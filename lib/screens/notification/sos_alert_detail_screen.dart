import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosAlertDetailScreen extends StatelessWidget {
  final String requestId;
  const SosAlertDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SOS alert')),
    body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.doc('sosRequests/$requestId').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load this SOS alert.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data();
        if (data == null) {
          return const Center(
            child: Text('This SOS alert is no longer available.'),
          );
        }
        final lat = data['latitude'] as num?, lng = data['longitude'] as num?;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${data['bloodGroup']} blood needed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('Urgency: ${data['urgency'] ?? 'critical'}'),
            Text(data['isResolved'] == true ? 'Resolved' : 'Open SOS alert'),
            const SizedBox(height: 16),
            if (lat != null && lng != null) ...[
              Text('Request location: $lat, $lng'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions),
                label: const Text('Open directions'),
                onPressed: () async {
                  try {
                    final opened = await launchUrl(
                      Uri.parse(
                        'https://www.openstreetmap.org/directions?to=$lat%2C$lng',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened) {
                      throw StateError('No maps application available.');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not open directions: $e'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ],
        );
      },
    ),
  );
}
