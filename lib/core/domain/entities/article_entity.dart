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
