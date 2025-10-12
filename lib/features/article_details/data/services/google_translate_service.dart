import 'package:dio/dio.dart';

import '../../../../core/data/services/dio_client.dart';

abstract class ArticleTranslator {
  Future<String> translate({
    required String text,
    String sourceLanguage = 'en',
    String targetLanguage = 'fa',
  });
}

class GoogleTranslateService implements ArticleTranslator {
  GoogleTranslateService(this._client);

  final DioClient _client;

  @override
  Future<String> translate({
    required String text,
    String sourceLanguage = 'en',
    String targetLanguage = 'fa',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text cannot be empty');
    }

    try {
      final response = await _client.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: <String, dynamic>{
          'client': 'gtx',
          'sl': sourceLanguage,
          'tl': targetLanguage,
          'dt': 't',
          'q': trimmed,
        },
      );

      final data = response.data;
      if (data is List && data.isNotEmpty) {
        final segments = data.first;
        if (segments is List && segments.isNotEmpty) {
          final buffer = StringBuffer();
          for (final segment in segments) {
            if (segment is List && segment.isNotEmpty) {
              final part = segment.first;
              if (part is String) {
                buffer.write(part);
              }
            }
          }

          final result = buffer.toString().trim();
          if (result.isNotEmpty) {
            return result;
          }
        }
      }

      throw const FormatException('Unexpected translation response shape');
    } on DioException catch (error) {
      final message = error.message ?? 'Failed to translate text';
      throw Exception(message);
    } on FormatException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
