import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// ✅ NEW — reusable colored pill badges used across admin/donor/receiver
/// screens (donor verification status, request urgency, blood type, etc.)
/// instead of each screen hand-rolling its own Container+Text combo with
/// slightly different colors/padding every time.
enum BadgeStatus { verified, pending, rejected, custom }

class StatusBadge extends StatelessWidget {
  final BadgeStatus status;
  final String? customLabel;
  final Color? customColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.customColor,
    this.icon,
  }) : assert(
  status != BadgeStatus.custom ||
      (customLabel != null && customColor != null),
  'BadgeStatus.custom requires both customLabel and customColor',
  );

  /// Verified (green) shortcut.
  const StatusBadge.verified({super.key})
      : status = BadgeStatus.verified,
        customLabel = null,
        customColor = null,
        icon = null;

  /// Pending (orange) shortcut.
  const StatusBadge.pending({super.key})
      : status = BadgeStatus.pending,
        customLabel = null,
        customColor = null,
        icon = null;

  /// Rejected (red) shortcut.
  const StatusBadge.rejected({super.key})
      : status = BadgeStatus.rejected,
        customLabel = null,
        customColor = null,
        icon = null;

  String get _label {
    switch (status) {
      case BadgeStatus.verified:
        return 'Verified';
      case BadgeStatus.pending:
        return 'Pending';
      case BadgeStatus.rejected:
        return 'Rejected';
      case BadgeStatus.custom:
        return customLabel!;
    }
  }

  Color get _color {
    switch (status) {
      case BadgeStatus.verified:
        return AppColors.success;
      case BadgeStatus.pending:
        return AppColors.warning;
      case BadgeStatus.rejected:
        return AppColors.error;
      case BadgeStatus.custom:
        return customColor!;
    }
  }

  IconData get _icon {
    if (icon != null) return icon!;
    switch (status) {
      case BadgeStatus.verified:
        return Icons.check_circle;
      case BadgeStatus.pending:
        return Icons.access_time;
      case BadgeStatus.rejected:
        return Icons.cancel;
      case BadgeStatus.custom:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Blood type badge — A+, O-, etc. — always shown in the app's red theme
/// since blood type isn't a "status" the way verified/pending/rejected are.
class BloodTypeBadge extends StatelessWidget {
  final String bloodGroup;
  final double fontSize;

  const BloodTypeBadge({super.key, required this.bloodGroup, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        bloodGroup,
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Urgency badge — Critical / Urgent / Normal, color-coded by severity.
class UrgencyBadge extends StatelessWidget {
  final String urgency; // 'Critical' | 'Urgent' | 'Normal' (case-insensitive)

  const UrgencyBadge({super.key, required this.urgency});

  Color get _color {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'urgent':
        return AppColors.warning;
      default:
        return AppColors.secondaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        urgency,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}