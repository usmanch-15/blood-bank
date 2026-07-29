import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'status_badge.dart';

/// ✅ NEW — general-purpose reusable widgets referenced by the UI polish
/// checklist. Note: StatusBadge / BloodTypeBadge / UrgencyBadge live in
/// status_badge.dart, and LoadingShimmer / EmptyState / AppErrorState live
/// in their own files (loading_shimmer.dart / empty_state.dart) — they are
/// NOT redefined here to avoid duplicate-class conflicts. Import those
/// files directly when you need them; this file covers the rest:
/// PrimaryButton, SecondaryButton, CustomIconButton, ProfileCard,
/// RequestCard, DonorCard, StatCard.

// ── Buttons ──────────────────────────────────────────────────────────────
// Thin, semantically-named wrappers around CustomButton (widgets/custom_button.dart)
// for the common cases, so call sites read clearly.

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          elevation: AppSpacing.elevationLow,
          shadowColor: AppColors.shadowRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryRed,
          side: const BorderSide(color: AppColors.primaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// A circular icon button with a soft tinted background — used for compact
/// actions (call, message, edit) inside cards.
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primaryRed;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: resolvedColor, size: size * 0.5),
        style: IconButton.styleFrom(
          backgroundColor: resolvedColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

// ── Cards ────────────────────────────────────────────────────────────────

/// A profile summary card — avatar + name + subtitle + trailing widget
/// (e.g. an edit icon or a badge). Used in donor/receiver profile headers.
class ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? avatarUrl;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ProfileCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.avatarUrl,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryRed.withOpacity(0.15),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 18),
          )
              : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: trailing,
      ),
    );
  }
}

/// A blood request summary card — bloodGroup + hospital/location + status +
/// urgency, with an optional tap action. Deliberately takes plain fields
/// (not a specific model type) so it works regardless of which screen's
/// BloodRequestModel shape is in use.
class RequestCard extends StatelessWidget {
  final String bloodGroup;
  final String hospitalName;
  final String location;
  final String status; // 'pending' | 'fulfilled' | 'rejected' | ...
  final String? urgency;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RequestCard({
    super.key,
    required this.bloodGroup,
    required this.hospitalName,
    required this.location,
    required this.status,
    this.urgency,
    this.onTap,
    this.trailing,
  });

  BadgeStatus get _badgeStatus {
    switch (status.toLowerCase()) {
      case 'fulfilled':
        return BadgeStatus.verified;
      case 'rejected':
        return BadgeStatus.rejected;
      default:
        return BadgeStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      BloodTypeBadge(bloodGroup: bloodGroup),
                      if (urgency != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        UrgencyBadge(urgency: urgency!),
                      ],
                    ],
                  ),
                  StatusBadge(status: _badgeStatus, customLabel: status, customColor: null),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.local_hospital_outlined, size: AppSpacing.iconSm, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(hospitalName, style: const TextStyle(color: AppColors.textSecondary))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: AppSpacing.iconSm, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(location, style: const TextStyle(color: AppColors.textSecondary))),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A matching donor card — name + bloodGroup + optional distance/level,
/// with a call action.
class DonorCard extends StatelessWidget {
  final String name;
  final String bloodGroup;
  final String? subtitle; // e.g. distance, "Level: Gold"
  final VoidCallback? onCall;
  final VoidCallback? onTap;

  const DonorCard({
    super.key,
    required this.name,
    required this.bloodGroup,
    this.subtitle,
    this.onCall,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppSpacing.elevationLow,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: BloodTypeBadge(bloodGroup: bloodGroup, fontSize: 14),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary)) : null,
        trailing: onCall != null ? CustomIconButton(icon: Icons.call, onPressed: onCall, size: 40) : null,
      ),
    );
  }
}

/// A small stat tile for dashboards — big number + label + icon.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primaryRed;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [BoxShadow(color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: resolvedColor, size: AppSpacing.iconMd),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}