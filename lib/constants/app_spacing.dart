/// ✅ NEW — Centralized spacing/sizing system so the whole app uses
/// consistent gaps, radii, icon sizes, and elevations instead of magic
/// numbers scattered across screens (8, 12, 16, 20... repeated everywhere
/// with slight inconsistencies).
///
/// Usage: `SizedBox(height: AppSpacing.md)`, `BorderRadius.circular(AppSpacing.radiusLg)`
class AppSpacing {
  AppSpacing._(); // no instances — static constants only

  // ── Padding / gap scale ───────────────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // ── Border radius scale ──────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusFull = 999; // pill-shaped buttons/badges

  // ── Icon sizes ────────────────────────────────────────────────────────
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;

  // ── Elevation levels ──────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 2;
  static const double elevationMedium = 4;
  static const double elevationHigh = 8;
}