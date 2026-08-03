import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ NEW — manual theme override.
/// ----------------------------------------------------------------------
/// AppTheme.darkTheme already existed and was already wired into
/// MaterialApp (themeMode: ThemeMode.system) — so the app already
/// followed the OS dark/light setting. What was missing is any way for
/// the USER to override that from inside the app (most people expect an
/// explicit Light/Dark/System switch in Settings → Appearance). This
/// controller adds exactly that, and persists the choice locally so it
/// survives app restarts (no Firestore write needed — it's a per-device
/// UI preference, not account data).
class ThemeController extends ChangeNotifier {
  static const _prefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeController() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      // First run / storage unavailable — default (system) is fine.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // Non-fatal — the in-memory choice still applies for this session.
    }
  }
}