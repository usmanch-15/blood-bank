import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ PHASE 2 — Admin Audit Log
/// Call logAction() every time an admin approves/rejects/suspends a user,
/// changes a request status, or sends a broadcast — so there's a
/// traceable record of who did what and when.
class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logAction({
    required String action, // e.g. 'approve_user', 'suspend_user', 'update_request_status', 'send_broadcast'
    required String targetId, // uid, requestId, etc.
    Map<String, dynamic>? changes, // e.g. {'status': {'from': 'pending', 'to': 'approved'}}
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    await _firestore.collection('audit_logs').add({
      'adminId': admin.uid,
      'adminEmail': admin.email,
      'action': action,
      'targetId': targetId,
      'changes': changes ?? {},
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}