import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';

class EnvConfig {
  EnvConfig(this._prefs);

  final SharedPreferences _prefs;

  String? get savedLanguageCode => _prefs.getString(AppConstants.languageKey);

  String? get savedThemeMode => _prefs.getString(AppConstants.themeModeKey);
}
