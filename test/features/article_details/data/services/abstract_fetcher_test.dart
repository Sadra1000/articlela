import 'package:articlela/core/data/services/dio_client.dart';
import 'package:articlela/core/data/services/key_store.dart';
import 'package:articlela/features/article_details/data/services/abstract_fetcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeKeyStore implements KeyStore {
  @override
  Future<void> markOnboardingCompleted() async {}
  @override
  Future<bool> isOnboardingCompleted() async => true;
  @override
  Future<void> resetOnboarding() async {}
  @override
  Future<void> saveElsevierKey(String key, {bool scopusEnabled = true}) async {}
  @override
  Future<String?> getElsevierKey() async => null;
  @override
  Future<void> saveCrossrefMailto(String email) async {}
  @override
  Future<String?> getCrossrefMailto() async => null;
  @override
  Future<bool> isKeysConfigured() async => true;
  @override
  Future<void> setScopusEnabled(bool enabled) async {}
  @override
  Future<bool> isScopusEnabled() async => false;
}

typedef ResponseHandler = Future<Response<dynamic>> Function(
  String path,
  Map<String, dynamic>? queryParameters,
);

class _StubDioClient extends DioClient {
  _StubDioClient(this._handler) : super(Dio(), _FakeKeyStore());

  final ResponseHandler _handler;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return _handler(path, queryParameters);
  }
}

Response<dynamic> _response(String path, dynamic data, {int statusCode = 200}) {
  return Response<dynamic>(
    data: data,
    statusCode: statusCode,
    requestOptions: RequestOptions(path: path, queryParameters: const {}),
  );
}

DioException _notFound(String path) {
  final request = RequestOptions(path: path);
  return DioException(
    requestOptions: request,
    response: Response<dynamic>(requestOptions: request, statusCode: 404),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  test('prefers Semantic Scholar when available', () async {
    var semanticCalls = 0;
    var openAlexCalls = 0;
    final client = _StubDioClient((path, _) async {
      if (path.contains('semanticscholar')) {
        semanticCalls += 1;
        return _response(path, {
          'title': 'Sample Paper',
          'abstract': 'This is an abstract from Semantic Scholar.',
          'year': 2024,
          'venue': 'Test Venue',
          'authors': [
            {'name': 'Ada Lovelace'},
            {'name': 'Alan Turing'},
          ],
        });
      }
      if (path.contains('openalex')) {
        openAlexCalls += 1;
        throw _notFound(path);
      }
      throw _notFound(path);
    });

    final fetcher = AbstractFetcher(client);
    final result = await fetcher.fetchByDoi('10.1000/xyz');
    expect(result.resolutionSource, 'SEMANTIC_SCHOLAR');
    expect(result.abstractText, 'This is an abstract from Semantic Scholar.');
    expect(result.authors, containsAll(['Ada Lovelace', 'Alan Turing']));
    expect(semanticCalls, 1);
    expect(openAlexCalls, 0);
  });

  test('falls back to OpenAlex when Semantic Scholar unavailable', () async {
    final client = _StubDioClient((path, _) async {
      if (path.contains('semanticscholar')) {
        throw _notFound(path);
      }
      if (path.contains('openalex')) {
        return _response(path, {
          'title': 'OpenAlex Paper',
          'abstract_inverted_index': {
            'OpenAI': [0],
            'advances': [1],
            'research.': [2],
          },
          'publication_year': 2023,
          'host_venue': {'display_name': 'OpenAI Journal'},
          'authorships': [
            {
              'author': {'display_name': 'Grace Hopper'}
            }
          ],
        });
      }
      throw _notFound(path);
    });

    final fetcher = AbstractFetcher(client);
    final result = await fetcher.fetchByDoi('10.1000/openalex');
    expect(result.resolutionSource, 'OPENALEX');
    expect(result.abstractText, 'OpenAI advances research.');
    expect(result.authors, ['Grace Hopper']);
    expect(result.venue, 'OpenAI Journal');
  });

  test('falls back to Crossref last', () async {
    final client = _StubDioClient((path, _) async {
      if (path.contains('semanticscholar') || path.contains('openalex')) {
        throw _notFound(path);
      }
      if (path.contains('crossref')) {
        return _response(path, {
          'message': {
            'items': [
              {
                'title': ['Crossref Paper'],
                'abstract': '<jats:p>Crossref abstract content.</jats:p>',
                'issued': {
                  'date-parts': [
                    [2022]
                  ]
                },
                'author': [
                  {'given': 'Tim', 'family': 'Berners-Lee'}
                ],
              }
            ],
          },
        });
      }
      throw _notFound(path);
    });

    final fetcher = AbstractFetcher(client);
    final result = await fetcher.fetchByDoi('10.1000/crossref');
    expect(result.resolutionSource, 'CROSSREF');
    expect(result.abstractText, 'Crossref abstract content.');
    expect(result.authors, ['Tim Berners-Lee']);
    expect(result.year, 2022);
  });
}
