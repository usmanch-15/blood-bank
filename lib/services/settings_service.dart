import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_constants.dart';

/// ✅ PHASE 1 — Settings Service
/// Handles everything the Settings screen needs to read/write:
///   - profile fields (name, phone, email, bloodGroup, address)
///   - notification preferences (per-category toggles)
///   - donor availability toggle
///   - location-sharing toggle
///   - logout (with FCM token cleanup)
///   - delete account
///
/// FIRESTORE SCHEMA ASSUMED on users/{uid}:
///   name, email, bloodGroup, address,
///   isAvailable (bool),
///   locationSharingEnabled (bool),
///   notificationPrefs: {
///     sosAlerts: bool,
///     rewardUpdates: bool,
///     adminAnnouncements: bool,
///   },
///   fcmToken (String?), fcmUpdatedAt (Timestamp?)
///
/// phoneNumber lives separately, in users/{uid}/private/contact — see
/// below.
class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) {
      throw Exception('No user is currently logged in.');
    }
    return _firestore.collection(AppConstants.usersCollection).doc(uid);
  }

  // ✅ SECURITY FIX: phoneNumber used to live on _userDoc itself, which
  // has `allow read: if isSignedIn()` — any signed-in user could read
  // anyone's phone number. It now lives in this private subcollection,
  // which firestore.rules restricts to `isOwner(userId) || isAdmin()`.
  DocumentReference<Map<String, dynamic>> get _privateContactDoc =>
      _userDoc.collection('private').doc('contact');

  // ─────────────────────────── PROFILE ───────────────────────────

  /// Fetch the current user's full profile document as a stream, so the
  /// Settings screen updates live if changed elsewhere (e.g. by admin).
  /// NOTE: this stream no longer contains `phoneNumber` — use
  /// [phoneStream] / [getPhoneOnce] for that.
  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _userDoc.snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProfileOnce() {
    return _userDoc.get();
  }

  /// Stream just the phone number, from the private subcollection.
  Stream<String?> phoneStream() {
    return _privateContactDoc.snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data()?['phoneNumber'] as String?;
    });
  }

  Future<String?> getPhoneOnce() async {
    final doc = await _privateContactDoc.get();
    if (!doc.exists) return null;
    return doc.data()?['phoneNumber'] as String?;
  }

  /// Update basic profile fields. Only non-null fields are written, so
  /// callers can update just one field at a time if they want.
  /// `phoneNumber` is written to the private subcollection separately
  /// from the rest of the (non-sensitive) profile fields.
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? bloodGroup,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (bloodGroup != null) data['bloodGroup'] = bloodGroup;
    if (address != null) data['address'] = address.trim();

    if (data.isNotEmpty) {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _userDoc.update(data);
    }

    if (phoneNumber != null) {
      await _privateContactDoc.set(
        {'phoneNumber': phoneNumber.trim()},
        SetOptions(merge: true),
      );
    }
  }

  // ──────────────────────── NOTIFICATION PREFS ────────────────────────

  /// Convenience getters for the 3 notification categories requested in
  /// Phase 1: SOS alerts, reward updates, admin announcements.
  Future<void> updateNotificationPref({
    bool? sosAlerts,
    bool? rewardUpdates,
    bool? adminAnnouncements,
    bool? masterEnabled, // global on/off switch
  }) async {
    final data = <String, dynamic>{};
    if (masterEnabled != null) {
      data['notificationsEnabled'] = masterEnabled;
    }
    if (sosAlerts != null) {
      data['notificationPrefs.sosAlerts'] = sosAlerts;
    }
    if (rewardUpdates != null) {
      data['notificationPrefs.rewardUpdates'] = rewardUpdates;
    }
    if (adminAnnouncements != null) {
      data['notificationPrefs.adminAnnouncements'] = adminAnnouncements;
    }

    if (data.isEmpty) return;
    await _userDoc.update(data);
  }

  // ─────────────────────── AVAILABILITY (DONOR) ───────────────────────

  Future<void> setAvailability(bool isAvailable) async {
    await _userDoc.update({
      'isAvailable': isAvailable,
      'availabilityUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────── LOCATION SHARING ───────────────────────────

  /// When the user turns location sharing OFF, we also clear any stored
  /// coordinates so the app doesn't keep stale location data around (and
  /// so donor-matching correctly excludes them going forward).
  Future<void> setLocationSharing(bool enabled) async {
    final data = <String, dynamic>{
      'locationSharingEnabled': enabled,
    };
    if (!enabled) {
      data['latitude'] = null;
      data['longitude'] = null;
    }
    await _userDoc.update(data);
  }

  // ───────────────────────────── LOGOUT ─────────────────────────────

  /// Clears this device's FCM token from Firestore before signing out, so
  /// the Cloud Function stops trying to push notifications to a device
  /// that's no longer logged in.
  Future<void> logout() async {
    try {
      final uid = _uid;
      if (uid != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({
          'fcmToken': FieldValue.delete(),
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Don't block logout if token cleanup fails — still sign the user
      // out below.
    }
    await _auth.signOut();
  }

  // ─────────────────────────── DELETE ACCOUNT ───────────────────────────

  /// Soft-delete: marks the account for deletion instead of removing the
  /// Firestore document outright, which preserves donation/audit history
  /// and lets an admin recover the account if needed. Adjust to a hard
  /// delete if your policy requires actually removing the document.
  Future<void> deleteAccount() async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('No user is currently logged in.');
    }

    await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
      'status': 'deleted',
      'isAvailable': false,
      'fcmToken': FieldValue.delete(),
      'deletedAt': FieldValue.serverTimestamp(),
    });

    try {
      await FirebaseMessaging.instance.deleteToken();
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Firebase requires a recent sign-in before allowing account
        // deletion. Firestore doc is already marked 'deleted' above (so
        // the account is effectively disabled), but the Auth record
        // itself needs the user to re-authenticate before it can be
        // fully removed. Surface this so the UI can prompt for
        // re-login.
        rethrow;
      }
    }

    await _auth.signOut();
  }

  // ───────────────────────── PASSWORD CHANGE ─────────────────────────

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No logged-in user with an email/password account.');
    }

    // Re-authenticate first — Firebase requires this for sensitive
    // operations like password change.
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}