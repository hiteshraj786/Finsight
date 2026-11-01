import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

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

@DriftDatabase(tables: [Transactions, MerchantRules, AppStates])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e])
    : super(e ?? driftDatabase(name: 'finsight_sms'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createPhase2Tables(m);
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(transactions, transactions.normalizedParty);
        await m.addColumn(transactions, transactions.categorySource);
        await m.createTable(merchantRules);
        await m.createTable(appStates);
      }
      if (from < 3) {
        await _createPhase2Tables(m);
      }
    },
  );

  Future<void> _createPhase2Tables(Migrator m) async {
    await m.database.customStatement('''CREATE TABLE IF NOT EXISTS budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, category_id TEXT NOT NULL,
      limit_amount INTEGER NOT NULL, period TEXT NOT NULL,
      alert_threshold REAL NOT NULL DEFAULT 0.8, notify_on_over INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL)''');
    await m.database.customStatement('''CREATE TABLE IF NOT EXISTS recurring_patterns (
      id INTEGER PRIMARY KEY AUTOINCREMENT, merchant TEXT NOT NULL, amount INTEGER NOT NULL,
      interval_days INTEGER NOT NULL, next_expected_date INTEGER NOT NULL, status TEXT NOT NULL,
      last_seen_at INTEGER NOT NULL, confidence REAL NOT NULL)''');
    await m.database.customStatement('''CREATE TABLE IF NOT EXISTS savings_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target_amount INTEGER NOT NULL,
      saved_amount INTEGER NOT NULL DEFAULT 0, target_date INTEGER NOT NULL, created_at INTEGER NOT NULL)''');
    await m.database.customStatement('''CREATE TABLE IF NOT EXISTS insights (
      id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, message TEXT NOT NULL,
      generated_at INTEGER NOT NULL, related_txn_ids TEXT NOT NULL DEFAULT '[]',
      is_read INTEGER NOT NULL DEFAULT 0)''');
    await m.database.customStatement('''CREATE TABLE IF NOT EXISTS unusual_flags (
      id INTEGER PRIMARY KEY AUTOINCREMENT, txn_id INTEGER NOT NULL, reason TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'open', created_at INTEGER NOT NULL)''');
  }
}
