class ArticleEntity {
  const ArticleEntity({
    required this.title,
    required this.documentType,
    required this.source,
    this.publishedYear,
    this.doi,
    this.abstractText,
    this.link,
  });

  final String title;
  final int? publishedYear;
  final String? doi;
  final String? abstractText;
  final String documentType;
  final String source;
  final String? link;
}

class ArticlePage {
  const ArticlePage({
    required this.articles,
    required this.nextCrossrefCursor,
    required this.hasMoreCrossref,
    required this.nextScopusStart,
    required this.hasMoreScopus,
  });

  final List<ArticleEntity> articles;
  final String? nextCrossrefCursor;
  final bool hasMoreCrossref;
  final int nextScopusStart;
  final bool hasMoreScopus;

  bool get hasMore => hasMoreCrossref || hasMoreScopus;
}
