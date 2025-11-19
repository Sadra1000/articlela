import 'deepseek_service.dart';

abstract class ArticleExplainer {
  Future<String> explain({required String text});
}

class DeepSeekArticleExplainer implements ArticleExplainer {
  DeepSeekArticleExplainer(this._deepSeekService);

  final DeepSeekService _deepSeekService;

  @override
  Future<String> explain({required String text}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('text cannot be empty');
    }

    final response = await _deepSeekService.createChatCompletion(
      DeepSeekChatCompletionRequest(
        messages: <DeepSeekMessage>[
          const DeepSeekMessage(
            role: 'system',
            content:
                'You are an expert academic writing assistant who explains English research text in fluent Persian while keeping technical terms in English.',
          ),
          DeepSeekMessage(
            role: 'user',
            content:
                'Explain the following excerpt for a graduate researcher. Include one concise summary paragraph in Persian followed by up to three bullet highlights. Do not add extra sections.\n\n$trimmed',
          ),
        ],
        temperature: 0.35,
      ),
    );

    final explanation = response.firstMessageContent;
    if (explanation == null || explanation.trim().isEmpty) {
      throw const FormatException(
        'Unexpected DeepSeek explanation response shape',
      );
    }

    return explanation.trim();
  }
}
