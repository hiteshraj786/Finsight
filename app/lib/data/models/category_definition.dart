class CategoryDefinition {
  final int? id;
  final String name;
  final String iconKey;
  final List<String> keywords;
  final bool isCustom;

  const CategoryDefinition({
    this.id,
    required this.name,
    required this.iconKey,
    this.keywords = const [],
    this.isCustom = true,
  });

  static List<String> parseKeywords(String raw) => raw
      .split(',')
      .map((keyword) => keyword.trim().toLowerCase())
      .where((keyword) => keyword.isNotEmpty)
      .toSet()
      .toList();
}
