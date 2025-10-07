import '../../../../core/data/models/api_result.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/domain/repositories/article_repository.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';

class FetchArticlesUseCase {
  FetchArticlesUseCase(this._repository);

  final ArticleRepository _repository;

  Future<ApiResult<ArticlePage>> call(
    SearchFilterEntity filter, {
    String? crossrefCursor,
    int? scopusStart,
  }) {
    return _repository.fetchArticles(
      filter,
      crossrefCursor: crossrefCursor,
      scopusStart: scopusStart,
    );
  }
}
