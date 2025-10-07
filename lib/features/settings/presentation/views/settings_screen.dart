import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_state.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/services/env_config.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../app/di/service_locator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _crossrefController = TextEditingController();
  final _elsevierController = TextEditingController();

  bool _mailtoFromEnv = false;
  bool _apiKeyFromEnv = false;
  bool _isSaving = false;
  late String _languageCode;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    final prefs = getIt<SharedPreferences>();
    final env = getIt<EnvConfig>();
    final appState = context.read<AppStateNotifier>();

    _languageCode = appState.locale.languageCode;
    _themeMode = appState.themeMode;

    final storedMailto = prefs.getString(AppConstants.crossrefMailtoKey);
    final storedApiKey = prefs.getString(AppConstants.elsevierApiKey);

    final envMailto = env.crossrefMailto;
    final envApiKey = env.elsevierApiKey;

    if (storedMailto != null && storedMailto.isNotEmpty) {
      _crossrefController.text = storedMailto;
    } else if (envMailto != null && envMailto.isNotEmpty) {
      _crossrefController.text = envMailto;
      _mailtoFromEnv = true;
    }

    if (storedApiKey != null && storedApiKey.isNotEmpty) {
      _elsevierController.text = storedApiKey;
    } else if (envApiKey != null && envApiKey.isNotEmpty) {
      _elsevierController.text = envApiKey;
      _apiKeyFromEnv = true;
    }
  }

  @override
  void dispose() {
    _crossrefController.dispose();
    _elsevierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                height: 220.h,
                child: Lottie.asset('assets/lottie/settings.json'),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle(l10n.settingsLanguageSection),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              children: [
                ChoiceChip(
                  label: Text(l10n.languageEnglish),
                  selected: _languageCode == 'en',
                  onSelected: (_) => setState(() => _languageCode = 'en'),
                ),
                ChoiceChip(
                  label: Text(l10n.languagePersian),
                  selected: _languageCode == 'fa',
                  onSelected: (_) => setState(() => _languageCode = 'fa'),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle(l10n.settingsThemeSection),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              children: [
                ChoiceChip(
                  label: Text(l10n.settingsThemeLight),
                  selected: _themeMode == ThemeMode.light,
                  onSelected: (_) => setState(() => _themeMode = ThemeMode.light),
                ),
                ChoiceChip(
                  label: Text(l10n.settingsThemeDark),
                  selected: _themeMode == ThemeMode.dark,
                  onSelected: (_) => setState(() => _themeMode = ThemeMode.dark),
                ),
                ChoiceChip(
                  label: Text(l10n.settingsThemeSystem),
                  selected: _themeMode == ThemeMode.system,
                  onSelected: (_) => setState(() => _themeMode = ThemeMode.system),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildSectionTitle(l10n.settingsApiSection),
            SizedBox(height: 12.h),
            TextField(
              controller: _crossrefController,
              decoration: InputDecoration(
                labelText: l10n.settingsCrossrefMailto,
                hintText: l10n.settingsCrossrefMailtoHint,
                helperText: _mailtoFromEnv ? l10n.settingsSourceEnv : null,
              ),
              onChanged: (_) {
                if (_mailtoFromEnv) {
                  setState(() => _mailtoFromEnv = false);
                }
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _elsevierController,
              decoration: InputDecoration(
                labelText: l10n.settingsElsevierKey,
                hintText: l10n.settingsElsevierKeyHint,
                helperText: _apiKeyFromEnv ? l10n.settingsSourceEnv : null,
              ),
              onChanged: (_) {
                if (_apiKeyFromEnv) {
                  setState(() => _apiKeyFromEnv = false);
                }
              },
            ),
            SizedBox(height: 32.h),
            Align(
              alignment: Alignment.centerLeft,
              child: CustomButton(
                label: l10n.settingsSave,
                onPressed: _isSaving ? null : () => _save(context),
                icon: _isSaving ? const LoadingIndicator(size: 22) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = context.l10n;
    final prefs = getIt<SharedPreferences>();
    final appState = context.read<AppStateNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = l10n.snackbarSettingsSaved;

    setState(() => _isSaving = true);

    final mailto = _crossrefController.text.trim();
    final apiKey = _elsevierController.text.trim();

    if (mailto.isEmpty) {
      await prefs.remove(AppConstants.crossrefMailtoKey);
    } else {
      await prefs.setString(AppConstants.crossrefMailtoKey, mailto);
    }

    if (apiKey.isEmpty) {
      await prefs.remove(AppConstants.elsevierApiKey);
    } else {
      await prefs.setString(AppConstants.elsevierApiKey, apiKey);
    }

    await prefs.setString(AppConstants.languageKey, _languageCode);
    await prefs.setString(AppConstants.themeModeKey, _themeMode.name);

    appState.updateLocale(Locale(_languageCode));
    appState.updateTheme(_themeMode);

    if (!mounted) return;
    setState(() => _isSaving = false);

    messenger.showSnackBar(
      SnackBar(content: Text(successMessage)),
    );
  }
}
