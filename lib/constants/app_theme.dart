import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  // ── Color constants ──────────────────────────────────────────────────────
  static const Color crimsonDark = Color(0xFFB71C1C);

  // ── ✅ NEW — shared text theme, used by both light + dark below ─────────
  static const TextTheme _textTheme = TextTheme(
    // Headlines
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    // Body
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
    // Labels
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static CardThemeData _cardTheme(Brightness brightness) => CardThemeData(
    elevation: AppSpacing.elevationLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    color: brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E),
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  );

  static ChipThemeData _chipTheme(Brightness brightness) => ChipThemeData(
    backgroundColor: brightness == Brightness.light
        ? AppColors.backgroundLight
        : const Color(0xFF2A2A2A),
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
  );

  static DialogThemeData _dialogTheme(Brightness brightness) => DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    backgroundColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E),
    elevation: AppSpacing.elevationHigh,
  );

  static final BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    elevation: 4,
  );

  static InputDecorationTheme _inputTheme(Brightness brightness) => InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: brightness == Brightness.light ? AppColors.textHint : Colors.grey.shade700),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: brightness == Brightness.light ? AppColors.textHint : Colors.grey.shade700),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
  );

  // 🔴 Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: _textTheme,

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    inputDecorationTheme: _inputTheme(Brightness.light),
    cardTheme: _cardTheme(Brightness.light),
    chipTheme: _chipTheme(Brightness.light),
    dialogTheme: _dialogTheme(Brightness.light),
    bottomSheetTheme: _bottomSheetTheme,
  );

  // ⚫ Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.black,
    textTheme: _textTheme,

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    inputDecorationTheme: _inputTheme(Brightness.dark),
    cardTheme: _cardTheme(Brightness.dark),
    chipTheme: _chipTheme(Brightness.dark),
    dialogTheme: _dialogTheme(Brightness.dark),
    bottomSheetTheme: _bottomSheetTheme,
  );
}