import 'package:flutter/material.dart';
import '../../../models/blood_request_model.dart';

class BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;

  const BloodRequestCard({super.key, required this.request});

  Color _urgencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'urgent': return Colors.orange;
      default: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(request.bloodGroup,
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.hospitalName,
                      style:
                      const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${request.quantity} unit(s) needed',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Chip(
              label: Text(request.urgency,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11)),
              backgroundColor: _urgencyColor(request.urgency),
            ),
          ],
        ),
      ),
    );
  }
}