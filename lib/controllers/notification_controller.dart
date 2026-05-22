import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../constants/app_constants.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      _notifications = snapshot.docs
          .map((d) => NotificationModel.fromFirestore(d.data(), d.id))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in _notifications.where((n) => !n.isRead)) {
      final ref = FirebaseFirestore.instance
          .collection(AppConstants.notificationsCollection)
          .doc(n.id);
      batch.update(ref, {'isRead': true});
    }
    await batch.commit();
    _notifications =
        _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}