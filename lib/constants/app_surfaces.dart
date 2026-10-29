import 'package:flutter/material.dart';

/// Neutral surfaces keep urgency and primary actions visually distinct.
abstract final class AppSurfaces {
  static ColorScheme scheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF9E2333),
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFFFFB3B8) : const Color(0xFF9E2333),
      onPrimary: dark ? const Color(0xFF590D1C) : Colors.white,
      surface: dark ? const Color(0xFF151719) : const Color(0xFFFAFAFA),
      surfaceContainerLowest: dark ? const Color(0xFF101214) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF1D2023) : Colors.white,
      surfaceContainer:
          dark ? const Color(0xFF23272A) : const Color(0xFFF1F2F3),
      surfaceContainerHigh:
          dark ? const Color(0xFF2B2F33) : const Color(0xFFEAECED),
      surfaceContainerHighest:
          dark ? const Color(0xFF34393D) : const Color(0xFFE3E6E8),
      onSurface: dark ? const Color(0xFFF2F3F4) : const Color(0xFF202428),
      onSurfaceVariant:
          dark ? const Color(0xFFBCC3C9) : const Color(0xFF505A63),
      outline: dark ? const Color(0xFF8D969E) : const Color(0xFF737D86),
      outlineVariant: dark ? const Color(0xFF41474D) : const Color(0xFFD8DDE1),
    );
  }
}
