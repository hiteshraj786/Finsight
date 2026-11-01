/// A transaction category, either one of the predefined categories that ship
/// with the app or one the user created.
class CategoryDefinition {
  /// Database id for a custom category; null for a predefined one.
  final int? id;
  final String name;

  /// Key into [CategoryIcons.byKey].
  final String iconKey;

  /// Lower-case words matched against the merchant name to auto-categorize.
  final List<String> keywords;
  final bool isCustom;

  const CategoryDefinition({
    this.id,
    required this.name,
    required this.iconKey,
    this.keywords = const [],
    this.isCustom = false,
  });

  /// Splits a comma-separated keyword string into clean lower-case keywords.
  static List<String> parseKeywords(String raw) => raw
      .split(',')
      .map((k) => k.trim().toLowerCase())
      .where((k) => k.isNotEmpty)
      .toSet()
      .toList();
}
