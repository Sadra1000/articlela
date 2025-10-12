import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/services/dio_client.dart';
import '../../core/data/services/env_config.dart';
import '../../core/data/services/file_exporter.dart';
import '../../core/data/services/in_memory_article_cache.dart';
import '../../core/data/services/key_store.dart';
import '../../core/domain/repositories/article_repository.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../features/keyword_config/domain/usecases/save_search_prefs_usecase.dart';
import '../../features/keyword_config/presentation/viewmodels/keyword_config_viewmodel.dart';
import '../../features/onboarding/domain/usecases/set_language_usecase.dart';
import '../../features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import '../../features/article_details/data/services/abstract_fetcher.dart';
import '../../features/article_details/data/services/google_translate_service.dart';
import '../../features/article_details/presentation/viewmodels/article_details_viewmodel.dart';
import '../../features/search_results/data/datasources/crossref_api_datasource.dart';
import '../../features/search_results/data/datasources/openalex_api_datasource.dart';
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
  getIt.registerLazySingleton<KeyStore>(() => KeyStoreImpl(getIt<SharedPreferences>()));
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt<Dio>(), getIt<KeyStore>()));
  getIt.registerLazySingleton<FileExporter>(FileExporter.new);
  getIt.registerLazySingleton<InMemoryArticleCache>(InMemoryArticleCache.new);
  getIt.registerLazySingleton<IAbstractFetcher>(() => AbstractFetcher(getIt<DioClient>()));
  getIt.registerLazySingleton<ArticleTranslator>(() => GoogleTranslateService(getIt<DioClient>()));

  getIt.registerLazySingleton<CrossrefApiDatasource>(
    () => CrossrefApiDatasource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<ScopusApiDatasource>(
    () => ScopusApiDatasource(getIt<DioClient>()),
  );
  getIt.registerLazySingleton<OpenAlexApiDatasource>(
    () => OpenAlexApiDatasource(getIt<DioClient>()),
  );

  getIt.registerLazySingleton<ArticleRepository>(
    () => ArticleRepositoryImpl(
      getIt<CrossrefApiDatasource>(),
      getIt<ScopusApiDatasource>(),
      getIt<OpenAlexApiDatasource>(),
    ),
  );

  getIt.registerLazySingleton(() => SetLanguageUseCase(getIt<SharedPreferences>()));
  getIt.registerLazySingleton(() => SaveSearchPrefsUseCase(getIt<SharedPreferences>()));
  getIt.registerLazySingleton(() => FetchArticlesUseCase(getIt<ArticleRepository>(), getIt<InMemoryArticleCache>()));
  getIt.registerLazySingleton(() => ExportArticlesUseCase(getIt<FileExporter>()));

  getIt.registerFactory(() => OnboardingViewModel(getIt<SetLanguageUseCase>(), getIt<KeyStore>()));
  getIt.registerFactory(() => HomeViewModel());
  getIt.registerFactory(
    () => KeywordConfigViewModel(
      saveSearchPrefsUseCase: getIt<SaveSearchPrefsUseCase>(),
      keyStore: getIt<KeyStore>(),
    ),
  );
  getIt.registerFactory(
    () => SearchResultsViewModel(
      fetchArticlesUseCase: getIt<FetchArticlesUseCase>(),
      exportArticlesUseCase: getIt<ExportArticlesUseCase>(),
    ),
  );
  getIt.registerFactory(() => ArticleDetailsViewModel(getIt<IAbstractFetcher>(), getIt<ArticleTranslator>()));
}
