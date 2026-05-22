import 'package:flutter/material.dart';
import '../../../models/reward_model.dart';
import '../../../utils/date_utils.dart';

class CertificateCard extends StatelessWidget {
  final Certificate certificate; // ✅ RewardModel ki jagah Certificate
  final VoidCallback onDownload;

  const CertificateCard({
    super.key,
    required this.certificate, // ✅
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                const Text('Donation Certificate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Chip(
                  label: Text('+${certificate.pointsEarned} pts', // ✅
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Date: ${AppDateUtils.formatDate(certificate.issuedDate)}', // ✅
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download, color: Colors.red),
                label: const Text('Download PDF', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}