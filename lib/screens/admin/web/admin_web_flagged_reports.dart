import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

String _r(BuildContext c, String en, String ur) => AppLocalizations.of(c).locale.languageCode == 'ur' ? ur : en;

class AdminFlaggedReportsScreen extends StatelessWidget {
  const AdminFlaggedReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('misuse_reports').orderBy('reportedAt', descending: true).limit(50).snapshots(),
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Text(_r(context, 'Unable to load reports.', 'رپورٹس لوڈ نہیں ہو سکیں۔')));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final docs = snap.data!.docs;
      if (docs.isEmpty) return Center(child: Text(_r(context, 'No reports.', 'کوئی رپورٹ نہیں۔')));
      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (c, i) {
          final v = docs[i].data();
          return Card(
            child: ListTile(
              title: Text(v['targetRequestId']?.toString() ??
                  v['targetUserId']?.toString() ??
                  docs[i].id),
              subtitle: Text('${v['reason'] ?? ''}\n${v['status'] ?? 'open'}'),
            ),
          );
        },
      );
    },
  );
}
