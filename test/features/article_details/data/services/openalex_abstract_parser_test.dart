import 'package:flutter_test/flutter_test.dart';

import 'package:articlela/features/article_details/data/services/openalex_abstract_parser.dart';

void main() {
  group('OpenAlexAbstractParser', () {
    test('reconstructs text from inverted index', () {
      final invertedIndex = {
        'The': [0],
        'quick': [1],
        'brown': [2],
        'fox': [3],
        'jumps': [4],
        'over': [5],
        'the': [6],
        'lazy': [7],
        'dog.': [8],
      };

      final text = OpenAlexAbstractParser.toPlainText(invertedIndex);
      expect(text, 'The quick brown fox jumps over the lazy dog.');
    });

    test('handles punctuation without extra spaces', () {
      final invertedIndex = {
        'AI': [0],
        'transforms': [1],
        'science': [2],
        ',': [3, 5],
        'industry': [4],
        'and': [6],
        'education.': [7],
      };

      final text = OpenAlexAbstractParser.toPlainText(invertedIndex);
      expect(text, 'AI transforms science, industry, and education.');
    });
  });
}
