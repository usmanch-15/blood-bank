import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String dashboardText(BuildContext context, String en, String ur) =>
    Localizations.localeOf(context).languageCode == 'ur' ? ur : en;

class DashboardPanel extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const DashboardPanel({super.key, required this.child, this.tint});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: tint ?? Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .5),
      ),
    ),
    child: child,
  );
}

class DashboardHeading extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onTap;
  const DashboardHeading(this.title, {super.key, this.action, this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    ),
  );
}

class DashboardAction extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const DashboardAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class OpportunityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final String? action;
  const OpportunityCard({
    super.key,
    required this.data,
    required this.onTap,
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final rawDate = data['requiredBy'];
    final date =
        rawDate is Timestamp
            ? rawDate.toDate()
            : rawDate is num
            ? DateTime.fromMillisecondsSinceEpoch(rawDate.toInt())
            : null;
    final distance = data['distanceKm'];
    final urgency = (data['urgency'] ?? 'normal').toString();
    final urgent = ['critical', 'urgent', 'life_threatening'].contains(urgency);
    final units = data['remainingUnits'] ?? data['quantity'] ?? 1;
    final urgencyLabel = switch (urgency) {
      'critical' => dashboardText(context, 'Critical', 'انتہائی فوری'),
      'life_threatening' => dashboardText(context, 'Critical', 'انتہائی فوری'),
      'urgent' => dashboardText(context, 'Urgent', 'فوری'),
      _ => dashboardText(context, 'Normal', 'معمول'),
    };
    final status =
        (data['responseStatus'] ?? data['status'] ?? 'pending').toString();
    final statusLabel = switch (status) {
      'accepted' => dashboardText(context, 'Accepted', 'قبول شدہ'),
      'agreed' => dashboardText(context, 'Arranged', 'طے شدہ'),
      'awaiting_confirmation' => dashboardText(
        context,
        'Awaiting confirmation',
        'تصدیق کا انتظار',
      ),
      'completed' || 'fulfilled' => dashboardText(context, 'Completed', 'مکمل'),
      'cancelled' => dashboardText(context, 'Cancelled', 'منسوخ'),
      'expired' => dashboardText(context, 'Expired', 'مدت ختم'),
      'withdrawn' => dashboardText(context, 'Withdrawn', 'واپس لی گئی'),
      'partially_fulfilled' => dashboardText(
        context,
        'Partially fulfilled',
        'جزوی طور پر مکمل',
      ),
      _ => dashboardText(context, 'Open request', 'کھلی درخواست'),
    };
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${data['bloodGroup'] ?? '—'}',
                  style: TextStyle(
                    color: c.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (data['hospitalName'] ?? '').toString().isEmpty
                      ? dashboardText(
                        context,
                        'Blood request',
                        'خون کی درخواست',
                      )
                      : data['hospitalName'].toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  urgencyLabel,
                  style: TextStyle(
                    color: urgent ? c.error : c.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusLabel,
            style: TextStyle(color: c.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              Text(
                dashboardText(
                  context,
                  '$units unit(s) remaining',
                  '$units یونٹ باقی',
                ),
              ),
              if (distance is num)
                Text(
                  dashboardText(
                    context,
                    'Approx. ${distance.toStringAsFixed(0)} km',
                    'تقریباً ${distance.toStringAsFixed(0)} کلومیٹر',
                  ),
                ),
            ],
          ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${dashboardText(context, 'Required by', 'درکار وقت')}: ${DateFormat('d MMM, h:mm a', Localizations.localeOf(context).languageCode).format(date.toLocal())}',
                style: TextStyle(color: c.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                action ??
                    dashboardText(context, 'View request', 'درخواست دیکھیں'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
