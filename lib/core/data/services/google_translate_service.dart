import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';
import 'deepseek_service.dart';
import 'dio_client.dart';

enum TranslationProvider { google, deepseek }

const TranslationProvider kDefaultTranslationProvider = TranslationProvider.deepseek;

TranslationProvider translationProviderFromName(String? raw) {
  if (raw == null) {
    return kDefaultTranslationProvider;
  }
  return TranslationProvider.values.firstWhere(
    (value) => value.name == raw,
    orElse: () => kDefaultTranslationProvider,
  );
}

abstract class ArticleTranslator {
  Future<String> translate({
    required String text,
  });
}

class ConfigurableArticleTranslator implements ArticleTranslator {
  ConfigurableArticleTranslator({
    required SharedPreferences preferences,
    required GoogleTranslateService googleService,
    required DeepSeekTranslateService deepSeekService,
  })  : _preferences = preferences,
        _googleService = googleService,
        _deepSeekService = deepSeekService;

  final SharedPreferences _preferences;
  final GoogleTranslateService _googleService;
  final DeepSeekTranslateService _deepSeekService;

  TranslationProvider get _currentProvider {
    final stored = _preferences.getString(AppConstants.translationProviderKey);
    return translationProviderFromName(stored);
  }

  @override
  Future<String> translate({required String text}) {
    switch (_currentProvider) {
      case TranslationProvider.google:
        return _googleService.translate(text: text);
      case TranslationProvider.deepseek:
        return _deepSeekService.translate(text: text);
    }
  }
}

class GoogleTranslateService implements ArticleTranslator {
  GoogleTranslateService(this._client);

  final DioClient _client;

  @override
  Future<String> translate({
    required String text,
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
          'sl': "en",
          'tl': "fa",
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
class DeepSeekTranslateService implements ArticleTranslator {
  DeepSeekTranslateService(this._deepSeekService);

  final DeepSeekService _deepSeekService;

  @override
  Future<String> translate({
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text cannot be empty');
    }

    try {
      final response = await _deepSeekService.createChatCompletion(
        messages: <DeepSeekMessage>[
          const DeepSeekMessage(
            role: 'system',
            content:
                'You are a professional translator that rewrites academic content from English to Persian while preserving meaning, tone, and inline formatting.',
          ),
          DeepSeekMessage(
            role: 'user',
            content:
                'Translate the following text to Persian. Respond only with the translated text:\n\n$trimmed',
          ),
        ],
      );

      final translated = response.firstMessageContent;
      if (translated == null || translated.isEmpty) {
        throw const FormatException('Unexpected DeepSeek translation response shape');
      }

      return translated;
    } on FormatException {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (error) {
      throw Exception(error.toString());
    }
  }
}
