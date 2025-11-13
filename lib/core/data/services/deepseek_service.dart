import 'package:dio/dio.dart';

import 'dio_client.dart';
import 'env_config.dart';

class DeepSeekService {
  DeepSeekService(this._client, this._envConfig);

  final DioClient _client;
  final EnvConfig _envConfig;

  static const _endpoint = 'https://api.deepseek.com/chat/completions';
  static const defaultModel = 'deepseek-chat';

  Future<DeepSeekChatCompletion> createChatCompletion({
    required List<DeepSeekMessage> messages,
    String model = defaultModel,
    bool stream = false,
    double? temperature,
  }) async {
    final apiKey = _envConfig.deepSeekApiKey;
    if (apiKey == null) {
      throw StateError(
        'DEEPSEEK_API_KEY is missing. Please add it to assets/.env before using DeepSeek API features.',
      );
    }

    final payload = <String, dynamic>{
      'model': model,
      'messages': messages.map((message) => message.toJson()).toList(),
      'stream': stream,
    };

    if (temperature != null) {
      payload['temperature'] = temperature;
    }

    try {
      final response = await _client.post(
        _endpoint,
        data: payload,
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DeepSeekChatCompletion.fromJson(data);
      }

      throw const FormatException('Unexpected DeepSeek response structure');
    } on DioException catch (error) {
      final message = error.message ?? 'Failed to call DeepSeek API';
      throw Exception(message);
    }
  }
}

class DeepSeekChatCompletion {
  const DeepSeekChatCompletion({
    this.id,
    this.model,
    this.createdAt,
    required this.choices,
  });

  final String? id;
  final String? model;
  final int? createdAt;
  final List<DeepSeekChoice> choices;

  factory DeepSeekChatCompletion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    final parsedChoices = <DeepSeekChoice>[];
    if (rawChoices is List) {
      for (final choice in rawChoices) {
        if (choice is Map<String, dynamic>) {
          parsedChoices.add(DeepSeekChoice.fromJson(choice));
        }
      }
    }

    return DeepSeekChatCompletion(
      id: json['id'] as String?,
      model: json['model'] as String?,
      createdAt: json['created'] as int?,
      choices: parsedChoices,
    );
  }

  String? get firstMessageContent {
    if (choices.isEmpty) {
      return null;
    }
    final message = choices.first.message;
    final content = message?.content.trim();
    if (content == null || content.isEmpty) {
      return null;
    }
    return content;
  }
}

class DeepSeekChoice {
  const DeepSeekChoice({
    this.index,
    this.message,
    this.finishReason,
  });

  final int? index;
  final DeepSeekMessage? message;
  final String? finishReason;

  factory DeepSeekChoice.fromJson(Map<String, dynamic> json) {
    final rawMessage = json['message'];
    return DeepSeekChoice(
      index: json['index'] as int?,
      finishReason: json['finish_reason'] as String?,
      message: rawMessage is Map<String, dynamic>
          ? DeepSeekMessage.fromJson(rawMessage)
          : null,
    );
  }
}

class DeepSeekMessage {
  const DeepSeekMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  factory DeepSeekMessage.fromJson(Map<String, dynamic> json) {
    return DeepSeekMessage(
      role: (json['role'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
    );
  }

  Map<String, String> toJson() {
    return <String, String>{
      'role': role,
      'content': content,
    };
  }
}
