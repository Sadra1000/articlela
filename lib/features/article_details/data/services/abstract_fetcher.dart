import 'package:dio/dio.dart';

import '../../../../core/data/services/dio_client.dart';
import 'openalex_abstract_parser.dart';

class AbstractResult {
  const AbstractResult({
    required this.doi,
    required this.resolutionSource,
    this.title,
    this.abstractText,
    this.year,
    this.venue,
    this.authors = const [],
  });

  final String doi;
  final String? title;
  final String? abstractText;
  final int? year;
  final String? venue;
  final List<String> authors;
  final String resolutionSource;
}

abstract class IAbstractFetcher {
  Future<AbstractResult> fetchByDoi(String doi);
}

class AbstractFetcher implements IAbstractFetcher {
  AbstractFetcher(this._client);

  final DioClient _client;

  @override
  Future<AbstractResult> fetchByDoi(String doi) async {
    final normalizedDoi = _normalizeDoi(doi);

    final semantic = await _fetchSemanticScholar(normalizedDoi);
    if (semantic != null) return semantic;

    final openAlex = await _fetchOpenAlex(normalizedDoi);
    if (openAlex != null) return openAlex;

    final crossref = await _fetchCrossref(normalizedDoi);
    if (crossref != null) return crossref;

    return AbstractResult(
      doi: normalizedDoi,
      resolutionSource: 'NONE',
      authors: const [],
    );
  }

  Future<AbstractResult?> _fetchSemanticScholar(String doi) async {
    final url = 'https://api.semanticscholar.org/graph/v1/paper/DOI:$doi';
    try {
      final response = await _client.get(
        url,
        queryParameters: const {
          'fields': 'title,abstract,year,venue,authors',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final abstract = data['abstract'] as String?;
      if (abstract == null || abstract.isEmpty) {
        return null;
      }
      final authors = ((data['authors'] as List<dynamic>?) ?? [])
          .map((author) => (author as Map<String, dynamic>)['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      return AbstractResult(
        doi: doi,
        resolutionSource: 'SEMANTIC_SCHOLAR',
        title: data['title'] as String?,
        abstractText: abstract.trim(),
        year: data['year'] as int?,
        venue: data['venue'] as String?,
        authors: authors,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  Future<AbstractResult?> _fetchOpenAlex(String doi) async {
    final url = 'https://api.openalex.org/works/https://doi.org/$doi';
    try {
      final response = await _client.get(
        url,
        queryParameters: const {
          'select': 'title,abstract_inverted_index,publication_year,host_venue,authorships',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final abstractIndex = data['abstract_inverted_index'] as Map<String, dynamic>?;
      if (abstractIndex == null || abstractIndex.isEmpty) {
        return null;
      }
      final abstract = OpenAlexAbstractParser.toPlainText(abstractIndex);
      if (abstract.isEmpty) {
        return null;
      }
      final hostVenue = data['host_venue'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final authorships = (data['authorships'] as List<dynamic>? ?? [])
          .map((entry) => (entry as Map<String, dynamic>)['author'] as Map<String, dynamic>? ?? {})
          .map((author) => author['display_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      return AbstractResult(
        doi: doi,
        resolutionSource: 'OPENALEX',
        title: data['title'] as String?,
        abstractText: abstract,
        year: data['publication_year'] as int?,
        venue: hostVenue['display_name'] as String?,
        authors: authorships,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  Future<AbstractResult?> _fetchCrossref(String doi) async {
    final url = 'https://api.crossref.org/works';
    try {
      final response = await _client.get(
        url,
        queryParameters: {
          'filter': 'doi:$doi',
          'select': 'title,abstract,issued,author',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final message = data['message'] as Map<String, dynamic>?;
      final items = (message?['items'] as List<dynamic>? ?? <dynamic>[]);
      if (items.isEmpty) {
        return null;
      }
      final first = items.first as Map<String, dynamic>;
      final abstractRaw = first['abstract'] as String?;
      if (abstractRaw == null || abstractRaw.isEmpty) {
        return null;
      }
      final abstract = _sanitizeAbstract(abstractRaw);
      final issued = first['issued'] as Map<String, dynamic>?;
      final dateParts = issued?['date-parts'] as List<dynamic>?;
      final year = (dateParts != null && dateParts.isNotEmpty)
          ? (dateParts.first as List<dynamic>? ?? <dynamic>[]).first as int?
          : null;
      final authors = (first['author'] as List<dynamic>? ?? [])
          .map((author) {
            final map = author as Map<String, dynamic>;
            final given = (map['given'] as String?) ?? '';
            final family = (map['family'] as String?) ?? '';
            return '$given $family'.trim();
          })
          .where((name) => name.isNotEmpty)
          .toList();

      final titles = first['title'] as List<dynamic>? ?? [];
      final title = titles.isNotEmpty ? titles.first as String : null;

      return AbstractResult(
        doi: doi,
        resolutionSource: 'CROSSREF',
        title: title,
        abstractText: abstract,
        year: year,
        venue: null,
        authors: authors,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  String _normalizeDoi(String doi) {
    final value = doi.trim();
    if (value.startsWith('http://doi.org/')) {
      return value.substring('http://doi.org/'.length);
    }
    if (value.startsWith('https://doi.org/')) {
      return value.substring('https://doi.org/'.length);
    }
    return value;
  }

  String _sanitizeAbstract(String input) {
    final unescaped = input
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
    final stripped = unescaped.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
