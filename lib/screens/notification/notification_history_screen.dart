import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';

/// ✅ PHASE 2 — Notification History
/// Shows all past notifications for the logged-in user, newest first.
/// Tapping a notification marks it as read.
class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: uid == null
          ? const Center(child: Text('Please log in.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] == true;
              final createdAt = data['createdAt'] as Timestamp?;
              final type = data['type']?.toString() ?? 'general';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRead
                      ? Colors.grey.shade300
                      : AppColors.primaryRed.withOpacity(0.15),
                  child: Icon(
                    _iconForType(type),
                    color: isRead ? Colors.grey : AppColors.primaryRed,
                    size: 20,
                  ),
                ),
                title: Text(
                  data['title']?.toString() ?? '',
                  style: TextStyle(
                    fontWeight:
                    isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(data['body']?.toString() ?? ''),
                trailing: createdAt != null
                    ? Text(
                  DateFormat('MMM d, h:mm a')
                      .format(createdAt.toDate()),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                )
                    : null,
                onTap: () {
                  if (!isRead) {
                    doc.reference.update({'isRead': true});
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'sosAlerts':
        return Icons.emergency;
      case 'rewardUpdates':
        return Icons.card_giftcard;
      case 'adminAnnouncements':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }
}