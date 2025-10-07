import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';

class EnvConfig {
  EnvConfig(this._prefs);

  final SharedPreferences _prefs;

  String? get elsevierApiKey => _readString(
        preferenceKey: AppConstants.elsevierApiKey,
        envKey: 'ELSEVIER_API_KEY',
      );

  String? get crossrefMailto => _readString(
        preferenceKey: AppConstants.crossrefMailtoKey,
        envKey: 'CROSSREF_MAILTO',
      );

  String? get savedLanguageCode => _prefs.getString(AppConstants.languageKey);

  String? get savedThemeMode => _prefs.getString(AppConstants.themeModeKey);

  String? _readString({
    required String preferenceKey,
    required String envKey,
  }) {
    final prefValue = _prefs.getString(preferenceKey);
    if (prefValue != null && prefValue.trim().isNotEmpty) {
      return prefValue.trim();
    }
    final envValue = dotenv.maybeGet(envKey);
    if (envValue != null && envValue.trim().isNotEmpty) {
      return envValue.trim();
    }
    return null;
  }
}
