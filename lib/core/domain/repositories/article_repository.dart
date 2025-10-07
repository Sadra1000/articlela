import '../../data/models/api_result.dart';
import '../entities/article_entity.dart';
import '../../../features/keyword_config/domain/entities/search_filter_entity.dart';

abstract class ArticleRepository {
  Future<ApiResult<ArticlePage>> fetchArticles(
    SearchFilterEntity filter, {
    String? crossrefCursor,
    int? scopusStart,
  });
}
