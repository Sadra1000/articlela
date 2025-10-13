import 'package:flutter/foundation.dart';

import 'package:articlela/core/data/models/api_result.dart';
import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/features/search_results/domain/usecases/export_articles_usecase.dart';

typedef StageReviewSummaryCallback = void Function();

@immutable
class StageReviewState {
  const StageReviewState({
    required this.index,
    required this.selectedIds,
    this.showSummary = false,
  });

  final int index;
  final Set<String> selectedIds;
  final bool showSummary;

  StageReviewState copyWith({
    int? index,
    Set<String>? selectedIds,
    bool? showSummary,
  }) {
    return StageReviewState(
      index: index ?? this.index,
      selectedIds: selectedIds != null
          ? Set<String>.from(selectedIds)
          : Set<String>.from(this.selectedIds),
      showSummary: showSummary ?? this.showSummary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StageReviewState &&
        other.index == index &&
        other.showSummary == showSummary &&
        setEquals(other.selectedIds, selectedIds);
  }

  @override
  int get hashCode {
    final sorted = selectedIds.toList()..sort();
    return Object.hash(index, showSummary, Object.hashAll(sorted));
  }
}

class StageReviewViewModel with ChangeNotifier {
  StageReviewViewModel({
    required List<ArticleEntity> items,
    required ExportArticlesUseCase exportArticlesUseCase,
    StageReviewState? initialState,
    StageReviewSummaryCallback? onSummaryRequested,
  }) : items = List<ArticleEntity>.unmodifiable(items),
       _exportArticlesUseCase = exportArticlesUseCase,
       _onSummaryRequested = onSummaryRequested ?? _noopSummaryCallback {
    if (initialState != null) {
      index = items.isEmpty ? 0 : initialState.index.clamp(0, items.length - 1);
      selectedIds.addAll(initialState.selectedIds);
      _isSummaryVisible = items.isNotEmpty && initialState.showSummary;
    }
  }

  final List<ArticleEntity> items;
  final ExportArticlesUseCase _exportArticlesUseCase;
  final StageReviewSummaryCallback _onSummaryRequested;
  final Set<String> selectedIds = <String>{};

  int index = 0;
  bool _isSummaryVisible = false;
  bool _isExporting = false;

  ArticleEntity? get current => _inRange(index) ? items[index] : null;
  bool get isLast => items.isEmpty || index >= items.length - 1;
  bool get isSummaryVisible => _isSummaryVisible;
  bool get isExporting => _isExporting;
  int get totalCount => items.length;
  int get progressCurrent => items.isEmpty ? 0 : index + 1;

  void markAddAndNext() {
    final article = current;
    if (article == null || _isSummaryVisible) return;
    selectedIds.add(_resolveKey(article));
    _next();
  }

  void markRemoveAndNext() {
    final article = current;
    if (article == null || _isSummaryVisible) return;
    selectedIds.remove(_resolveKey(article));
    _next();
  }

  void back() {
    if (_isSummaryVisible) return;
    if (index > 0) {
      index -= 1;
      notifyListeners();
    }
  }

  void restart() {
    index = 0;
    selectedIds.clear();
    _isSummaryVisible = false;
    notifyListeners();
  }

  List<ArticleEntity> selectedArticles() {
    final seen = <String>{};
    final results = <ArticleEntity>[];
    for (final article in items) {
      final key = _resolveKey(article);
      if (selectedIds.contains(key) && seen.add(key)) {
        results.add(article);
      }
    }
    return results;
  }

  StageReviewState snapshot() {
    return StageReviewState(
      index: index,
      selectedIds: Set<String>.from(selectedIds),
      showSummary: _isSummaryVisible,
    );
  }

  Future<ApiResult<String>> exportSelected() async {
    final exports = selectedArticles();
    if (exports.isEmpty) {
      return ApiResult.failure('no_selection');
    }
    _isExporting = true;
    notifyListeners();
    try {
      final result = await _exportArticlesUseCase(exports);
      return result;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  void _next() {
    if (items.isEmpty) {
      _navigateToSummary();
      return;
    }

    if (!isLast) {
      index += 1;
      notifyListeners();
      return;
    }
    _navigateToSummary();
  }

  void _navigateToSummary() {
    if (_isSummaryVisible) return;
    _isSummaryVisible = true;
    _onSummaryRequested();
    notifyListeners();
  }

  bool _inRange(int position) => position >= 0 && position < items.length;

  String _resolveKey(ArticleEntity article) {
    final doi = article.doi?.trim();
    if (doi != null && doi.isNotEmpty) {
      return doi.toLowerCase();
    }
    final link = article.link?.trim();
    if (link != null && link.isNotEmpty) {
      return link.toLowerCase();
    }
    final title = article.title.trim().toLowerCase();
    final year = article.publishedYear != null
        ? article.publishedYear.toString()
        : '';
    final source = article.source.trim().toLowerCase();
    return '$source|$title|$year';
  }

  static void _noopSummaryCallback() {}
}
