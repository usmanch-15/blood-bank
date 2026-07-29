import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

/// ✅ NEW — small helper functions so screens stop hand-rolling the same
/// BoxDecoration(boxShadow: [...], borderRadius: ...) blocks with slightly
/// different values everywhere.
class AppDecorations {
  AppDecorations._();

  static List<BoxShadow> boxShadow({
    Color color = AppColors.shadowLight,
    double blurRadius = 8,
    Offset offset = const Offset(0, 2),
  }) {
    return [BoxShadow(color: color, blurRadius: blurRadius, offset: offset)];
  }

  static BoxDecoration cardDecoration({
    Color backgroundColor = Colors.white,
    double radius = AppSpacing.radiusMd,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: withShadow ? boxShadow() : null,
    );
  }

  static BoxDecoration gradientDecoration({
    required Gradient gradient,
    double radius = AppSpacing.radiusLg,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: withShadow ? boxShadow(color: AppColors.shadowMedium, blurRadius: 12, offset: const Offset(0, 4)) : null,
    );
  }

  static BoxDecoration roundedDecoration({
    required Color color,
    double radius = AppSpacing.radiusMd,
    Color? borderColor,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null ? Border.all(color: borderColor, width: borderWidth) : null,
    );
  }
}