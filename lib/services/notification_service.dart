import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();
  StreamSubscription<String>? _refresh;
  String? _initializedUid;

  Future<void> init() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _initializedUid || kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      final token = await messaging.getToken().timeout(
        const Duration(seconds: 8),
      );
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (token != null) await _save(uid, token);
      await _refresh?.cancel();
      _refresh = messaging.onTokenRefresh.listen((token) async {
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        try {
          await _save(uid, token);
        } catch (e) {
          debugPrint('Token refresh failed: $e');
        }
      });
      _initializedUid = uid;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<void> _save(String uid, String token) => FirebaseFirestore.instance
      .doc('users/$uid/private/device')
      .set({'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()});

  Future<void> clearDeviceToken() async {
    await _refresh?.cancel();
    _refresh = null;
    _initializedUid = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null) {
        await FirebaseFirestore.instance
            .doc('users/$uid/private/device')
            .delete();
      }
      if (!kIsWeb) await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Token cleanup unavailable: $e');
    }
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) => sendToUsers(
    userIds: [userId],
    title: title,
    body: body,
    type: type,
    relatedId: relatedId,
  );

  Future<void> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    if (relatedId == null) {
      throw StateError('Create a blood request before notifying donors.');
    }
    await FirebaseFunctions.instance.httpsCallable('notifyRequest').call({
      'requestId': relatedId,
      'userIds': userIds,
    });
  }

  Future<void> markAsRead(String id) => FirebaseFirestore.instance
      .doc('notifications/$id')
      .update({'isRead': true});
}
