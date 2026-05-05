import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_config.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        !user.emailVerified ||
        !AdminConfig.adminEmails.contains(user.email)) {
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
  }
}