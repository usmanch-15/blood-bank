import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// ✅ REWRITTEN — the old version declared `borderRadius`, `textStyle`, and
/// `loadingColor` as `required` constructor parameters but never actually
/// used any of them in build() — every value passed in was silently
/// discarded. The one call site (donor_profile_screen.dart) was passing
/// all 3 anyway, so it *looked* fine by coincidence, but the params were
/// structurally dead. Now they're properly wired in, made optional (with
/// sensible defaults so existing call sites keep compiling unchanged),
/// and a `variant`/`size` system + icon/gradient support has been added.
enum ButtonVariant { primary, secondary, outlined, ghost }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  // ✅ Now actually used (previously required-but-ignored):
  final int borderRadius;
  final TextStyle? textStyle;
  final Color loadingColor;

  // ✅ NEW
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final Gradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.textStyle,
    this.loadingColor = Colors.white,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.gradient,
  });

  double get _defaultHeight {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 50;
      case ButtonSize.large:
        return 58;
    }
  }

  double get _fontSize {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? _defaultHeight;
    final resolvedTextStyle = textStyle ??
        TextStyle(fontSize: _fontSize, fontWeight: FontWeight.bold);

    final content = isLoading
        ? SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          variant == ButtonVariant.primary ? loadingColor : AppColors.primaryRed,
        ),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSpacing.iconSm),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(text, style: resolvedTextStyle),
      ],
    );

    // ── Ghost — no background, no border, just colored text ──
    if (variant == ButtonVariant.ghost) {
      return SizedBox(
        width: width,
        height: resolvedHeight,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primaryRed,
          ),
          child: content,
        ),
      );
    }

    // ── Outlined — transparent background, colored border ──
    if (variant == ButtonVariant.outlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: resolvedHeight,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primaryRed,
            side: BorderSide(color: backgroundColor ?? AppColors.primaryRed),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
            ),
          ),
          child: content,
        ),
      );
    }

    // ── Secondary — light/white background, colored text ──
    if (variant == ButtonVariant.secondary) {
      return SizedBox(
        width: width ?? double.infinity,
        height: resolvedHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Colors.white,
            foregroundColor: textColor ?? AppColors.primaryRed,
            elevation: AppSpacing.elevationLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius.toDouble()),
              side: BorderSide(color: AppColors.primaryRed.withOpacity(0.3)),
            ),
          ),
          child: content,
        ),
      );
    }

    // ── Primary (default) — gradient/solid background, white text ──
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: gradient != null ? Colors.transparent : (backgroundColor ?? AppColors.primaryRed),
        foregroundColor: textColor ?? Colors.white,
        shadowColor: AppColors.shadowRed,
        elevation: gradient != null ? 0 : AppSpacing.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        ),
      ),
      child: content,
    );

    if (gradient == null) {
      return SizedBox(width: width ?? double.infinity, height: resolvedHeight, child: button);
    }

    // Gradient variant needs a wrapping Container since ElevatedButton
    // itself only accepts a solid backgroundColor.
    return Container(
      width: width ?? double.infinity,
      height: resolvedHeight,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius.toDouble()),
        boxShadow: [
          BoxShadow(color: AppColors.shadowRed, blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: button,
    );
  }
}