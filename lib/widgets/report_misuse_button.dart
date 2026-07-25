import 'package:flutter/material.dart';
import '../services/report_service.dart';

/// ✅ PHASE 2 — Report Misuse Button
/// Drop this into any screen (donor profile, request detail, etc.) to let
/// users report abuse. Pass targetUserId or targetRequestId depending on
/// context.
class ReportMisuseButton extends StatelessWidget {
  final String? targetUserId;
  final String? targetRequestId;

  const ReportMisuseButton({
    super.key,
    this.targetUserId,
    this.targetRequestId,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.red),
      label: const Text('Report', style: TextStyle(color: Colors.red)),
      onPressed: () => _openReportDialog(context),
    );
  }

  void _openReportDialog(BuildContext context) {
    String reason = 'Spam or fake request';
    final detailsCtrl = TextEditingController();
    const reasons = [
      'Spam or fake request',
      'Harassment or abuse',
      'Inappropriate content',
      'Fraud / scam attempt',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Report Misuse'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => reason = v ?? reason),
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ReportService().submitReport(
                    reason: reason,
                    targetUserId: targetUserId,
                    targetRequestId: targetRequestId,
                    details: detailsCtrl.text,
                  );
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Report submitted. Thank you.')),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}