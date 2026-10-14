import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static const _key = 'app_language';
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isUrdu => _locale.languageCode == 'ur';

  LocaleController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      if (value == 'en' || value == 'ur') _locale = Locale(value!);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'ur') return;
    _locale = Locale(code);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (_) {}
  }
}
