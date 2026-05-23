import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (token != null) await _saveDeviceToken(token);

      // Refresh token automatically when it changes
      _messaging.onTokenRefresh.listen(_saveDeviceToken);
    }
  }

  // ✅ FIXED: properly saves FCM token to the logged-in user's Firestore doc
  Future<void> _saveDeviceToken(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()});
  }

  // ✅ Call this on logout to remove the token
  Future<void> clearDeviceToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': FieldValue.delete()});
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .add({
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    final batch = _firestore.batch();
    for (final uid in userIds) {
      final ref = _firestore
          .collection(AppConstants.notificationsCollection)
          .doc();
      batch.set(ref, {
        'userId': uid,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    await batch.commit();
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
}