import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/domain/entities/article_entity.dart';
import '../../features/about/presentation/views/about_screen.dart';
import '../../features/article_details/presentation/viewmodels/article_details_viewmodel.dart';
import '../../features/article_details/presentation/views/article_details_screen.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../features/home/presentation/views/home_screen.dart';
import '../../features/keyword_config/domain/entities/search_filter_entity.dart';
import '../../features/keyword_config/presentation/viewmodels/keyword_config_viewmodel.dart';
import '../../features/keyword_config/presentation/views/keyword_config_screen.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import '../../features/onboarding/presentation/views/onboarding_screen.dart';
import '../../features/pdf_reader/presentation/viewmodels/pdf_reader_viewmodel.dart';
import '../../features/pdf_reader/presentation/views/pdf_reader_screen.dart';
import '../../features/search_results/presentation/viewmodels/search_results_viewmodel.dart';
import '../../features/search_results/presentation/views/search_results_screen.dart';
import '../../features/search_results/domain/usecases/export_articles_usecase.dart';
import '../../features/settings/presentation/views/settings_screen.dart';
import '../../features/shell/presentation/views/app_shell.dart';
import '../../features/review/navigation/review_routes.dart';
import '../../features/review/presentation/stage_review_page.dart';
import '../../features/review/presentation/viewmodel/stage_review_viewmodel.dart';
import '../di/service_locator.dart';
import '../theme/app_colors.dart';
import '../../features/article_details/data/services/google_translate_service.dart';

class AppRouter {
  static const String onboarding = '/';
  static const String home = '/home';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String keywordConfig = '/keywords';
  static const String results = '/results';
  static const String articleDetails = '/articleDetails';
  static const String stageReview = '/stageReview';
  static const String pdfReader = '/pdfReader';
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
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
      case '/home':
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
      case '/about':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AppShell(
            preset: GradientPreset.about,
            titleBuilder: (l10n) => l10n.aboutTitle,
            child: const AboutScreen(),
          ),
        );
      case '/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AppShell(
            preset: GradientPreset.settings,
            titleBuilder: (l10n) => l10n.settingsTitle,
            child: const SettingsScreen(),
          ),
        );
      case '/keywords':
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
      case '/results':
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
      case '/articleDetails':
        final detailArgs = settings.arguments;
        if (detailArgs is! ArticleEntity) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => getIt<ArticleDetailsViewModel>(),
            child: AppShell(
              preset: GradientPreset.results,
              titleBuilder: (l10n) => l10n.articleDetailsTitle,
              child: ArticleDetailsScreen(article: detailArgs),
            ),
          ),
        );
      case "/stageReview":
        final reviewArgs = settings.arguments;
        if (reviewArgs is! StageReviewArguments) {
          return _errorRoute();
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeNotifierProvider(
            create: (_) => StageReviewViewModel(
              items: reviewArgs.items,
              exportArticlesUseCase: getIt<ExportArticlesUseCase>(),
              initialState: reviewArgs.initialState,
            ),
            child: AppShell(
              preset: GradientPreset.results,
              titleBuilder: (l10n) => l10n.stageReviewButton,
              child: const StageReviewPage(),
            ),
          ),
        );
      case pdfReader:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => ChangeNotifierProvider(
            create: (_) => PdfReaderViewModel(getIt<ArticleTranslator>()),
            child: AppShell(
              preset: GradientPreset.reader,
              titleBuilder: (l10n) => l10n.pdfReaderTitle,
              child: const PdfReaderScreen(),
            ),
          ),
        );
      default:
        return _errorRoute();
    }
  }

  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) =>
          const Scaffold(body: Center(child: Text('Route not found'))),
    );
  }
}
