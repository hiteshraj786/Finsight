import 'package:drift/drift.dart';

import '../catalogs/predefined_categories.dart';
import '../local/app_database.dart';
import '../models/category_definition.dart';

class CategoryException implements Exception {
  final String message;
  const CategoryException(this.message);

  @override
  String toString() => message;
}

/// Stores every editable category (built-in and the user's own) in the
/// local database. Only [uncategorizedCategory] lives outside it.
class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  /// All stored categories, oldest first (built-ins keep their usual order).
  Future<List<CategoryDefinition>> getStored() async {
    final rows = await (_db.select(
      _db.customCategories,
    )..orderBy([(c) => OrderingTerm(expression: c.id)])).get();
    return rows.map(_toModel).toList();
  }

  /// Re-adds any built-in category the user deleted. Returns how many.
  Future<int> restoreBuiltIns() => _db.seedBuiltInCategories();

  Future<void> add({
    required String name,
    required String iconKey,
    String keywords = '',
  }) async {
    final clean = await _validateName(name);
    await _db
        .into(_db.customCategories)
        .insert(
          CustomCategoriesCompanion.insert(
            name: clean,
            iconKey: Value(iconKey),
            keywords: Value(CategoryDefinition.parseKeywords(keywords).join(',')),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Updates a custom category. A rename is carried over to every
  /// transaction and learned merchant rule that used the old name.
  Future<void> update(
    CategoryDefinition category, {
    required String name,
    required String iconKey,
    String keywords = '',
  }) async {
    final id = category.id;
    if (id == null) {
      throw const CategoryException('Uncategorized cannot be edited.');
    }
    final clean = await _validateName(name, exceptId: id);
    await _db.transaction(() async {
      await (_db.update(
        _db.customCategories,
      )..where((c) => c.id.equals(id))).write(
        CustomCategoriesCompanion(
          name: Value(clean),
          iconKey: Value(iconKey),
          keywords: Value(CategoryDefinition.parseKeywords(keywords).join(',')),
        ),
      );
      if (clean != category.name) {
        await _renameUsages(category.name, clean);
      }
    });
  }

  /// Deletes a custom category. Its transactions and merchant rules fall back
  /// to [uncategorizedCategory].
  Future<void> delete(CategoryDefinition category) async {
    final id = category.id;
    if (id == null) {
      throw const CategoryException('Uncategorized cannot be deleted.');
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.customCategories,
      )..where((c) => c.id.equals(id))).go();
      await (_db.update(_db.transactions)
            ..where((t) => t.category.equals(category.name)))
          .write(const TransactionsCompanion(category: Value(uncategorizedCategory)));
      await (_db.delete(
        _db.merchantRules,
      )..where((r) => r.category.equals(category.name))).go();
    });
  }

  Future<void> _renameUsages(String from, String to) async {
    await (_db.update(_db.transactions)..where((t) => t.category.equals(from)))
        .write(TransactionsCompanion(category: Value(to)));
    await (_db.update(_db.merchantRules)..where((r) => r.category.equals(from)))
        .write(MerchantRulesCompanion(category: Value(to)));
  }

  Future<String> _validateName(String name, {int? exceptId}) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) {
      throw const CategoryException('Enter a category name.');
    }
    if (clean.length > 24) {
      throw const CategoryException('Use 24 characters or fewer.');
    }
    final lower = clean.toLowerCase();
    if (lower == uncategorizedCategory.toLowerCase()) {
      throw const CategoryException('"Uncategorized" is reserved.');
    }
    final existing = await getStored();
    if (existing.any((c) => c.id != exceptId && c.name.toLowerCase() == lower)) {
      throw CategoryException('You already have a category called "$clean".');
    }
    return clean;
  }

  CategoryDefinition _toModel(CustomCategory row) => CategoryDefinition(
    id: row.id,
    name: row.name,
    iconKey: row.iconKey,
    keywords: CategoryDefinition.parseKeywords(row.keywords),
    isCustom: true,
  );
}
