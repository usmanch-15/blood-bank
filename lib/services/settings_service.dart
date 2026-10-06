import 'dart:convert';
import 'workflow_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'notification_service.dart';
import 'geo_location_service.dart';
import '../utils/location_helper.dart';
import '../utils/validators.dart';
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
    if (name != null && AppValidators.validateName(name) != null) throw ArgumentError(AppValidators.validateName(name));
    if (phoneNumber != null) throw StateError('Use phone verification to change your number.');
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
    if (enabled) {
      final position = await GeoLocationService().getCurrentLocation();
      data['latitude'] = LocationHelper.roundForPrivacy(position.latitude);
      data['longitude'] = LocationHelper.roundForPrivacy(position.longitude);
      data['locationUpdatedAt'] = FieldValue.serverTimestamp();
    }
    if (!enabled) {
      data['latitude'] = null;
      data['longitude'] = null;
    }
    await _userDoc.update(data);
  }

  Future<void> logout() async {
    await NotificationService().clearDeviceToken();
    await _auth.signOut();
  }
  Future<void> deleteAccount() async {
    await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
    await NotificationService().clearDeviceToken();
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
    final uid=_uid;if(uid==null)throw StateError('Sign in first.');
    final output=<String,dynamic>{'generatedAt':DateTime.now().toIso8601String()};
    final contact=await _privateContactDoc.get();
    output['privateContact']=contact.data();
    for(final collection in ['users','blood_requests','donations','sosRequests','misuse_reports','feedback','notifications']) {
      final items=<dynamic>[];String? cursor;
      do{final page=await WorkflowService.call('exportPage',{'collection':collection,'cursor':cursor});items.addAll(page['items'] as List);cursor=page['cursor'];}while(cursor!=null);
      output[collection]=items;
    }
    return const JsonEncoder.withIndent('  ').convert(output);
  }
}
