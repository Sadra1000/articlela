import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/models/api_result.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../../domain/usecases/export_articles_usecase.dart';
import '../../domain/usecases/fetch_articles_usecase.dart';

enum SearchSortOption {
  nameAsc,
  nameDesc,
  yearAsc,
  yearDesc,
}

class SearchResultsViewModel extends ChangeNotifier {
  SearchResultsViewModel({
    required FetchArticlesUseCase fetchArticlesUseCase,
    required ExportArticlesUseCase exportArticlesUseCase,
  })  : _fetchArticlesUseCase = fetchArticlesUseCase,
        _exportArticlesUseCase = exportArticlesUseCase;

  final FetchArticlesUseCase _fetchArticlesUseCase;
  final ExportArticlesUseCase _exportArticlesUseCase;

  final List<ArticleEntity> _articles = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isExporting = false;
  String? _error;
  bool _hasMore = false;

  String? _nextCrossrefCursor;
  int _nextScopusStart = 0;
  SearchFilterEntity? _currentFilter;
  SearchSortOption _sortOption = SearchSortOption.yearDesc;

  List<ArticleEntity> get articles => List.unmodifiable(_articles);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isExporting => _isExporting;
  String? get error => _error;
  bool get hasMore => _hasMore;
  SearchSortOption get sortOption => _sortOption;
  SearchFilterEntity? get currentFilter => _currentFilter;

  Future<void> fetchInitial(SearchFilterEntity filter) async {
    _currentFilter = filter;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _articles.clear();
    notifyListeners();

    final result = await _fetchArticlesUseCase(
      filter,
      crossrefCursor: null,
      scopusStart: 0,
    );

    if (result.isSuccess && result.data != null) {
      final payload = result.data!;
      _mergeArticles(payload.articles, replace: true);
      _nextCrossrefCursor = payload.nextCrossrefCursor;
      _nextScopusStart = payload.nextScopusStart;
      _hasMore = payload.hasMore;
      _applySort();
    } else {
      _error = result.message ?? 'Unknown error';
      _hasMore = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _currentFilter == null) {
      return;
    }
    _isLoadingMore = true;
    notifyListeners();

    final result = await _fetchArticlesUseCase(
      _currentFilter!,
      crossrefCursor: _nextCrossrefCursor,
      scopusStart: _nextScopusStart,
    );

    if (result.isSuccess && result.data != null) {
      final payload = result.data!;
      _mergeArticles(payload.articles);
      _nextCrossrefCursor = payload.nextCrossrefCursor;
      _nextScopusStart = payload.nextScopusStart;
      _hasMore = payload.hasMore;
      _applySort();
    } else {
      _error = result.message ?? 'Unknown error';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void sortBy(SearchSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    _applySort();
    notifyListeners();
  }

  Future<ApiResult<String>> exportCsv() async {
    if (_articles.isEmpty) {
      return ApiResult.failure('no_data');
    }
    _isExporting = true;
    notifyListeners();
    final result = await _exportArticlesUseCase(_articles);
    _isExporting = false;
    notifyListeners();
    return result;
  }

  void resetError() {
    _error = null;
    notifyListeners();
  }

  String formattedCount() {
    final formatter = NumberFormat.decimalPattern();
    return formatter.format(_articles.length);
  }

  void _applySort() {
    switch (_sortOption) {
      case SearchSortOption.nameAsc:
        _articles.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SearchSortOption.nameDesc:
        _articles.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SearchSortOption.yearAsc:
        _articles.sort((a, b) => (a.publishedYear ?? 0).compareTo(b.publishedYear ?? 0));
        break;
      case SearchSortOption.yearDesc:
        _articles.sort((a, b) => (b.publishedYear ?? 0).compareTo(a.publishedYear ?? 0));
        break;
    }
  }

  void _mergeArticles(List<ArticleEntity> newArticles, {bool replace = false}) {
    if (replace) {
      _articles.clear();
    }
    final Map<String, ArticleEntity> merged = {
      for (final article in _articles)
        (article.doi?.toLowerCase() ?? '${article.title.toLowerCase()}_${article.publishedYear ?? 0}_${article.source}')
            : article,
    };
    for (final article in newArticles) {
      final key = article.doi?.toLowerCase() ??
          '${article.title.toLowerCase()}_${article.publishedYear ?? 0}_${article.source}';
      merged[key] = article;
    }
    _articles
      ..clear()
      ..addAll(merged.values);
  }
}
