import 'package:articlela/core/data/services/google_translate_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_state.dart';
import '../../../../app/di/service_locator.dart';
import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/services/key_store.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSaving = false;
  bool _isLoadingKeys = true;
  late String _languageCode;
  late ThemeMode _themeMode;
  late TranslationProvider _translationProvider;
  bool _scopusEnabled = false;
  String? _elsevierKey;
  String? _crossrefMailto;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateNotifier>();
    _languageCode = appState.locale.languageCode;
    _themeMode = appState.themeMode;
    final prefs = getIt<SharedPreferences>();
    _translationProvider = translationProviderFromName(
      prefs.getString(AppConstants.translationProviderKey),
    );
    _loadApiState();
  }

  Future<void> _loadApiState() async {
    final keyStore = getIt<KeyStore>();
    final key = await keyStore.getElsevierKey();
    final mailto = await keyStore.getCrossrefMailto();
    final scopusEnabled = await keyStore.isScopusEnabled();
    if (!mounted) return;
    setState(() {
      _elsevierKey = key;
      _crossrefMailto = mailto;
      _scopusEnabled = scopusEnabled;
      _isLoadingKeys = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
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
          _buildSectionTitle(l10n.settingsTranslationSection),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 12.w,
            children: [
              ChoiceChip(
                label: Text(l10n.settingsTranslationDeepSeek),
                selected: _translationProvider == TranslationProvider.deepseek,
                onSelected: (_) => setState(
                  () => _translationProvider = TranslationProvider.deepseek,
                ),
              ),
              ChoiceChip(
                label: Text(l10n.settingsTranslationGoogle),
                selected: _translationProvider == TranslationProvider.google,
                onSelected: (_) => setState(
                  () => _translationProvider = TranslationProvider.google,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.settingsTranslationHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          SizedBox(height: 24.h),
          _buildSectionTitle(l10n.settingsApiSection),
          SizedBox(height: 12.h),
          _isLoadingKeys
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: LoadingIndicator(size: 28),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoTile(
                      title: l10n.settingsScopusStatus,
                      value: _scopusEnabled ? l10n.settingsScopusEnabled : l10n.settingsScopusDisabled,
                      icon: _scopusEnabled ? Icons.verified_outlined : Icons.visibility_off_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _InfoTile(
                      title: l10n.settingsElsevierKey,
                      value: _maskKey(_elsevierKey, l10n),
                      icon: Icons.key_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _InfoTile(
                      title: l10n.settingsCrossrefMailto,
                      value: _crossrefMailto ?? l10n.settingsValueNotSet,
                      icon: Icons.email_outlined,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      l10n.settingsApiHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
          SizedBox(height: 32.h),
          CustomButton(
            label: l10n.settingsSave,
            onPressed: _isSaving ? null : () => _save(context),
            icon: _isSaving ? const LoadingIndicator(size: 22) : null,
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: _resetOnboarding,
            child: Text(l10n.settingsResetOnboarding),
          ),
        ],
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
    final prefs = getIt<SharedPreferences>();
    final appState = context.read<AppStateNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    setState(() => _isSaving = true);

    await prefs.setString(AppConstants.languageKey, _languageCode);
    await prefs.setString(AppConstants.themeModeKey, _themeMode.name);
    await prefs.setString(
      AppConstants.translationProviderKey,
      _translationProvider.name,
    );

    appState.updateLocale(Locale(_languageCode));
    appState.updateTheme(_themeMode);

    if (!mounted) return;
    setState(() => _isSaving = false);
    messenger.showSnackBar(SnackBar(content: Text(l10n.snackbarSettingsSaved)));
  }

  Future<void> _resetOnboarding() async {
    final keyStore = getIt<KeyStore>();
    await keyStore.resetOnboarding();
    await _loadApiState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.settingsResetOnboardingMessage)),
    );
  }

  String _maskKey(String? key, AppLocalizations l10n) {
    if (key == null || key.isEmpty) {
      return l10n.settingsValueNotSet;
    }
    if (key.length <= 4) {
      return '****';
    }
    final prefix = key.substring(0, 2);
    final suffix = key.substring(key.length - 2);
    return '$prefix••••$suffix';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
