import '../../../../core/data/models/api_result.dart';
import '../../../../core/data/services/file_exporter.dart';
import '../../../../core/domain/entities/article_entity.dart';

class ExportArticlesUseCase {
  ExportArticlesUseCase(this._exporter);

  final FileExporter _exporter;

  Future<ApiResult<String>> call(List<ArticleEntity> articles) {
    return _exporter.exportArticlesCsv(articles);
  }
}
