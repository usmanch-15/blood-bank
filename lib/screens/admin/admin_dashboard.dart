import 'package:flutter/material.dart';
import 'admin_guard.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text("Admin Dashboard")),
        body: const Center(
          child: Text("Welcome Admin Panel"),
        ),
      ),
    );
  }
}