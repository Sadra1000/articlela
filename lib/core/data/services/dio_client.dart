import 'package:dio/dio.dart';

import 'env_config.dart';

class DioClient {
  DioClient(this._dio, this._envConfig) {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final uri = options.uri.toString();
          if (uri.contains('elsevier.com')) {
            final apiKey = _envConfig.elsevierApiKey;
            if (apiKey != null && apiKey.isNotEmpty) {
              options.headers['X-ELS-APIKey'] = apiKey;
            }
          }

          if (uri.contains('crossref.org')) {
            final mailto = _envConfig.crossrefMailto;
            if (mailto != null && mailto.isNotEmpty) {
              options.queryParameters.putIfAbsent('mailto', () => mailto);
              final userAgent = 'ArticleLA/1.0 (mailto:$mailto)';
              options.headers['User-Agent'] = userAgent;
            }
          } else {
            options.headers.remove('User-Agent');
          }

          options.headers.putIfAbsent('User-Agent', () => 'ArticleLA/1.0');
          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final EnvConfig _envConfig;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }
}
