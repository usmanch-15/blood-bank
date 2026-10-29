import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_surfaces.dart';

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
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
    color: AppSurfaces.scheme(brightness).surfaceContainerLow,
    margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  );

  static ChipThemeData _chipTheme(Brightness brightness) => ChipThemeData(
    backgroundColor:
        brightness == Brightness.light
            ? AppColors.backgroundLight
            : const Color(0xFF2A2A2A),
    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
    ),
  );

  static DialogThemeData _dialogTheme(Brightness brightness) => DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
    ),
    backgroundColor: AppSurfaces.scheme(brightness).surfaceContainerLow,
    elevation: 2,
  );

  static final BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    elevation: 4,
  );

  static InputDecorationTheme _inputTheme(Brightness brightness) =>
      InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color:
                brightness == Brightness.light
                    ? AppColors.textHint
                    : Colors.grey.shade700,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color:
                brightness == Brightness.light
                    ? AppColors.textHint
                    : Colors.grey.shade700,
          ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      );

  // 🔴 Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: AppSurfaces.scheme(Brightness.light),
    scaffoldBackgroundColor: AppSurfaces.scheme(Brightness.light).surface,
    textTheme: _textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppSurfaces.scheme(Brightness.light).surface,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9E2333),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
        minimumSize: const Size(48, 48),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF9E2333),
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF9E2333),
      foregroundColor: Colors.white,
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: AppSurfaces.scheme(Brightness.light).onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppSurfaces.scheme(Brightness.light).surfaceContainerLow,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
    colorScheme: AppSurfaces.scheme(Brightness.dark),
    scaffoldBackgroundColor: AppSurfaces.scheme(Brightness.dark).surface,
    textTheme: _textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppSurfaces.scheme(Brightness.dark).surface,
      foregroundColor: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9E2333),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
        minimumSize: const Size(48, 48),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF9E2333),
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: AppSurfaces.scheme(Brightness.dark).onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppSurfaces.scheme(Brightness.dark).surfaceContainerLow,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    inputDecorationTheme: _inputTheme(Brightness.dark),
    cardTheme: _cardTheme(Brightness.dark),
    chipTheme: _chipTheme(Brightness.dark),
    dialogTheme: _dialogTheme(Brightness.dark),
    bottomSheetTheme: _bottomSheetTheme,
  );
}
