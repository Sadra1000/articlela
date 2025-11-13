import 'package:dio/dio.dart';

import 'dio_client.dart';
import 'env_config.dart';

class DeepSeekService {
  DeepSeekService(this._client, this._envConfig);

  final DioClient _client;
  final EnvConfig _envConfig;

  static const String _endpoint = 'https://api.deepseek.com/chat/completions';
  static const String defaultModel = 'deepseek-chat';

  Future<DeepSeekChatCompletion> createChatCompletion(
    DeepSeekChatCompletionRequest request,
  ) async {
    final apiKey = _envConfig.deepSeekApiKey;
    if (apiKey == null) {
      throw const DeepSeekException(
        'Missing DEEPSEEK_API_KEY. Please add it to assets/.env and restart the app.',
      );
    }

    try {
      final response = await _client.post(
        _endpoint,
        data: request.toJson(),
        headers: <String, String>{
          'Authorization': 'Bearer $apiKey',
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return DeepSeekChatCompletion.fromJson(data);
      }

      throw const DeepSeekException('Unexpected DeepSeek response format.');
    } on DioException catch (error) {
      throw DeepSeekException.fromDio(error);
    }
  }
}

class DeepSeekChatCompletionRequest {
  const DeepSeekChatCompletionRequest({
    required this.messages,
    this.model = DeepSeekService.defaultModel,
    this.temperature,
    this.maxTokens,
    this.topP,
    this.stream = false,
  });

  final List<DeepSeekMessage> messages;
  final String model;
  final double? temperature;
  final int? maxTokens;
  final double? topP;
  final bool stream;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'model': model,
      'messages': messages.map((message) => message.toJson()).toList(),
      'stream': stream,
    };

    if (temperature != null) {
      payload['temperature'] = temperature;
    }
    if (maxTokens != null) {
      payload['max_tokens'] = maxTokens;
    }
    if (topP != null) {
      payload['top_p'] = topP;
    }
    return payload;
  }
}

class DeepSeekChatCompletion {
  const DeepSeekChatCompletion({
    required this.id,
    required this.model,
    required this.createdAt,
    required this.choices,
    this.systemFingerprint,
    this.usage,
  });

  final String id;
  final String model;
  final int createdAt;
  final List<DeepSeekChoice> choices;
  final String? systemFingerprint;
  final DeepSeekUsage? usage;

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
      id: (json['id'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      createdAt: (json['created'] as int?) ?? 0,
      systemFingerprint: json['system_fingerprint'] as String?,
      usage: json['usage'] is Map<String, dynamic>
          ? DeepSeekUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
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

class DeepSeekUsage {
  const DeepSeekUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  factory DeepSeekUsage.fromJson(Map<String, dynamic> json) {
    return DeepSeekUsage(
      promptTokens: (json['prompt_tokens'] as int?) ?? 0,
      completionTokens: (json['completion_tokens'] as int?) ?? 0,
      totalTokens: (json['total_tokens'] as int?) ?? 0,
    );
  }
}

class DeepSeekException implements Exception {
  const DeepSeekException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory DeepSeekException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorData = data['error'];
      if (errorData is Map<String, dynamic>) {
        final message = (errorData['message'] as String?)?.trim();
        final type = (errorData['type'] as String?)?.trim();
        final code = (errorData['code'] as String?)?.trim();
        final buffer = StringBuffer();
        if (message != null && message.isNotEmpty) {
          buffer.write(message);
        }
        if (type != null && type.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' • ');
          buffer.write(type);
        }
        if (code != null && code.isNotEmpty) {
          if (buffer.isNotEmpty) buffer.write(' • ');
          buffer.write(code);
        }
        if (buffer.isNotEmpty) {
          return DeepSeekException(
            buffer.toString(),
            statusCode: statusCode,
          );
        }
      }
    }
    final fallback = error.message ?? 'Failed to call DeepSeek API';
    return DeepSeekException(fallback, statusCode: statusCode);
  }

  @override
  String toString() {
    if (statusCode == null) {
      return 'DeepSeekException: $message';
    }
    return 'DeepSeekException($statusCode): $message';
  }
}
