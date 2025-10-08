import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/in_memory_article_cache.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/domain/repositories/article_repository.dart' as repository;
import '../../../keyword_config/domain/entities/search_filter_entity.dart';

class FetchArticlesUseCase {
  FetchArticlesUseCase(
    repository.ArticleRepository repository,
    this._cache,
  ) : _repository = repository;

  final repository.ArticleRepository _repository;
  final InMemoryArticleCache _cache;

  Future<ApiResult<List<ArticleEntity>>> fetchAllToCache(
    SearchFilterEntity filter,
    void Function(repository.FetchProgress progress) onProgress,
  ) async {
    _cache.clear();
    final result = await _repository.ingestAll(filter, onProgress);
    if (result.isSuccess && result.data != null) {
      _cache.addAll(result.data!);
    }
    return result;
  }

  InMemoryArticleCache get cache => _cache;
}
