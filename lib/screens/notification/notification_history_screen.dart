import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/paged_records.dart';
import '../../services/push_navigation_service.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body:
          uid == null
              ? const Center(child: Text('Please sign in.'))
              : PagedRecords(
                query: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('userId', isEqualTo: uid)
                    .orderBy('createdAt', descending: true),
                itemBuilder: (context, doc) {
                  final d = doc.data();
                  return ListTile(
                    leading: Icon(
                      d['isRead'] == true
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                    ),
                    title: Text(d['title'] ?? ''),
                    subtitle: Text(d['body'] ?? ''),
                    onTap: () async {
                      try {
                        await doc.reference.update({'isRead': true});
                        await PushNavigationService.instance.openNotification(
                          d['type'],
                          d['relatedId'],
                        );
                      } catch (e) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unable to open notification: $e'),
                            ),
                          );
                      }
                    },
                  );
                },
              ),
    );
  }
}
