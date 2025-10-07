import '../../../../core/data/models/api_result.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/domain/repositories/article_repository.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../datasources/crossref_api_datasource.dart';
import '../datasources/scopus_api_datasource.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  ArticleRepositoryImpl(
    this._crossrefDatasource,
    this._scopusDatasource,
  );

  final CrossrefApiDatasource _crossrefDatasource;
  final ScopusApiDatasource _scopusDatasource;

  @override
  Future<ApiResult<ArticlePage>> fetchArticles(
    SearchFilterEntity filter, {
    String? crossrefCursor,
    int? scopusStart,
  }) async {
    final crossrefFuture = _crossrefDatasource.searchCrossref(
      groups: filter.keywordMatrix,
      fromYear: filter.fromYear,
      toYear: filter.toYear,
      documentTypes: DocumentTypeMapper.crossrefCodes(filter.documentTypes),
      cursor: crossrefCursor,
    );

    final scopusFuture = _scopusDatasource.searchScopus(
      groups: filter.keywordMatrix,
      fromYear: filter.fromYear,
      toYear: filter.toYear,
      documentTypes: DocumentTypeMapper.scopusCodes(filter.documentTypes),
      start: scopusStart ?? 0,
    );

    final crossrefResult = await crossrefFuture;
    final scopusResult = await scopusFuture;

    if (!crossrefResult.isSuccess && !scopusResult.isSuccess) {
      return ApiResult.failure(
        crossrefResult.message ?? scopusResult.message ?? 'Unable to fetch articles',
      );
    }

    final buffer = <String, ArticleEntity>{};

    void addArticles(List<ArticleEntity> articles) {
      for (final article in articles) {
        final key = article.doi?.toLowerCase() ??
            '${article.title.toLowerCase()}_${article.publishedYear ?? 0}_${article.source}';
        buffer[key] = article;
      }
    }

    if (crossrefResult.isSuccess && crossrefResult.data != null) {
      addArticles(crossrefResult.data!.articles);
    }
    if (scopusResult.isSuccess && scopusResult.data != null) {
      addArticles(scopusResult.data!.articles);
    }

    final combined = buffer.values.toList()
      ..sort(
        (a, b) => (b.publishedYear ?? 0).compareTo(a.publishedYear ?? 0),
      );

    final nextCursor = crossrefResult.data?.nextCursor;
    final hasMoreCrossref = crossrefResult.data?.hasMore ?? false;

    final nextScopusStart = scopusResult.data?.nextStart ?? (scopusStart ?? 0);
    final hasMoreScopus = scopusResult.data?.hasMore ?? false;

    return ApiResult.success(
      ArticlePage(
        articles: combined,
        nextCrossrefCursor: nextCursor,
        hasMoreCrossref: hasMoreCrossref,
        nextScopusStart: nextScopusStart,
        hasMoreScopus: hasMoreScopus,
      ),
    );
  }
}
