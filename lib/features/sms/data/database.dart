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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.addColumn(transactions, transactions.normalizedParty);
        await m.addColumn(transactions, transactions.categorySource);
        await m.createTable(merchantRules);
        await m.createTable(appStates);
      }
    },
  );
}
