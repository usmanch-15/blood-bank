import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ PHASE 2 — Report Misuse
/// Lets any signed-in user flag another user, a blood request, or general
/// abuse. Admin sees these in a reports queue (see AdminWebReports).
///
/// ✅ FIX: previously wrote to a `reports` collection with field
/// `reportedBy`, but AdminWebReports (the admin queue UI) reads from
/// `misuse_reports` with field `reporterId` (see MisuseReportModel).
/// Those were two different collections, so every report submitted from
/// this button silently never reached the admin. Now writes directly to
/// `misuse_reports` using the same field names MisuseReportModel expects,
/// so submitted reports show up in the admin panel immediately.
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

    await _firestore.collection('misuse_reports').add({
      'reporterId': uid,
      'reportedUserId': targetUserId,
      // 'other' matches the AdminWebReports type filter list
      // (fraud / misuse / fake_profile / other); this button doesn't
      // collect a specific type from the user, so default to 'other'.
      'reportType': 'other',
      'title': reason,
      'description': details ?? '',
      if (targetRequestId != null) 'targetRequestId': targetRequestId,
      'status': 'pending', // matches MisuseReportModel: pending | investigating | resolved | dismissed
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }
}