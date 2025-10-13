import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/in_memory_article_cache.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/domain/repositories/article_repository.dart'
    as repository;
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../../domain/usecases/export_articles_usecase.dart';
import '../../domain/usecases/fetch_articles_usecase.dart';

enum SearchSortOption { nameAsc, nameDesc, yearAsc, yearDesc }

class SearchResultsViewModel extends ChangeNotifier {
  SearchResultsViewModel({
    required FetchArticlesUseCase fetchArticlesUseCase,
    required ExportArticlesUseCase exportArticlesUseCase,
  }) : _fetchArticlesUseCase = fetchArticlesUseCase,
       _exportArticlesUseCase = exportArticlesUseCase,
       _cache = fetchArticlesUseCase.cache;

  final FetchArticlesUseCase _fetchArticlesUseCase;
  final ExportArticlesUseCase _exportArticlesUseCase;
  final InMemoryArticleCache _cache;
  final Map<DataSource, repository.FetchProgress> _progress = {};
  final List<ArticleEntity> _visibleArticles = [];
  StageReviewState? _stageReviewState;

  bool _isFetching = false;
  bool _isExporting = false;
  bool _ingestionComplete = false;
  String? _error;
  SearchFilterEntity? _currentFilter;
  SearchSortOption _sortOption = SearchSortOption.yearDesc;
  int _visibleLimit = AppConstants.defaultVisibleLimit;

  List<ArticleEntity> get articles => List.unmodifiable(_visibleArticles);
  bool get isFetching => _isFetching;
  bool get isExporting => _isExporting;
  bool get ingestionComplete => _ingestionComplete;
  String? get error => _error;
  SearchSortOption get sortOption => _sortOption;
  SearchFilterEntity? get currentFilter => _currentFilter;
  int get totalResults => _cache.length;
  List<ArticleEntity> get allArticles => _cache.all();
  bool get canShowMore => _visibleLimit < _cache.length;
  Iterable<repository.FetchProgress> get progress => _progress.values;
  int get selectedSourceCount => _currentFilter?.sources.length ?? 0;
  int get combinedFetched =>
      _progress.values.fold(0, (sum, item) => sum + item.fetchedItems);
  StageReviewState? get stageReviewState => _stageReviewState;

  Future<void> fetchAll(SearchFilterEntity filter) async {
    _currentFilter = filter;
    _isFetching = true;
    _ingestionComplete = false;
    _visibleLimit = AppConstants.defaultVisibleLimit;
    _visibleArticles.clear();
    _progress.clear();
    _cache.clear();
    _stageReviewState = null;
    _error = null;
    notifyListeners();

    final result = await _fetchArticlesUseCase.fetchAllToCache(
      filter,
      _handleProgress,
    );

    if (result.isSuccess && result.data != null) {
      _applySortOnCache();
      _refreshVisibleArticles();
      _ingestionComplete = true;
    } else {
      _error = result.message ?? 'Unknown error';
    }

    _isFetching = false;
    notifyListeners();
  }

  void _handleProgress(repository.FetchProgress progress) {
    _progress[progress.source] = progress;
    notifyListeners();
  }

  void sortBy(SearchSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _applySortOnCache();
    _refreshVisibleArticles();
    notifyListeners();
  }

  Future<ApiResult<String>> exportCsv() async {
    if (_cache.length == 0) {
      return ApiResult.failure('no_data');
    }
    _isExporting = true;
    notifyListeners();
    final allArticles = _cache.all();
    final exportResult = await _exportArticlesUseCase(allArticles);
    _isExporting = false;
    notifyListeners();
    return exportResult;
  }

  void showNextBatch() {
    if (!canShowMore) return;
    _visibleLimit += AppConstants.defaultVisibleLimit;
    _refreshVisibleArticles();
    notifyListeners();
  }

  void resetError() {
    _error = null;
    notifyListeners();
  }

  void updateStageReviewState(StageReviewState? state) {
    _stageReviewState = state;
  }

  String formattedTotalCount() {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(totalResults);
  }

  String formattedVisibleCount() {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(_visibleArticles.length);
  }

  void _applySortOnCache() {
    final sorted = _cache.all().toList();
    switch (_sortOption) {
      case SearchSortOption.nameAsc:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case SearchSortOption.nameDesc:
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case SearchSortOption.yearAsc:
        sorted.sort(
          (a, b) => (a.publishedYear ?? 0).compareTo(b.publishedYear ?? 0),
        );
        break;
      case SearchSortOption.yearDesc:
        sorted.sort(
          (a, b) => (b.publishedYear ?? 0).compareTo(a.publishedYear ?? 0),
        );
        break;
    }
    _cache.replaceAll(sorted);
  }

  void _refreshVisibleArticles() {
    final end = _visibleLimit.clamp(0, _cache.length);
    final nextSlice = _cache.slice(0, end);
    _visibleArticles
      ..clear()
      ..addAll(nextSlice);
  }
}
