import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/services/dio_client.dart';
import '../../core/data/services/env_config.dart';
import '../../core/data/services/file_exporter.dart';
import '../../core/domain/repositories/article_repository.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../features/keyword_config/domain/usecases/save_search_prefs_usecase.dart';
import '../../features/keyword_config/presentation/viewmodels/keyword_config_viewmodel.dart';
import '../../features/onboarding/domain/usecases/set_language_usecase.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import '../../features/search_results/data/datasources/crossref_api_datasource.dart';
import '../../features/search_results/data/datasources/scopus_api_datasource.dart';
import '../../features/search_results/data/repositories/article_repository_impl.dart';
import '../../features/search_results/domain/usecases/export_articles_usecase.dart';
import '../../features/search_results/domain/usecases/fetch_articles_usecase.dart';
import '../../features/search_results/presentation/viewmodels/search_results_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final sharedPrefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<SharedPreferences>(sharedPrefs);
  getIt.registerLazySingleton<EnvConfig>(() => EnvConfig(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<Dio>(), getIt<EnvConfig>()));
  getIt.registerLazySingleton<FileExporter>(FileExporter.new);

  getIt.registerLazySingleton<CrossrefApiDatasource>(
    () => CrossrefApiDatasource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ScopusApiDatasource>(
    () => ScopusApiDatasource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<ArticleRepository>(
    () => ArticleRepositoryImpl(
      getIt<CrossrefApiDatasource>(),
      getIt<ScopusApiDatasource>(),
    ),
  );

  getIt.registerLazySingleton(() => SetLanguageUseCase(getIt<SharedPreferences>()));
  getIt.registerLazySingleton(() => SaveSearchPrefsUseCase(getIt<SharedPreferences>()));
  getIt.registerLazySingleton(() => FetchArticlesUseCase(getIt<ArticleRepository>()));
  getIt.registerLazySingleton(() => ExportArticlesUseCase(getIt<FileExporter>()));

  getIt.registerFactory(() => OnboardingViewModel(getIt<SetLanguageUseCase>()));
  getIt.registerFactory(() => HomeViewModel());
  getIt.registerFactory(
    () => KeywordConfigViewModel(
      saveSearchPrefsUseCase: getIt<SaveSearchPrefsUseCase>(),
    ),
  );
  getIt.registerFactory(
    () => SearchResultsViewModel(
      fetchArticlesUseCase: getIt<FetchArticlesUseCase>(),
      exportArticlesUseCase: getIt<ExportArticlesUseCase>(),
    ),
  );
}
