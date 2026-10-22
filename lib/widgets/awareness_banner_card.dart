import 'package:flutter/material.dart';
import '../models/awareness_banner.dart';
import 'dashboard_components.dart';

class AwarenessBannerCard extends StatelessWidget {
  final AwarenessBanner banner;
  final VoidCallback? onDismiss;
  final VoidCallback onAction;
  final bool? urdu;
  const AwarenessBannerCard({
    super.key,
    required this.banner,
    this.onDismiss,
    required this.onAction,
    this.urdu,
  });
  @override
  Widget build(BuildContext context) {
    final isUrdu = urdu ?? Localizations.localeOf(context).languageCode == 'ur';
    final c = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: DashboardPanel(
        tint: c.primaryContainer.withValues(alpha: .35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  color: c.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUrdu ? 'عطیہ دہندگان کے لیے' : 'DONOR CORNER',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: c.primary,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    tooltip: isUrdu ? 'بینر بند کریں' : 'Dismiss banner',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
            if (banner.imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    banner.imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Text(
              banner.text('title', isUrdu),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              banner.text('description', isUrdu),
              style: TextStyle(color: c.onSurfaceVariant),
            ),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: Text(banner.text('button', isUrdu)),
            ),
          ],
        ),
      ),
    );
  }
}
