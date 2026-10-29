import 'package:flutter/material.dart';
import '../requests/request_list_screen.dart';

/// Keeps the legacy route on the same server-redacted donor feed.
class MyResponsesScreen extends StatelessWidget {
  const MyResponsesScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const RequestListScreen(mode: 'responses');
}
