import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations._(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [
    Locale('en'),
    Locale('fa'),
  ];

  static Future<AppLocalizations> load(Locale locale) async {
    final languageCode = supportedLocales.any((l) => l.languageCode == locale.languageCode)
        ? locale.languageCode
        : supportedLocales.first.languageCode;

    final path = 'assets/l10n/app_$languageCode.arb';
    final jsonString = await rootBundle.loadString(path);
    final Map<String, dynamic> mapped = json.decode(jsonString) as Map<String, dynamic>;

    final filtered = <String, String>{};
    mapped.forEach((key, value) {
      if (!key.startsWith('@') && value is String) {
        filtered[key] = value;
      }
    });

    return AppLocalizations._(Locale(languageCode), filtered);
  }

  bool get isRtl => locale.languageCode == 'fa';

  String get appTitle => _strings['appTitle'] ?? '';
  String get appTagline => _strings['appTagline'] ?? '';
  String get onboardingHeadline => _strings['onboardingHeadline'] ?? '';
  String get onboardingDescription => _strings['onboardingDescription'] ?? '';
  String get onboardingSelectLanguage => _strings['onboardingSelectLanguage'] ?? '';
  String get onboardingContinue => _strings['onboardingContinue'] ?? '';
  String get languageEnglish => _strings['languageEnglish'] ?? '';
  String get languagePersian => _strings['languagePersian'] ?? '';
  String get homeTitle => _strings['homeTitle'] ?? '';
  String get homeSubtitle => _strings['homeSubtitle'] ?? '';
  String get homeStart => _strings['homeStart'] ?? '';
  String get homeAbout => _strings['homeAbout'] ?? '';
  String get homeSettings => _strings['homeSettings'] ?? '';
  String get aboutTitle => _strings['aboutTitle'] ?? '';
  String get aboutParagraphOne => _strings['aboutParagraphOne'] ?? '';
  String get aboutParagraphTwo => _strings['aboutParagraphTwo'] ?? '';
  String get aboutContact => _strings['aboutContact'] ?? '';
  String get aboutSupport => _strings['aboutSupport'] ?? '';
  String get settingsTitle => _strings['settingsTitle'] ?? '';
  String get settingsLanguageSection => _strings['settingsLanguageSection'] ?? '';
  String get settingsApiSection => _strings['settingsApiSection'] ?? '';
  String get settingsThemeSection => _strings['settingsThemeSection'] ?? '';
  String get settingsThemeLight => _strings['settingsThemeLight'] ?? '';
  String get settingsThemeDark => _strings['settingsThemeDark'] ?? '';
  String get settingsThemeSystem => _strings['settingsThemeSystem'] ?? '';
  String get settingsCrossrefMailto => _strings['settingsCrossrefMailto'] ?? '';
  String get settingsCrossrefMailtoHint => _strings['settingsCrossrefMailtoHint'] ?? '';
  String get settingsElsevierKey => _strings['settingsElsevierKey'] ?? '';
  String get settingsElsevierKeyHint => _strings['settingsElsevierKeyHint'] ?? '';
  String get settingsSave => _strings['settingsSave'] ?? '';
  String get settingsSavedMessage => _strings['settingsSavedMessage'] ?? '';
  String get keywordConfigTitle => _strings['keywordConfigTitle'] ?? '';
  String get keywordConfigSubtitle => _strings['keywordConfigSubtitle'] ?? '';
  String get keywordConfigAddGroup => _strings['keywordConfigAddGroup'] ?? '';
  String get keywordConfigRenameGroup => _strings['keywordConfigRenameGroup'] ?? '';
  String get keywordConfigRemoveGroup => _strings['keywordConfigRemoveGroup'] ?? '';
  String get keywordConfigAddKeyword => _strings['keywordConfigAddKeyword'] ?? '';
  String get keywordConfigRemoveKeyword => _strings['keywordConfigRemoveKeyword'] ?? '';
  String get keywordConfigKeywordHint => _strings['keywordConfigKeywordHint'] ?? '';
  String get keywordConfigYearRange => _strings['keywordConfigYearRange'] ?? '';
  String get keywordConfigDocTypes => _strings['keywordConfigDocTypes'] ?? '';
  String get keywordConfigNext => _strings['keywordConfigNext'] ?? '';
  String get keywordConfigErrorEmpty => _strings['keywordConfigErrorEmpty'] ?? '';
  String get keywordConfigErrorNoGroups => _strings['keywordConfigErrorNoGroups'] ?? '';
  String keywordConfigGroupName(int index) {
    final template = _strings['keywordConfigGroupName'] ?? 'Group {index}';
    return template.replaceAll('{index}', index.toString());
  }

  String get searchResultsTitle => _strings['searchResultsTitle'] ?? '';
  String get searchResultsEmpty => _strings['searchResultsEmpty'] ?? '';
  String get searchResultsLoading => _strings['searchResultsLoading'] ?? '';
  String get searchResultsLoadMore => _strings['searchResultsLoadMore'] ?? '';
  String get searchResultsExport => _strings['searchResultsExport'] ?? '';
  String searchResultsTotal(String count) {
    final template = _strings['searchResultsTotal'] ?? '{count}';
    return template.replaceAll('{count}', count);
  }

  String get searchResultsSort => _strings['searchResultsSort'] ?? '';
  String get searchResultsSortNameAsc => _strings['searchResultsSortNameAsc'] ?? '';
  String get searchResultsSortNameDesc => _strings['searchResultsSortNameDesc'] ?? '';
  String get searchResultsSortYearAsc => _strings['searchResultsSortYearAsc'] ?? '';
  String get searchResultsSortYearDesc => _strings['searchResultsSortYearDesc'] ?? '';
  String get searchResultsDocumentType => _strings['searchResultsDocumentType'] ?? '';
  String get searchResultsSource => _strings['searchResultsSource'] ?? '';
  String get searchResultsYear => _strings['searchResultsYear'] ?? '';
  String get searchResultsAbstract => _strings['searchResultsAbstract'] ?? '';
  String get searchResultsOpenLink => _strings['searchResultsOpenLink'] ?? '';
  String get searchResultsNoAbstract => _strings['searchResultsNoAbstract'] ?? '';
  String get searchResultsSourceCrossref => _strings['searchResultsSourceCrossref'] ?? '';
  String get searchResultsSourceScopus => _strings['searchResultsSourceScopus'] ?? '';
  String get errorGeneric => _strings['errorGeneric'] ?? '';
  String get errorMissingKeys => _strings['errorMissingKeys'] ?? '';
  String get retry => _strings['retry'] ?? '';
  String get back => _strings['back'] ?? '';
  String get themeAutoLabel => _strings['themeAutoLabel'] ?? '';
  String get snackbarLanguageSaved => _strings['snackbarLanguageSaved'] ?? '';
  String get snackbarSettingsSaved => _strings['snackbarSettingsSaved'] ?? '';
  String get csvExportSuccess => _strings['csvExportSuccess'] ?? '';
  String get csvExportFailure => _strings['csvExportFailure'] ?? '';
  String get docTypeJournalArticle => _strings['docTypeJournalArticle'] ?? '';
  String get docTypeReview => _strings['docTypeReview'] ?? '';
  String get docTypeBook => _strings['docTypeBook'] ?? '';
  String get docTypeConference => _strings['docTypeConference'] ?? '';
  String get docTypeReport => _strings['docTypeReport'] ?? '';
  String get docTypeThesis => _strings['docTypeThesis'] ?? '';
  String get docTypeOther => _strings['docTypeOther'] ?? '';
  String versionLabel(String version) {
    final template = _strings['versionLabel'] ?? 'Version {version}';
    return template.replaceAll('{version}', version);
  }

  String get settingsSourceEnv => _strings['settingsSourceEnv'] ?? '';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations)!;
  bool get isRtl => l10n.isRtl;
}
