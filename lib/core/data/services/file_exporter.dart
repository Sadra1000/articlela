import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/article_entity.dart';
import '../models/api_result.dart';

class FileExporter {
  Future<ApiResult<String>> exportArticlesCsv(List<ArticleEntity> items) async {
    try {
      if (items.isEmpty) {
        return ApiResult.failure('No items to export');
      }

      Directory? targetDir;

      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {
        targetDir = null;
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'articles_$timestamp.csv';

      final file = File('${targetDir.path}${Platform.pathSeparator}$filename');
      final sink = file.openWrite();
      const bom = [0xEF, 0xBB, 0xBF];
      sink.add(bom);

      sink.writeln('title,year,doi,document_type,source,abstract');

      for (final article in items) {
        final row = [
          _escape(article.title),
          _escape(article.publishedYear?.toString() ?? ''),
          _escape(article.doi ?? ''),
          _escape(article.documentType),
          _escape(article.source),
          _escape(article.abstractText?.replaceAll(RegExp(r'\s+'), ' ') ?? ''),
        ].join(',');
        sink.writeln(row);
      }

      await sink.flush();
      await sink.close();

      return ApiResult.success(file.path);
    } catch (error) {
      return ApiResult.failure(error.toString());
    }
  }

  static String _escape(String input) {
    final sanitized = input.replaceAll('"', '""');
    if (sanitized.contains(',') || sanitized.contains('\n')) {
      return '"$sanitized"';
    }
    return sanitized;
  }
}
