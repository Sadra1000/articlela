import 'package:dio/dio.dart';

import 'key_store.dart';

class DioClient {
  DioClient(this._dio, this._keyStore) {
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
        onRequest: (options, handler) async {
          final host = options.uri.host;
          final path = options.uri.toString();

          if (host.contains('elsevier.com')) {
            final scopusEnabled = await _keyStore.isScopusEnabled();
            if (scopusEnabled) {
              final apiKey = await _keyStore.getElsevierKey();
              if (apiKey != null && apiKey.isNotEmpty) {
                options.headers['X-ELS-APIKey'] = apiKey;
              }
            }
          }

          if (host.contains('crossref.org')) {
            final mailto = await _keyStore.getCrossrefMailto();
            if (mailto != null && mailto.isNotEmpty) {
              options.queryParameters.putIfAbsent('mailto', () => mailto);
              options.headers['User-Agent'] = 'ArticleLA/1.0 (mailto:$mailto)';
            } else {
              options.headers['User-Agent'] = 'ArticleLA/1.0';
            }
          } else if (!options.headers.containsKey('User-Agent')) {
            options.headers['User-Agent'] = 'ArticleLA/1.0';
          }

          if (path.contains('openalex.org')) {
            options.headers['Accept'] = 'application/json';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final KeyStore _keyStore;

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
