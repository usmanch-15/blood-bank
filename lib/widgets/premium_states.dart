import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class PremiumLoading extends StatelessWidget {
  final int rows;
  const PremiumLoading({super.key, this.rows = 3});
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: rows,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => const _LoadingRow(),
  );
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => Container(
    height: 72,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
  );
}

class PremiumErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const PremiumErrorState({super.key, required this.onRetry, this.message});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 48), const SizedBox(height: 12), Text(message ?? AppLocalizations.of(context).somethingWentWrong, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(AppLocalizations.of(context).retry))])));
}

class PremiumEmptyState extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  final String? actionLabel;
  const PremiumEmptyState({super.key, required this.title, this.onAction, this.actionLabel});
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_outlined, size: 52, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center), if (onAction != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onAction, child: Text(actionLabel ?? AppLocalizations.of(context).retry))]])));
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context) => MaterialBanner(content: Text(AppLocalizations.of(context).offlineMessage), leading: const Icon(Icons.cloud_off), actions: [TextButton(onPressed: () {}, child: Text(AppLocalizations.of(context).retry))]);
}

Future<void> showPermissionDeniedSheet(
    BuildContext context, String permissionName) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 44),
            const SizedBox(height: 12),
            Text('$permissionName permission is required',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).permissionSettingsHint,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context).openSettings),
            ),
          ],
        ),
      ),
    ),
  );
}
