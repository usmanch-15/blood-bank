import 'package:flutter/material.dart';

class AdminWebUsers extends StatelessWidget {
  const AdminWebUsers({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: const Center(child: Text('Users Screen')),
    );
  }
}