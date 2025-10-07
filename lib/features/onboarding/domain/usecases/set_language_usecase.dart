import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

class SetLanguageUseCase {
  SetLanguageUseCase(this._prefs);

  final SharedPreferences _prefs;

  Future<void> call(Locale locale) async {
    await _prefs.setString(AppConstants.languageKey, locale.languageCode);
  }

  Locale resolveInitialLocale() {
    final code = _prefs.getString(AppConstants.languageKey);
    if (code == null) {
      return const Locale('en');
    }
    return Locale(code);
  }
}
