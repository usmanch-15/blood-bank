import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ PHASE 2 — Report Misuse
/// Lets any signed-in user flag another user, a blood request, or general
/// abuse. Admin sees these in a reports queue (see AdminReportsScreen).
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport({
    required String reason,
    String? targetUserId,
    String? targetRequestId,
    String? details,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('You must be logged in to report.');

    await _firestore.collection('reports').add({
      'reportedBy': uid,
      'reason': reason,
      'targetUserId': targetUserId,
      'targetRequestId': targetRequestId,
      'details': details ?? '',
      'status': 'open', // open | reviewed | resolved
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}