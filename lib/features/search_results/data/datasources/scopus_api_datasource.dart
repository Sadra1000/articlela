import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/dio_client.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/utils/query_builder.dart';

class ScopusResponse {
  const ScopusResponse({
    required this.articles,
    required this.nextStart,
    required this.hasMore,
  });

  final List<ArticleEntity> articles;
  final int nextStart;
  final bool hasMore;
}

class ScopusApiDatasource {
  ScopusApiDatasource(this._client);

  final DioClient _client;

  Future<ApiResult<ScopusResponse>> searchScopus({
    required List<List<String>> groups,
    required int fromYear,
    required int toYear,
    required List<String> documentTypes,
    int start = 0,
  }) async {
    try {
      final baseQuery = QueryBuilder.buildScopusQuery(groups);
      final rangeClause = 'PUBYEAR >= $fromYear AND PUBYEAR <= $toYear';
      final docTypeClause = _buildDocTypeClause(documentTypes);
      final combinedQuery = [
        baseQuery,
        rangeClause,
        if (docTypeClause != null) docTypeClause,
      ].join(' AND ');

      final params = <String, dynamic>{
        'query': combinedQuery,
        'count': AppConstants.scopusPageSize,
        'start': start,
        'httpAccept': 'application/json',
        'view': 'COMPLETE',
      };

      final response = await _client.get(
        '${AppConstants.scopusBaseUrl}/content/search/scopus',
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;
      final searchResults = data['search-results'] as Map<String, dynamic>;
      final entries = (searchResults['entry'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final results = <ArticleEntity>[];

      for (final entry in entries) {
        final title = (entry['dc:title'] as String?)?.trim() ?? 'Untitled';
        final doi = (entry['prism:doi'] as String?)?.trim();
        final date = entry['prism:coverDate'] as String?;
        final year = date != null && date.length >= 4 ? int.tryParse(date.substring(0, 4)) : null;
        final docType = (entry['prism:aggregationType'] as String?)?.toLowerCase() ?? 'other';
        final links = (entry['link'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
        final preferredLink = links?.firstWhere(
          (link) => link['@ref'] == 'scopus',
          orElse: () => links.isNotEmpty ? links.first : <String, dynamic>{},
        );
        final linkHref = preferredLink?['@href'] as String?;

        results.add(
          ArticleEntity(
            title: title,
            publishedYear: year,
            doi: doi,
            abstractText: null,
            documentType: docType,
            source: 'SCOPUS',
            link: linkHref,
          ),
        );
      }

      final totalResultsStr = searchResults['opensearch:totalResults'] as String? ?? '0';
      final totalResults = int.tryParse(totalResultsStr) ?? 0;
      final nextStart = start + AppConstants.scopusPageSize;
      final hasMore = nextStart < totalResults;

      return ApiResult.success(
        ScopusResponse(
          articles: results,
          nextStart: nextStart,
          hasMore: hasMore,
        ),
      );
    } on DioException catch (error) {
      return ApiResult.failure(error.message ?? 'Scopus request failed');
    } catch (error) {
      return ApiResult.failure(error.toString());
    }
  }

  String? _buildDocTypeClause(List<String> documentTypes) {
    if (documentTypes.isEmpty) {
      return null;
    }
    final clauses = documentTypes.map((type) => 'DOCTYPE(${type.toUpperCase()})').join(' OR ');
    return '($clauses)';
  }
}
