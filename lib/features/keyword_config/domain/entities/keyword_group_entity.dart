class KeywordGroupEntity {
  KeywordGroupEntity({
    required this.id,
    required this.name,
    List<String>? keywords,
  }) : keywords = keywords ?? <String>[];

  final String id;
  String name;
  final List<String> keywords;

  KeywordGroupEntity copy() {
    return KeywordGroupEntity(
      id: id,
      name: name,
      keywords: List<String>.from(keywords),
    );
  }
}
