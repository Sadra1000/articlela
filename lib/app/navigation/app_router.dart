import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/about/presentation/views/about_screen.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/keyword_config/domain/entities/search_filter_entity.dart';
import '../../features/keyword_config/presentation/viewmodels/keyword_config_viewmodel.dart';
import '../../features/keyword_config/presentation/views/keyword_config_screen.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import '../../features/onboarding/presentation/views/onboarding_screen.dart';
import '../../features/search_results/presentation/viewmodels/search_results_viewmodel.dart';
import '../../features/search_results/presentation/views/search_results_screen.dart';
import '../../features/settings/presentation/views/settings_screen.dart';
import '../../features/shell/presentation/views/app_shell.dart';
import '../di/service_locator.dart';
import '../theme/app_colors.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String home = '/home';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String keywordConfig = '/keywords';
  static const String results = '/results';

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouter.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => getIt<OnboardingViewModel>(),
            child: const AppShell(
              preset: GradientPreset.onboarding,
              child: OnboardingScreen(),
            ),
          ),
        );
      case AppRouter.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => getIt<HomeViewModel>()..loadVersion(),
            child: AppShell(
              preset: GradientPreset.home,
              titleBuilder: (l10n) => l10n.homeTitle,
              child: const HomeScreen(),
            ),
          ),
        );
      case AppRouter.about:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AppShell(
            preset: GradientPreset.about,
            titleBuilder: (l10n) => l10n.aboutTitle,
            child: const AboutScreen(),
          ),
        );
      case AppRouter.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AppShell(
            preset: GradientPreset.settings,
            titleBuilder: (l10n) => l10n.settingsTitle,
            child: const SettingsScreen(),
          ),
        );
      case AppRouter.keywordConfig:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => getIt<KeywordConfigViewModel>()..initialize(),
            child: AppShell(
              preset: GradientPreset.keyword,
              titleBuilder: (l10n) => l10n.keywordConfigTitle,
              child: const KeywordConfigScreen(),
            ),
          ),
        );
      case AppRouter.results:
        final args = settings.arguments;
        if (args is! SearchFilterEntity) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => getIt<SearchResultsViewModel>(),
            child: AppShell(
              preset: GradientPreset.results,
              titleBuilder: (l10n) => l10n.searchResultsTitle,
              child: SearchResultsScreen(filter: args),
            ),
          ),
        );
      default:
        return _errorRoute();
    }
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text('Route not found'),
        ),
      ),
    );
  }
}
