import '../../data/catalogs/default_category_rules.dart';

class SmsCategorizer {
  const SmsCategorizer();

  String categorize(String party) {
    final lowerParty = party.toLowerCase();
    String bestCategory = 'Uncategorized';
    int bestLength = 0;

    for (final entry in categoryRules.entries) {
      final category = entry.key;
      final keywords = entry.value;
      for (final keyword in keywords) {
        final kwLower = keyword.toLowerCase();
        if (lowerParty.contains(kwLower)) {
          if (kwLower.length > bestLength) {
            bestLength = kwLower.length;
            bestCategory = category;
          }
        }
      }
    }
    return bestCategory;
  }
}
