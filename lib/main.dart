import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app_state.dart';
import 'app/di/service_locator.dart';
import 'app/l10n/app_localizations.dart';
import 'app/navigation/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/data/services/env_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);
  await setupServiceLocator();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 780),
      minimumSize: Size(1100, 700),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: AppConstants.appName,
      center: true,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
    });

    doWhenWindowReady(() {
      final initialSize = const Size(1200, 780);
      appWindow
        ..size = initialSize
        ..minSize = const Size(1100, 700)
        ..title = AppConstants.appName
        ..show();
    });
  }

  final env = getIt<EnvConfig>();
  final prefs = getIt<SharedPreferences>();

  final languageCode = env.savedLanguageCode ?? 'en';
  final themePreference = env.savedThemeMode ?? prefs.getString(AppConstants.themeModeKey);

  final initialLocale = Locale(languageCode);
  final initialThemeMode = _themeModeFromString(themePreference);

  final appState = AppStateNotifier(
    initialLocale: initialLocale,
    initialThemeMode: initialThemeMode,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateNotifier>.value(value: appState),
      ],
      child: ArticleLaApp(router: AppRouter()),
    ),
  );
}

class ArticleLaApp extends StatelessWidget {
  const ArticleLaApp({super.key, required this.router});

  final AppRouter router;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      builder: (context, child) {
        final appState = context.watch<AppStateNotifier>();
        final locale = appState.locale;

        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: appState.themeMode,
          theme: AppTheme.light(locale),
          darkTheme: AppTheme.dark(locale),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          initialRoute: AppRouter.onboarding,
          onGenerateRoute: router.onGenerateRoute,
        );
      },
    );
  }
}

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}
