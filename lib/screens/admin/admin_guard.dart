import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// ✅ FIX (Issue #8): admin access used to be granted purely by matching a
/// hardcoded email list (AdminConfig.adminEmails). If that list leaked in
/// the client bundle, anyone using one of those emails became admin. Now
/// we check the user's actual role + approval status stored in Firestore,
/// which only an existing admin can set.
class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  Future<bool> _isApprovedAdmin(User? user) async {
    if (user == null || !user.emailVerified) return false;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data()?['role'] == 'admin' &&
        doc.data()?['status'] == 'approved';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: _isApprovedAdmin(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return const Scaffold(
            body: Center(
              child: Text(
                "❌ Access Denied",
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}