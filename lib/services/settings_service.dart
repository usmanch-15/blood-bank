import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_constants.dart';

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

  DocumentReference<Map<String, dynamic>> get _privateContactDoc =>
      _userDoc.collection('private').doc('contact');

  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream() {
    return _userDoc.snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getProfileOnce() {
    return _userDoc.get();
  }

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

  Future<void> updateNotificationPref({
    bool? sosAlerts,
    bool? rewardUpdates,
    bool? adminAnnouncements,
    bool? masterEnabled,
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

  Future<void> setAvailability(bool isAvailable) async {
    await _userDoc.update({
      'isAvailable': isAvailable,
      'availabilityUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

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
    } catch (_) {}
    await _auth.signOut();
  }

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
        rethrow;
      }
    }

    await _auth.signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No logged-in user with an email/password account.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// ✅ NEW — Change account email. firebase_auth v5 removed the old
  /// updateEmail() (phishing/account-takeover risk). This sends a
  /// confirmation link to the NEW address instead — email only changes
  /// once that link is clicked.
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No logged-in user with an email/password account.');
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.verifyBeforeUpdateEmail(newEmail.trim());
  }

  /// ✅ NEW — "Download My Data" (Privacy Policy §6).
  Future<String> exportUserData() async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('No user is currently logged in.');
    }

    final profileDoc = await _userDoc.get();
    final profile = profileDoc.data() ?? {};
    final phone = await getPhoneOnce();

    final donationsSnap = await _firestore
        .collection(AppConstants.donationsCollection)
        .where('donorId', isEqualTo: uid)
        .get();

    final notificationsSnap = await _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: uid)
        .limit(100)
        .get();

    final buffer = StringBuffer();
    buffer.writeln('SMART BLOOD BANK — MY DATA EXPORT');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('User ID: $uid');
    buffer.writeln('${'=' * 50}');

    buffer.writeln('\nPROFILE');
    buffer.writeln('-' * 20);
    buffer.writeln('Name: ${profile['name'] ?? '-'}');
    buffer.writeln('Email: ${profile['email'] ?? '-'}');
    buffer.writeln('Phone: ${phone ?? '-'}');
    buffer.writeln('Role: ${profile['role'] ?? '-'}');
    buffer.writeln('Blood Group: ${profile['bloodGroup'] ?? '-'}');
    buffer.writeln('Location: ${profile['location'] ?? '-'}');
    buffer.writeln('Status: ${profile['status'] ?? '-'}');
    buffer.writeln('Reward Points: ${profile['rewardPoints'] ?? 0}');
    buffer.writeln(
        'Location Sharing Enabled: ${profile['locationSharingEnabled'] ?? true}');
    buffer.writeln('Available to Donate: ${profile['isAvailable'] ?? false}');

    buffer.writeln('\nDONATION HISTORY (${donationsSnap.docs.length})');
    buffer.writeln('-' * 20);
    if (donationsSnap.docs.isEmpty) {
      buffer.writeln('No donations recorded.');
    }
    for (final doc in donationsSnap.docs) {
      final d = doc.data();
      final date = d['donationDate'];
      final dateStr = date is Timestamp
          ? date.toDate().toIso8601String()
          : (date?.toString() ?? '-');
      buffer.writeln(
          '• $dateStr — ${d['bloodGroup'] ?? '-'} — ${d['location'] ?? '-'} — ${d['pointsEarned'] ?? 0} pts');
    }

    buffer.writeln(
        '\nRECENT NOTIFICATIONS (last ${notificationsSnap.docs.length})');
    buffer.writeln('-' * 20);
    if (notificationsSnap.docs.isEmpty) {
      buffer.writeln('No notifications recorded.');
    }
    for (final doc in notificationsSnap.docs) {
      final d = doc.data();
      buffer.writeln('• ${d['title'] ?? '-'}: ${d['body'] ?? '-'}');
    }

    buffer.writeln('\n${'=' * 50}');
    buffer.writeln(
        'This export contains the personal data Smart Blood Bank holds '
            'about your account, as described in our Privacy Policy.');

    return buffer.toString();
  }
}