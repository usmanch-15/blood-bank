import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import 'admin_guard.dart';

/// ✅ PHASE 2 — Admin Audit Log Viewer
class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Audit Log'),
          backgroundColor: AppColors.primaryDarkRed,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('audit_logs')
              .orderBy('timestamp', descending: true)
              .limit(200)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No admin actions logged yet.'));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final ts = data['timestamp'] as Timestamp?;
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(
                    '${data['action'] ?? 'unknown action'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'By: ${data['adminEmail'] ?? data['adminId']}\n'
                        'Target: ${data['targetId'] ?? '-'}',
                  ),
                  isThreeLine: true,
                  trailing: ts != null
                      ? Text(
                    DateFormat('MMM d, h:mm a').format(ts.toDate()),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}