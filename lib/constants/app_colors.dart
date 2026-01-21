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
}