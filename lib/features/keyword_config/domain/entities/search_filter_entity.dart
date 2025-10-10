import 'keyword_group_entity.dart';

enum DataSource { crossref, scopus, openalex }

class SearchFilterEntity {
  const SearchFilterEntity({
    required this.groups,
    required this.fromYear,
    required this.toYear,
    required this.documentTypes,
    required this.sources,
  });

  final List<KeywordGroupEntity> groups;
  final int fromYear;
  final int toYear;
  final List<String> documentTypes;
  final Set<DataSource> sources;

  List<List<String>> get keywordMatrix => groups.map((group) => group.keywords).toList();

  bool includesSource(DataSource source) => sources.contains(source);
}

class DocumentTypeMapper {
  static const Map<String, String> _crossref = {
    'journal_article': 'journal-article',
    'book': 'book',
    'conference': 'proceedings-article',
    'report': 'report',
    'thesis': 'dissertation',
    'other': 'other',
  };

  static const Map<String, String> _scopus = {
    'journal_article': 'ar',
    'review': 're',
    'book': 'bk',
    'conference': 'cp',
    'report': 'rp',
    'thesis': 'dp',
    'other': 'no',
  };

  static const Map<String, String> _openAlex = {
    'journal_article': 'article',
    'book': 'book',
    'conference': 'proceedings-article',
    'report': 'report',
    'thesis': 'dissertation',
    'other': 'other',
  };

  static List<String> crossrefCodes(List<String> ids) {
    return ids.map((id) => _crossref[id]).whereType<String>().toList();
  }

  static List<String> scopusCodes(List<String> ids) {
    return ids.map((id) => _scopus[id]).whereType<String>().toList();
  }

  static List<String> openAlexCodes(List<String> ids) {
    
    print(ids);
    return ids.map((id) => _openAlex[id]).whereType<String>().toList();
  }
}
