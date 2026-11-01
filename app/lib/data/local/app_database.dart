import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../catalogs/predefined_categories.dart';

part 'app_database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountPaise => integer()();
  TextColumn get type => text()();
  TextColumn get party => text()();
  TextColumn get category => text()();
  TextColumn get accountLast4 => text().nullable()();
  TextColumn get reference => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get status => text()();
  BoolColumn get lowConfidence =>
      boolean().withDefault(const Constant(false))();
  TextColumn get confidenceReason => text().nullable()();
  TextColumn get senderId => text()();
  TextColumn get dedupeKey => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get normalizedParty => text().withDefault(const Constant(''))();
  TextColumn get categorySource => text().withDefault(const Constant('auto'))();
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('unknown'))();
}

class MerchantRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get normalizedParty => text().unique()();
  TextColumn get category => text()();
  DateTimeColumn get updatedAt => dateTime()();
}

class AppStates extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Every category except Uncategorized: the built-in ones (copied in when
/// the database is created, so the user can edit or delete them) and the
/// user's own. [keywords] is a comma-separated list matched against the
/// merchant name to auto-categorize new SMS transactions.
class CustomCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get iconKey => text().withDefault(const Constant('category'))();
  TextColumn get keywords => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [Transactions, MerchantRules, AppStates, CustomCategories],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
    : super(e ?? driftDatabase(name: 'finsight_sms'));

  /// The single connection shared by the whole app. Opening several
  /// connections to the same SQLite file causes lock contention and stalls.
  static final AppDatabase instance = AppDatabase();

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // The background SMS handler and the payment popup open their own
    // connections; wait for a lock instead of failing when they overlap.
    beforeOpen: (_) => customStatement('PRAGMA busy_timeout = 5000'),
    onCreate: (m) async {
      await m.createAll();
      await seedBuiltInCategories();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.normalizedParty);
        await m.addColumn(transactions, transactions.categorySource);
        await m.createTable(merchantRules);
        await m.createTable(appStates);
      }
      if (from < 3) {
        await m.createTable(customCategories);
      }
      if (from < 4) {
        await m.addColumn(transactions, transactions.paymentMethod);
      }
      if (from < 5) {
        // Built-in categories become ordinary, editable rows.
        await seedBuiltInCategories();
      }
    },
  );

  /// Adds any built-in category that is missing (matched by name). Also used
  /// by "Restore built-in categories". Returns how many were added.
  Future<int> seedBuiltInCategories() async {
    final existing = {
      for (final row in await select(customCategories).get())
        row.name.toLowerCase(),
    };
    var added = 0;
    for (final category in predefinedCategories) {
      if (category.name == uncategorizedCategory) continue;
      if (existing.contains(category.name.toLowerCase())) continue;
      await into(customCategories).insert(
        CustomCategoriesCompanion.insert(
          name: category.name,
          iconKey: Value(category.iconKey),
          keywords: Value(category.keywords.join(',')),
          createdAt: DateTime.now().toUtc(),
        ),
      );
      added++;
    }
    return added;
  }
}
