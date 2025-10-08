import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';

abstract class KeyStore {
  Future<void> saveElsevierKey(String key, {bool scopusEnabled = true});
  Future<String?> getElsevierKey();
  Future<void> saveCrossrefMailto(String email);
  Future<String?> getCrossrefMailto();
  Future<bool> isKeysConfigured();
  Future<void> markOnboardingCompleted();
  Future<bool> isOnboardingCompleted();
  Future<void> resetOnboarding();
  Future<void> setScopusEnabled(bool enabled);
  Future<bool> isScopusEnabled();
}

class KeyStoreImpl implements KeyStore {
  KeyStoreImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> markOnboardingCompleted() async {
    await _prefs.setBool(AppConstants.onboardingCompletedKey, true);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return _prefs.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  @override
  Future<void> saveElsevierKey(String key, {bool scopusEnabled = true}) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(AppConstants.elsevierApiKey);
    } else {
      await _prefs.setString(AppConstants.elsevierApiKey, trimmed);
    }
    await setScopusEnabled(scopusEnabled && trimmed.isNotEmpty);
  }

  @override
  Future<String?> getElsevierKey() async {
    final value = _prefs.getString(AppConstants.elsevierApiKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  @override
  Future<void> saveCrossrefMailto(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(AppConstants.crossrefMailtoKey);
    } else {
      await _prefs.setString(AppConstants.crossrefMailtoKey, trimmed);
    }
  }

  @override
  Future<String?> getCrossrefMailto() async {
    final value = _prefs.getString(AppConstants.crossrefMailtoKey);
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  @override
  Future<bool> isKeysConfigured() async {
    final scopusEnabled = await isScopusEnabled();
    final key = await getElsevierKey();
    return scopusEnabled ? key != null : true;
  }

  @override
  Future<void> resetOnboarding() async {
    await _prefs.remove(AppConstants.onboardingCompletedKey);
    await _prefs.remove(AppConstants.elsevierApiKey);
    await _prefs.remove(AppConstants.crossrefMailtoKey);
    await setScopusEnabled(false);
  }

  @override
  Future<void> setScopusEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.scopusEnabledKey, enabled);
  }

  @override
  Future<bool> isScopusEnabled() async {
    return _prefs.getBool(AppConstants.scopusEnabledKey) ?? false;
  }
}
