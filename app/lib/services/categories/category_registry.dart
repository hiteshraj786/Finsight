import 'package:flutter/foundation.dart';

import '../../data/catalogs/predefined_categories.dart';
import '../../data/models/category_definition.dart';
import '../../data/repositories/category_repository.dart';

/// In-memory list of every category (built-in + the user's own) that pickers and
/// category icons read from. Call [load] at startup; edits reload it and
/// notify listeners.
class CategoryRegistry extends ChangeNotifier {
  CategoryRegistry._(this._repository);

  static final CategoryRegistry instance = CategoryRegistry._(
    CategoryRepository(),
  );

  final CategoryRepository _repository;
  List<CategoryDefinition> _stored = const [];

  /// Every editable category: built-in ones and the user's own.
  List<CategoryDefinition> get editable => _stored;

  /// Every category, with Uncategorized last.
  List<CategoryDefinition> get all => [
    ..._stored,
    predefinedCategories.firstWhere((c) => c.name == uncategorizedCategory),
  ];

  List<String> get names => [for (final c in all) c.name];

  CategoryDefinition? find(String name) {
    final lower = name.trim().toLowerCase();
    for (final c in all) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  Future<void> load() async {
    try {
      _stored = await _repository.getStored();
    } catch (error) {
      debugPrint('Could not load custom categories: $error');
    }
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String iconKey,
    String keywords = '',
  }) async {
    await _repository.add(name: name, iconKey: iconKey, keywords: keywords);
    await load();
  }

  Future<void> update(
    CategoryDefinition category, {
    required String name,
    required String iconKey,
    String keywords = '',
  }) async {
    await _repository.update(
      category,
      name: name,
      iconKey: iconKey,
      keywords: keywords,
    );
    await load();
  }

  Future<void> delete(CategoryDefinition category) async {
    await _repository.delete(category);
    await load();
  }

  /// Brings back built-in categories the user deleted. Returns how many.
  Future<int> restoreBuiltIns() async {
    final added = await _repository.restoreBuiltIns();
    await load();
    return added;
  }
}
