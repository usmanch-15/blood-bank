import 'package:flutter/material.dart';
import '../requests/request_tracking_screen.dart';

class BloodRequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String? requestId;
  const BloodRequestDetailScreen({
    super.key,
    required this.requestData,
    this.requestId,
  });
  @override
  Widget build(BuildContext context) =>
      requestId == null
          ? Scaffold(
            appBar: AppBar(title: const Text('Request unavailable')),
            body: const Center(
              child: Text('Open this request from your request list.'),
            ),
          )
          : RequestTrackingScreen(requestId: requestId!);
}
