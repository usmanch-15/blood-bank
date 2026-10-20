import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../widgets/premium_states.dart';
import '../../l10n/app_localizations.dart';

class MyResponsesScreen extends StatelessWidget {
  const MyResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My responses')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('blood_requests')
                .where('participantIds', arrayContains: uid)
                .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return PremiumErrorState(onRetry: () {}, message: AppLocalizations.of(context).responsesLoadFailed);
          }
          if (!snap.hasData) {
            return const PremiumLoading();
          }
          if (snap.data!.docs.isEmpty) {
            return PremiumEmptyState(title: AppLocalizations.of(context).noResponses);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children:
                snap.data!.docs.map((doc) {
                  final d = doc.data();
                  final commitment = (d['commitments'] as Map?)?[uid];
                  final status =
                      commitment is Map
                          ? (commitment['status'] ?? 'accepted').toString()
                          : 'accepted';
                  return Card(
                    child: ListTile(
                      title: Text(
                        (d['hospitalName'] ?? d['hospital'] ?? 'Blood request')
                            .toString(),
                      ),
                      subtitle: Text(
                        'Status: ${status.replaceAll('_', ' ')}\nBlood group: ${d['bloodGroup'] ?? '—'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
