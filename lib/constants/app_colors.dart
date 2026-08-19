import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  // Primary Colors
  static const Color primaryRed = Color(0xFFDC143C); // Crimson Red
  static const Color primaryDarkRed = Color(0xFF8B0000);
  static const Color primaryLightRed = Color(0xFFFF6B6B);

  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color secondaryGreen = Color(0xFF4CAF50);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryRed, primaryDarkRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Additional Colors for Onboarding
  static const Color onboardingRed = Color(0xFFD32F2F); // Added for onboarding

  // ── ✅ NEW additions below — purely additive, nothing above this line
  // was changed, so every existing AppColors.xyz reference across the
  // app keeps working exactly as before. ──────────────────────────────

  // Text hint color (form field placeholders etc.)
  static const Color textHint = Color(0xFFBDBDBD);

  // Shadow colors — for card/button elevation effects
  static const Color shadowLight = Color(0x14000000); // 8% black
  static const Color shadowMedium = Color(0x29000000); // 16% black
  static const Color shadowRed = Color(0x33DC143C); // 20% primaryRed — for red-tinted button/card shadows

  // Additional gradients
  static const LinearGradient redToOrangeGradient = LinearGradient(
    colors: [primaryRed, warning],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [secondaryBlue, Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [secondaryGreen, Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Background gradient — for gradient-header screens (login, SOS card, etc.)
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundLight, backgroundWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [primaryDarkRed, Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── ✅ NEW — professional design-system tokens ──────────────────────
  // Purely additive (nothing above changed), used by the refreshed
  // AppTheme to give cards/surfaces more depth and hierarchy than plain
  // Colors.white everywhere.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFC); // faint off-white for grouped sections
  static const Color border = Color(0xFFE8E8ED);
  static const Color borderStrong = Color(0xFFD8D8E0);

  // A slightly deeper, more premium crimson used for gradients/headers so
  // the app doesn't read as flat "stock Material red".
  static const Color primaryRedDeep = Color(0xFFB3122E);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryRed, primaryRedDeep, primaryDarkRed],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}