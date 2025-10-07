class QueryBuilder {
  const QueryBuilder._();

  static String buildScopusQuery(List<List<String>> groups) {
    if (groups.isEmpty) {
      return '';
    }
    final buffer = StringBuffer('TITLE-ABS-KEY(');
    buffer.write('(');
    buffer.write(
      groups
          .map((group) => group.map(_tokenize).join(' OR '))
          .join(') AND ('),
    );
    buffer.write('))');
    return buffer.toString();
  }

  static String buildCrossrefQuery(List<List<String>> groups) {
    if (groups.isEmpty) {
      return '';
    }
    return groups.map((group) => group.map(_tokenize).join(' OR ')).map((group) => '($group)').join(' AND ');
  }

  static String _tokenize(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final escaped = trimmed.replaceAll('"', '\\"');
    if (escaped.contains(' ')) {
      return '"$escaped"';
    }
    return escaped.toUpperCase();
  }
}
