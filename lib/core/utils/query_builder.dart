class QueryBuilder {
  const QueryBuilder._();

  static String buildScopusQuery(List<List<String>> groups) {
    final normalized = _normalize(groups);
    if (normalized.isEmpty) {
      return '';
    }
    final clauses = normalized
        .map((group) => group.map((keyword) => _tokenize(keyword, uppercase: true)).join(' OR '))
        .map((clause) => '($clause)')
        .join(' AND ');
    return 'TITLE-ABS-KEY(($clauses))';
  }

  static String buildCrossrefQuery(List<List<String>> groups) {
    final normalized = _normalize(groups);
    if (normalized.isEmpty) {
      return '';
    }
    return normalized
        .map(
          (group) => '(${group.map((keyword) => _tokenize(keyword, uppercase: true)).join(' OR ')})',
        )
        .join(' AND ');
  }

  static String buildOpenAlexQuery(List<List<String>> groups) {
    final normalized = _normalize(groups);
    if (normalized.isEmpty) {
      return '';
    }
    final clauses = normalized
        .map(
          (group) => '(${group.map((keyword) => _tokenize(keyword, uppercase: false)).join(' OR ')})',
        )
        .join(' AND ');
    return clauses;
  }

  static List<List<String>> _normalize(List<List<String>> groups) {
    return groups
        .map((group) => group.where((kw) => kw.trim().isNotEmpty).toList())
        .where((group) => group.isNotEmpty)
        .toList();
  }

  static String _tokenize(String keyword, {required bool uppercase}) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final escaped = trimmed.replaceAll('"', '\\"');
    final token = uppercase ? escaped.toUpperCase() : escaped;
    if (token.contains(' ')) {
      return '"$token"';
    }
    return token;
  }
}
