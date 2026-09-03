import 'package:flutter/material.dart';

/// Responsive breakpoints and helpers used across the app.
///
/// Design principle: **every helper returns the desktop/original value at wide
/// widths**, so the existing Web/Desktop UI is preserved exactly. Values only
/// diverge below the tablet/mobile breakpoints. This lets us harden layouts for
/// narrow phones without touching how the app currently looks on the web.
///
/// Breakpoints:
/// * mobile  : width  < 600
/// * tablet  : 600 <= width < 1024
/// * desktop : width >= 1024
class Responsive {
  const Responsive._();

  /// Widths at/above these thresholds are treated as tablet / desktop.
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double heightOf(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isMobile(BuildContext context) =>
      widthOf(context) < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final w = widthOf(context);
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      widthOf(context) >= tabletMaxWidth;

  /// Picks a value per breakpoint. [tablet] falls back to [desktop] when null,
  /// so passing only `mobile` + `desktop` keeps tablet identical to desktop.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final w = widthOf(context);
    if (w < mobileMaxWidth) return mobile;
    if (w < tabletMaxWidth) return tablet ?? desktop;
    return desktop;
  }

  /// Font size that stays exactly [size] at tablet/desktop widths (>= 600px)
  /// and is gently scaled down on narrow phones so large headings never
  /// overflow. Below 600px it multiplies by `clamp(width / 400, minScale, 1)`,
  /// i.e. full size at >=400px, shrinking to [minScale] on the smallest phones.
  static double font(
    BuildContext context,
    double size, {
    double minScale = 0.82,
  }) {
    final w = widthOf(context);
    if (w >= mobileMaxWidth) return size;
    final scale = (w / 400).clamp(minScale, 1.0);
    return size * scale;
  }

  /// Symmetric all-around page padding: tighter on phones, original on wider
  /// screens. Defaults keep the common `EdgeInsets.all(16)` on the web.
  static EdgeInsets pagePadding(
    BuildContext context, {
    double mobile = 16,
    double? tablet,
    double desktop = 16,
  }) {
    return EdgeInsets.all(
      value(context, mobile: mobile, tablet: tablet, desktop: desktop),
    );
  }

  /// A width for dialogs/bottom sheets that fits small screens: at most
  /// [maxWidth] (desktop look preserved) and never more than 92% of the screen.
  static double dialogWidth(BuildContext context, {double maxWidth = 400}) {
    final w = widthOf(context);
    final capped = w * 0.92;
    return capped < maxWidth ? capped : maxWidth;
  }

  /// A max height for dialog content so it never exceeds the viewport on small
  /// screens. Defaults to 85% of the available height.
  static double dialogMaxHeight(BuildContext context, {double fraction = 0.85}) {
    return heightOf(context) * fraction;
  }
}
