class OpenAlexAbstractParser {
  const OpenAlexAbstractParser._();

  static String toPlainText(Map<String, dynamic> invertedIndex) {
    if (invertedIndex.isEmpty) {
      return '';
    }
    final positions = <int, String>{};
    var maxIndex = 0;

    invertedIndex.forEach((String token, dynamic value) {
      final indexes = value as List<dynamic>;
      for (final position in indexes) {
        final index = position as int;
        positions[index] = token;
        if (index > maxIndex) {
          maxIndex = index;
        }
      }
    });

    final buffer = <String>[];
    for (var i = 0; i <= maxIndex; i++) {
      buffer.add(positions[i] ?? '');
    }

    final joined = buffer.join(' ');
    final punctuationFixed = joined.replaceAllMapped(
      RegExp(r'\s+([,.;:])'),
      (match) => match.group(1)!,
    );
    return punctuationFixed.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
