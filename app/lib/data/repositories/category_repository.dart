import 'package:drift/drift.dart';

import '../catalogs/predefined_categories.dart';
import '../models/category_definition.dart';
import '../../features/sms/data/database.dart';

class CategoryException implements Exception {
  final String message;
  const CategoryException(this.message);

  @override
  String toString() => message;
}

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  Future<List<CategoryDefinition>> getStored() async {
    final rows = await (_db.select(
      _db.customCategories,
    )..orderBy([(category) => OrderingTerm(expression: category.id)])).get();
    return rows
        .map(
          (row) => CategoryDefinition(
            id: row.id,
            name: row.name,
            iconKey: row.iconKey,
            keywords: CategoryDefinition.parseKeywords(row.keywords),
          ),
        )
        .toList();
  }

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
            keywords: Value(
              CategoryDefinition.parseKeywords(keywords).join(','),
            ),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> update(
    CategoryDefinition category, {
    required String name,
    required String iconKey,
    String keywords = '',
  }) async {
    final id = category.id;
    if (id == null) {
      throw const CategoryException('This category cannot be edited.');
    }
    final clean = await _validateName(name, exceptId: id);
    await _db.transaction(() async {
      await (_db.update(
        _db.customCategories,
      )..where((row) => row.id.equals(id))).write(
        CustomCategoriesCompanion(
          name: Value(clean),
          iconKey: Value(iconKey),
          keywords: Value(CategoryDefinition.parseKeywords(keywords).join(',')),
        ),
      );
      if (clean != category.name) {
        await (_db.update(_db.transactions)..where(
              (transaction) => transaction.category.equals(category.name),
            ))
            .write(TransactionsCompanion(category: Value(clean)));
        await (_db.update(_db.merchantRules)
              ..where((rule) => rule.category.equals(category.name)))
            .write(MerchantRulesCompanion(category: Value(clean)));
      }
    });
  }

  Future<void> delete(CategoryDefinition category) async {
    final id = category.id;
    if (id == null) {
      throw const CategoryException('This category cannot be deleted.');
    }
    await _db.transaction(() async {
      await (_db.delete(
        _db.customCategories,
      )..where((row) => row.id.equals(id))).go();
      await (_db.update(
            _db.transactions,
          )..where((transaction) => transaction.category.equals(category.name)))
          .write(
            const TransactionsCompanion(category: Value(uncategorizedCategory)),
          );
      await (_db.delete(
        _db.merchantRules,
      )..where((rule) => rule.category.equals(category.name))).go();
    });
  }

  Future<String> _validateName(String name, {int? exceptId}) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) throw const CategoryException('Enter a category name.');
    if (clean.length > 24) {
      throw const CategoryException('Use 24 characters or fewer.');
    }
    if (clean.toLowerCase() == uncategorizedCategory.toLowerCase()) {
      throw const CategoryException('"Uncategorized" is reserved.');
    }
    final existing = await getStored();
    if (existing.any(
      (item) =>
          item.id != exceptId && item.name.toLowerCase() == clean.toLowerCase(),
    )) {
      throw CategoryException('You already have a category called "$clean".');
    }
    return clean;
  }
}
