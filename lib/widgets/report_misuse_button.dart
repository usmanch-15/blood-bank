import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../services/report_service.dart';

/// ✅ PHASE 2 — Report Misuse button.
/// Small, reusable flag icon + confirmation dialog. Place it on any
/// screen where a user might need to report another user or a specific
/// request as suspicious/fraudulent (e.g. blood_request_detail_screen.dart).
class ReportMisuseButton extends StatelessWidget {
  final String? targetUserId;
  final String? targetRequestId;

  const ReportMisuseButton({
    super.key,
    this.targetUserId,
    this.targetRequestId,
  });

  void _showReportDialog(BuildContext context) {
    final reasons = [
      'Fake / fraudulent request',
      'Harassment or abuse',
      'Requesting payment for blood',
      'Inappropriate content',
      'Other',
    ];
    String selectedReason = reasons.first;
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: Text(AppLocalizations.of(context).reportMisuse),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).issuePrompt),
                        const SizedBox(height: 8),
                        ...reasons.map(
                          (reason) => RadioListTile<String>(
                            value: reason,
                            // ignore: deprecated_member_use
                            groupValue: selectedReason,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              reason,
                              style: const TextStyle(fontSize: 14),
                            ),
                            activeColor: AppColors.primaryRed,
                            // ignore: deprecated_member_use
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedReason = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: detailsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                AppLocalizations.of(context).detailsOptional,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await ReportService().submitReport(
                            reason: selectedReason,
                            targetUserId: targetUserId,
                            targetRequestId: targetRequestId,
                            details: detailsController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context).reportSubmitted,
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${AppLocalizations.of(context).operationFailed} $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(AppLocalizations.of(context).submitReport),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.grey),
      label: Text(
        AppLocalizations.of(context).report,
        style: TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
