import '../../data/models/api_result.dart';
import '../entities/article_entity.dart';
import '../../../features/keyword_config/domain/entities/search_filter_entity.dart';

class FetchProgress {
  const FetchProgress({
    required this.source,
    required this.fetchedPages,
    required this.fetchedItems,
    required this.done,
  });

  final DataSource source;
  final int fetchedPages;
  final int fetchedItems;
  final bool done;
}

abstract class ArticleRepository {
  Future<ApiResult<List<ArticleEntity>>> ingestAll(
    SearchFilterEntity filter,
    void Function(FetchProgress progress) onProgress,
  );
}
