import 'package:articlela/core/data/models/api_result.dart';
import 'package:articlela/core/data/services/file_exporter.dart';
import 'package:articlela/core/domain/entities/article_entity.dart';

class RecordingExporter extends FileExporter {
  List<ArticleEntity>? lastExport;
  bool shouldFail = false;

  @override
  Future<ApiResult<String>> exportArticlesCsv(List<ArticleEntity> items) async {
    lastExport = List<ArticleEntity>.from(items);
    if (shouldFail) {
      return ApiResult.failure('fail');
    }
    return ApiResult.success('path');
  }
}
