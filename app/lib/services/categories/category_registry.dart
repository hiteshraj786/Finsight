import 'package:flutter/foundation.dart';

import '../../data/catalogs/predefined_categories.dart';
import '../../data/models/category_definition.dart';
import '../../data/repositories/category_repository.dart';

class CategoryRegistry extends ChangeNotifier {
  CategoryRegistry._(this._repository);

  static final instance = CategoryRegistry._(CategoryRepository());
  final CategoryRepository _repository;
  List<CategoryDefinition> _stored = const [];

  List<CategoryDefinition> get editable => _stored;
  List<CategoryDefinition> get all => [
        ..._stored,
        predefinedCategories.firstWhere(
          (category) => category.name == uncategorizedCategory,
        ),
      ];
  List<String> get names => [for (final category in all) category.name];

  CategoryDefinition? find(String name) {
    final lower = name.trim().toLowerCase();
    for (final category in all) {
      if (category.name.toLowerCase() == lower) return category;
    }
    return null;
  }

  Future<void> load() async {
    try {
      _stored = await _repository.getStored();
    } catch (error) {
      debugPrint('Could not load categories: $error');
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

  Future<int> restoreBuiltIns() async {
    final added = await _repository.restoreBuiltIns();
    await load();
    return added;
  }
}
