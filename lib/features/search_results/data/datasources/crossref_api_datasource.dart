import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/dio_client.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/utils/query_builder.dart';

class CrossrefResponse {
  const CrossrefResponse({
    required this.articles,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<ArticleEntity> articles;
  final String? nextCursor;
  final bool hasMore;
}

class CrossrefApiDatasource {
  CrossrefApiDatasource(this._client);

  final DioClient _client;

  Future<ApiResult<CrossrefResponse>> searchCrossref({
    required List<List<String>> groups,
    required int fromYear,
    required int toYear,
    required List<String> documentTypes,
    String? cursor,
  }) async {
    try {
      final query = QueryBuilder.buildCrossrefQuery(groups);
      final filters = <String>[
        'from-pub-date:$fromYear-01-01',
        'until-pub-date:$toYear-12-31',
        'has-abstract:true',
      ];

      filters.addAll(
        documentTypes.map((type) => 'type:$type'),
      );

      final params = <String, dynamic>{
        'query': query,
        'rows': AppConstants.crossrefPageSize,
        'cursor': cursor ?? '*',
        'sort': 'score',
        'order': 'desc',
        'select': 'title,DOI,issued,type,link',
        'filter': filters.join(','),
      };

      final response = await _client.get(
        '${AppConstants.crossrefBaseUrl}/works',
        queryParameters: params,
      );

      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as Map<String, dynamic>;
      final items = (message['items'] as List<dynamic>).cast<Map<String, dynamic>>();
      final results = <ArticleEntity>[];

      for (final item in items) {
        final titleList = item['title'] as List<dynamic>?;
        final title = (titleList != null && titleList.isNotEmpty) ? titleList.first as String : 'Untitled';

        final issued = item['issued'] as Map<String, dynamic>?;
        final dateParts = issued != null ? issued['date-parts'] as List<dynamic>? : null;
        final year = (dateParts != null && dateParts.isNotEmpty && (dateParts.first as List<dynamic>).isNotEmpty)
            ? (dateParts.first as List<dynamic>).first as int
            : null;

        final doi = item['DOI'] as String?;
        final type = item['type'] as String? ?? 'other';
        final linkList = item['link'] as List<dynamic>?;
        final link = linkList != null && linkList.isNotEmpty
            ? (linkList.first as Map<String, dynamic>)['URL'] as String?
            : item['URL'] as String?;

        results.add(
          ArticleEntity(
            title: title,
            publishedYear: year,
            doi: doi,
            abstractText: null,
            documentType: type,
            source: 'CROSSREF',
            link: link,
          ),
        );
      }

      final nextCursor = message['next-cursor'] as String?;
      final totalResults = message['total-results'] as int? ?? results.length;
      final hasMore = nextCursor != null && results.isNotEmpty && totalResults > results.length;

      return ApiResult.success(
        CrossrefResponse(
          articles: results,
          nextCursor: nextCursor,
          hasMore: hasMore,
        ),
      );
    } on DioException catch (error) {
      return ApiResult.failure(error.message ?? 'Crossref request failed');
    } catch (error) {
      return ApiResult.failure(error.toString());
    }
  }
}
