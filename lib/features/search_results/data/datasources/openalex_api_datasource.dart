import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/dio_client.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/utils/query_builder.dart';

class OpenAlexResponse {
  const OpenAlexResponse({
    required this.articles,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<ArticleEntity> articles;
  final String? nextCursor;
  final bool hasMore;
}

class OpenAlexApiDatasource {
  OpenAlexApiDatasource(this._client);

  final DioClient _client;

  Future<ApiResult<OpenAlexResponse>> searchOpenAlex({
    required List<List<String>> groups,
    required int fromYear,
    required int toYear,
    required List<String> documentTypes,
    String? cursor,
  }) async {
    try {
      final searchClause = QueryBuilder.buildOpenAlexQuery(groups);
      final filters = <String>[
        'from_publication_date:$fromYear-01-01',
        'to_publication_date:$toYear-12-31',
        'has_doi:true',
        'type:${documentTypes.join('|')}',
      ];

      final params = <String, dynamic>{
        'search': searchClause.isEmpty ? null : searchClause,
        'filter': filters.join(','),
        'per-page': 200,
        'cursor': cursor ?? '*',
        'select': 'title,doi,publication_year,type,primary_location',
      }..removeWhere((_, value) => value == null);

      final response = await _client.get(
        '${AppConstants.openAlexBaseUrl}/works',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final articles = results
          .map(_mapArticle)
          .where((article) => article.doi != null && article.doi!.isNotEmpty)
          .toList();

      final meta = data['meta'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final nextCursor = meta['next_cursor'] as String?;
      final hasMore = nextCursor != null;

      return ApiResult.success(
        OpenAlexResponse(
          articles: articles,
          nextCursor: nextCursor,
          hasMore: hasMore,
        ),
      );
    } on DioException catch (error) {
      return ApiResult.failure(error.message ?? 'OpenAlex request failed');
    } catch (error) {
      return ApiResult.failure(error.toString());
    }
  }

  ArticleEntity _mapArticle(Map<String, dynamic> json) {
    final rawDoi = json['doi'] as String?;
    final normalizedDoi = _normalizeDoi(rawDoi);
    final hostVenue =
        json['host_venue'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final primary =
        json['primary_location'] as Map<String, dynamic>? ??
        <String, dynamic>{};

    final primarySource = primary['source'] as Map<String, dynamic>?;
    final link =
        primary['landing_page_url'] as String? ??
        primarySource?['url'] as String? ??
        hostVenue['url'] as String?;

    final type = (json['type'] as String?) ?? 'other';

    return ArticleEntity(
      title: (json['title'] as String?)?.trim() ?? 'Untitled',
      publishedYear: json['publication_year'] as int?,
      doi: normalizedDoi,
      abstractText: null,
      documentType: type,
      source: 'OPENALEX',
      link: link,
    );
  }

  String? _normalizeDoi(String? doi) {
    if (doi == null || doi.isEmpty) {
      return null;
    }
    final lower = doi.toLowerCase();
    if (lower.startsWith('https://doi.org/')) {
      return doi.substring('https://doi.org/'.length);
    }
    if (lower.startsWith('http://doi.org/')) {
      return doi.substring('http://doi.org/'.length);
    }
    return doi;
  }
}
