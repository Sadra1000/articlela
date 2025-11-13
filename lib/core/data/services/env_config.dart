import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';

class EnvConfig {
  EnvConfig(this._prefs, this._dotEnv);

  final SharedPreferences _prefs;
  final DotEnv _dotEnv;

  String? get savedLanguageCode => _prefs.getString(AppConstants.languageKey);

  String? get savedThemeMode => _prefs.getString(AppConstants.themeModeKey);

  String? get deepSeekApiKey {
    final value = _dotEnv.maybeGet('DEEPSEEK_API_KEY');
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
