import 'package:flutter/material.dart';

class AppColors {
  // Primary Red Palette
  static const Color primaryRed = Color(0xFFDC143C);       // Crimson
  static const Color primaryDarkRed = Color(0xFF8B0000);   // Dark red
  static const Color primaryLightRed = Color(0xFFE53935);  // Bright red accent

  // Legacy alias — retained so existing imports compile
  // Remapped to a deep red instead of blue for single-theme consistency
  static const Color secondaryBlue = Color(0xFFB71C1C);

  static const Color secondaryGreen = Color(0xFF4CAF50);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFFFF8F00); // Amber — replaces blue

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryRed, primaryDarkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [primaryDarkRed, Color(0xFF5A0000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color onboardingRed = Color(0xFFD32F2F);
}
