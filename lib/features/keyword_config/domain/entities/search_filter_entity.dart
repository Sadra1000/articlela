import 'keyword_group_entity.dart';

class SearchFilterEntity {
  const SearchFilterEntity({
    required this.groups,
    required this.fromYear,
    required this.toYear,
    required this.documentTypes,
  });

  final List<KeywordGroupEntity> groups;
  final int fromYear;
  final int toYear;
  final List<String> documentTypes;

  List<List<String>> get keywordMatrix => groups.map((group) => group.keywords).toList();
}

class DocumentTypeMapper {
  static const Map<String, String> _crossref = {
    'journal_article': 'journal-article',
    'review': 'review',
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

  static List<String> crossrefCodes(List<String> ids) {
    return ids.map((id) => _crossref[id]).whereType<String>().toList();
  }

  static List<String> scopusCodes(List<String> ids) {
    return ids.map((id) => _scopus[id]).whereType<String>().toList();
  }
}
