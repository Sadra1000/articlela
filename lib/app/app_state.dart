import 'package:flutter/material.dart';

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier({
    required Locale initialLocale,
    required ThemeMode initialThemeMode,
  })  : _locale = initialLocale,
        _themeMode = initialThemeMode;

  Locale _locale;
  ThemeMode _themeMode;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  void updateLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void updateTheme(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}
