class AppConstants {
  const AppConstants._();

  static const String appName = 'ArticleLA';
  static const String crossrefBaseUrl = 'https://api.crossref.org';
  static const String scopusBaseUrl = 'https://api.elsevier.com';
  static const String openAlexBaseUrl = 'https://api.openalex.org';
  static const int crossrefPageSize = 200;
  static const int scopusPageSize = 25;
  static const String searchPrefsKey = 'search_prefs';
  static const String languageKey = 'app_language';
  static const String themeModeKey = 'app_theme_mode';
  static const String crossrefMailtoKey = 'crossref_mailto';
  static const String elsevierApiKey = 'elsevier_api_key';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String scopusEnabledKey = 'scopus_enabled';
  static const String downloadsFolderName = 'Downloads';
  static const int defaultVisibleLimit = 500;
  static const Duration minIngestionDelay = Duration(milliseconds: 150);
  static const Duration maxIngestionDelay = Duration(milliseconds: 250);

  static int get currentYear => DateTime.now().year;
  static int get defaultFromYear => currentYear - 5;
}
