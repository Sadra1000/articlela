import '../../domain/entities/article_entity.dart';

class InMemoryArticleCache {
  final List<ArticleEntity> _items = <ArticleEntity>[];

  void clear() {
    _items.clear();
  }

  void addAll(Iterable<ArticleEntity> items) {
    _items.addAll(items);
  }

  void replaceAll(Iterable<ArticleEntity> items) {
    _items
      ..clear()
      ..addAll(items);
  }

  int get length => _items.length;

  List<ArticleEntity> slice(int start, int end) {
    if (start >= _items.length) {
      return <ArticleEntity>[];
    }
    final adjustedEnd = end.clamp(0, _items.length);
    return List<ArticleEntity>.unmodifiable(_items.sublist(start, adjustedEnd));
  }

  List<ArticleEntity> all() => List<ArticleEntity>.unmodifiable(_items);
}
