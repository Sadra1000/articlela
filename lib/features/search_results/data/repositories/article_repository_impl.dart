import 'dart:async';
import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/api_result.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/domain/repositories/article_repository.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../datasources/crossref_api_datasource.dart';
import '../datasources/openalex_api_datasource.dart';
import '../datasources/scopus_api_datasource.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl(
    this._crossrefDatasource,
    this._scopusDatasource,
    this._openAlexDatasource,
  );

  final CrossrefApiDatasource _crossrefDatasource;
  final ScopusApiDatasource _scopusDatasource;
  final OpenAlexApiDatasource _openAlexDatasource;
  final Random _random = Random();

  @override
  Future<ApiResult<List<ArticleEntity>>> ingestAll(
    SearchFilterEntity filter,
    void Function(FetchProgress progress) onProgress,
  ) async {
    final dedup = <String, ArticleEntity>{};
    for (final source in filter.sources) {
      final error = await _ingestSource(
        source: source,
        filter: filter,
        onProgress: onProgress,
        dedup: dedup,
      );
      if (error != null) {
        return ApiResult.failure(error);
      }
    }

    final articles = dedup.values.toList()
      ..sort(
        (a, b) => (b.publishedYear ?? 0).compareTo(a.publishedYear ?? 0),
      );
    return ApiResult.success(articles);
  }

  Future<String?> _ingestSource({
    required DataSource source,
    required SearchFilterEntity filter,
    required void Function(FetchProgress progress) onProgress,
    required Map<String, ArticleEntity> dedup,
  }) async {
    switch (source) {
      case DataSource.crossref:
        return _ingestCrossref(filter, dedup, onProgress);
      case DataSource.scopus:
        return _ingestScopus(filter, dedup, onProgress);
      case DataSource.openalex:
        return _ingestOpenAlex(filter, dedup, onProgress);
    }
  }

  Future<String?> _ingestCrossref(
    SearchFilterEntity filter,
    Map<String, ArticleEntity> dedup,
    void Function(FetchProgress progress) onProgress,
  ) async {
    String? cursor;
    var hasMore = true;
    var pages = 0;
    var items = 0;

    while (hasMore) {
      try {
        final result = await _requestWithRetry(
          () => _crossrefDatasource.searchCrossref(
            groups: filter.keywordMatrix,
            fromYear: filter.fromYear,
            toYear: filter.toYear,
            documentTypes: DocumentTypeMapper.crossrefCodes(filter.documentTypes),
            cursor: cursor,
          ),
        );
        _mergeArticles(result.articles, dedup);
        pages += 1;
        items += result.articles.length;
        hasMore = result.hasMore && result.nextCursor != null && result.nextCursor!.isNotEmpty;
        cursor = result.nextCursor;
        onProgress(
          FetchProgress(
            source: DataSource.crossref,
            fetchedPages: pages,
            fetchedItems: items,
            done: !hasMore,
          ),
        );
        if (hasMore) {
          await _politeDelay();
        }
      } on Exception catch (error) {
        return error.toString();
      }
    }
    return null;
  }

  Future<String?> _ingestScopus(
    SearchFilterEntity filter,
    Map<String, ArticleEntity> dedup,
    void Function(FetchProgress progress) onProgress,
  ) async {
    var start = 0;
    var hasMore = true;
    var pages = 0;
    var items = 0;

    while (hasMore) {
      try {
        final result = await _requestWithRetry(
          () => _scopusDatasource.searchScopus(
            groups: filter.keywordMatrix,
            fromYear: filter.fromYear,
            toYear: filter.toYear,
            documentTypes: DocumentTypeMapper.scopusCodes(filter.documentTypes),
            start: start,
          ),
        );
        _mergeArticles(result.articles, dedup);
        pages += 1;
        items += result.articles.length;
        hasMore = result.hasMore && result.nextStart > start;
        start = result.nextStart;
        onProgress(
          FetchProgress(
            source: DataSource.scopus,
            fetchedPages: pages,
            fetchedItems: items,
            done: !hasMore,
          ),
        );
        if (hasMore) {
          await _politeDelay();
        }
      } on Exception catch (error) {
        return error.toString();
      }
    }
    return null;
  }

  Future<String?> _ingestOpenAlex(
    SearchFilterEntity filter,
    Map<String, ArticleEntity> dedup,
    void Function(FetchProgress progress) onProgress,
  ) async {
    String? cursor;
    var hasMore = true;
    var pages = 0;
    var items = 0;

    while (hasMore) {
      try {
        final result = await _requestWithRetry(
          () => _openAlexDatasource.searchOpenAlex(
            groups: filter.keywordMatrix,
            fromYear: filter.fromYear,
            toYear: filter.toYear,
            documentTypes: DocumentTypeMapper.openAlexCodes(filter.documentTypes),
            cursor: cursor,
          ),
        );
        _mergeArticles(result.articles, dedup);
        pages += 1;
        items += result.articles.length;
        hasMore = result.hasMore && result.nextCursor != null && result.nextCursor!.isNotEmpty;
        cursor = result.nextCursor;
        onProgress(
          FetchProgress(
            source: DataSource.openalex,
            fetchedPages: pages,
            fetchedItems: items,
            done: !hasMore,
          ),
        );
        if (hasMore) {
          await _politeDelay();
        }
      } on Exception catch (error) {
        return error.toString();
      }
    }
    return null;
  }

  Future<void> _politeDelay() {
    final minDelay = AppConstants.minIngestionDelay.inMilliseconds;
    final maxDelay = AppConstants.maxIngestionDelay.inMilliseconds;
    final span = max(1, maxDelay - minDelay);
    final delayMs = minDelay + _random.nextInt(span);
    return Future.delayed(Duration(milliseconds: delayMs));
  }

  void _mergeArticles(List<ArticleEntity> articles, Map<String, ArticleEntity> dedup) {
    for (final article in articles) {
      final key = _dedupKey(article);
      dedup[key] = article;
    }
  }

  String _dedupKey(ArticleEntity article) {
    final doiKey = article.doi?.toLowerCase();
    if (doiKey != null && doiKey.isNotEmpty) {
      return doiKey;
    }
    return '${article.title.toLowerCase()}_${article.publishedYear ?? 0}';
  }

  Future<T> _requestWithRetry<T>(Future<ApiResult<T>> Function() request) async {
    var attempt = 0;
    ApiResult<T>? lastResult;
    while (attempt < 4) {
      final result = await request();
      if (result.isSuccess && result.data != null) {
        return result.data as T;
      }
      lastResult = result;
      final message = result.message ?? '';
      if (!message.contains('429')) {
        throw Exception(message);
      }
      attempt += 1;
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
    throw Exception(lastResult?.message ?? 'Request failed');
  }
}
