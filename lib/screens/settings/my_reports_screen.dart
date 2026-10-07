import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/paged_records.dart';
import '../../services/workflow_service.dart';

class MyReportsScreen extends StatelessWidget {
  final bool admin;
  const MyReportsScreen({super.key, this.admin = false});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          admin ? 'Reports & Support' : 'My Reports / Support Status',
        ),
        bottom: const TabBar(
          tabs: [Tab(text: 'Misuse reports'), Tab(text: 'Support / Feedback')],
        ),
      ),
      floatingActionButton:
          admin
              ? null
              : FloatingActionButton.extended(
                onPressed: () => _support(context),
                icon: const Icon(Icons.help_outline),
                label: const Text('Ask for support'),
              ),
      body: TabBarView(
        children:
            ['misuse_reports', 'feedback'].map((collection) {
              Query<Map<String, dynamic>> q = FirebaseFirestore.instance
                  .collection(collection);
              if (!admin)
                q = q.where(
                  'reporterId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                );
              return PagedRecords(
                query: q.orderBy(FieldPath.documentId),
                itemBuilder: (context, doc) {
                  final d = doc.data();
                  return Card(
                    child: ListTile(
                      title: Text(d['title'] ?? 'Report'),
                      subtitle: Text(
                        '${d['status']}\n${d['description'] ?? ''}',
                      ),
                      isThreeLine: true,
                      trailing:
                          admin
                              ? PopupMenuButton<String>(
                                onSelected: (status) async {
                                  try {
                                    await WorkflowService.call('adminAction', {
                                      'collection': collection,
                                      'id': doc.id,
                                      'updates': {'status': status},
                                    });
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Updated. Refresh the list to see the latest status.',
                                          ),
                                        ),
                                      );
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('$e')),
                                      );
                                  }
                                },
                                itemBuilder:
                                    (_) =>
                                        [
                                              'investigating',
                                              'resolved',
                                              'dismissed',
                                            ]
                                            .map(
                                              (s) => PopupMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                              )
                              : null,
                    ),
                  );
                },
              );
            }).toList(),
      ),
    ),
  );
  Future<void> _support(BuildContext context) async {
    final title = TextEditingController(), body = TextEditingController();
    final form = GlobalKey<FormState>();
    bool sending = false;
    await showDialog(
      context: context,
      builder:
          (c) => StatefulBuilder(
            builder:
                (c, setState) => AlertDialog(
                  title: const Text('Support request'),
                  content: Form(
                    key: form,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: title,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Enter a subject'
                                        : null,
                          ),
                          TextFormField(
                            controller: body,
                            maxLength: 2000,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Describe the issue',
                            ),
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Describe the issue'
                                        : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: sending ? null : () => Navigator.pop(c),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          sending
                              ? null
                              : () async {
                                if (!form.currentState!.validate()) return;
                                setState(() => sending = true);
                                try {
                                  await WorkflowService.call('submitReport', {
                                    'title': title.text,
                                    'description': body.text,
                                    'feedback': true,
                                  });
                                  if (c.mounted) Navigator.pop(c);
                                } catch (e) {
                                  if (c.mounted) {
                                    setState(() => sending = false);
                                    ScaffoldMessenger.of(c).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                }
                              },
                      child: Text(sending ? 'Submitting…' : 'Submit'),
                    ),
                  ],
                ),
          ),
    );
    // Dialog routes animate out before their fields dispose.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      title.dispose();
      body.dispose();
    });
  }
}
