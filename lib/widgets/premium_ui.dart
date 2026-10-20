import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const PremiumCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(padding: padding, child: child),
  );
}

class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const PremiumSectionHeader({super.key, required this.title, this.subtitle, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleLarge), if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)])),
      if (action != null) action!,
    ]),
  );
}

class UrgencyBadge extends StatelessWidget {
  final String urgency;
  const UrgencyBadge({super.key, required this.urgency});
  @override
  Widget build(BuildContext context) {
    final critical = urgency.toLowerCase() == 'critical' || urgency.toLowerCase() == 'life_threatening';
    final urgent = urgency.toLowerCase() == 'urgent';
    final color = critical ? AppColors.error : urgent ? AppColors.warning : AppColors.secondaryGreen;
    final icon = critical ? Icons.priority_high : urgent ? Icons.warning_amber : Icons.schedule;
    return Semantics(label: urgency, child: Chip(avatar: Icon(icon, size: 16, color: color), label: Text(urgency), side: BorderSide(color: color), labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700)));
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});
  @override
  Widget build(BuildContext context) => Chip(avatar: const Icon(Icons.verified, size: 16, color: AppColors.secondaryGreen), label: Text(AppLocalizations.of(context).profileVerifiedLabel));
}
