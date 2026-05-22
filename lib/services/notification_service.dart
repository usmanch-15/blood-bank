import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) await _saveDeviceToken(token);
  }

  Future<void> _saveDeviceToken(String token) async {
    final user = await _messaging.getToken();
    if (user == null) return;
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