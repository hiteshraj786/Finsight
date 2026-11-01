import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:finsight/data/catalogs/predefined_categories.dart';
import 'package:finsight/data/local/app_database.dart';
import 'package:finsight/data/models/category_definition.dart';
import 'package:finsight/data/models/parsed_transaction.dart';
import 'package:finsight/data/models/transaction_type.dart';
import 'package:finsight/data/repositories/category_repository.dart';
import 'package:finsight/data/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;
  late TransactionRepository transactions;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    categories = CategoryRepository(db: db);
    transactions = TransactionRepository(db: db);
  });

  tearDown(() => db.close());

  ParsedTransaction tx(String party, {String? ref}) => ParsedTransaction(
    amountPaise: 150000,
    type: TransactionType.debit,
    party: party,
    category: 'Uncategorized',
    reference: ref,
    date: DateTime(2026, 10, 30, 12),
    sender: 'AD-HDFCBK',
  );

  Future<CategoryDefinition> named(String name) async =>
      (await categories.getStored()).firstWhere((c) => c.name == name);

  test('a new database contains the built-in categories as editable rows', () async {
    final stored = await categories.getStored();
    final builtIns = predefinedCategories
        .where((c) => c.name != uncategorizedCategory)
        .map((c) => c.name);
    expect(stored.map((c) => c.name), builtIns);
    expect(stored.every((c) => c.isCustom && c.id != null), isTrue);
    expect((await named('Food')).keywords, contains('swiggy'));
  });

  test('adds a category with cleaned keywords', () async {
    await categories.add(name: '  Rent ', iconKey: 'home', keywords: 'NoBroker, landlord,,');
    final rent = await named('Rent');
    expect(rent.keywords, ['nobroker', 'landlord']);
  });

  test('rejects duplicate, reserved and empty names', () async {
    expect(
      () => categories.add(name: 'food', iconKey: 'food'),
      throwsA(isA<CategoryException>()),
    );
    expect(
      () => categories.add(name: 'uncategorized', iconKey: 'category'),
      throwsA(isA<CategoryException>()),
    );
    expect(
      () => categories.add(name: '   ', iconKey: 'pets'),
      throwsA(isA<CategoryException>()),
    );
  });

  test('custom keywords auto-categorize new transactions', () async {
    await categories.add(name: 'Rent', iconKey: 'home', keywords: 'nobroker');
    await transactions.insertNewFromScan([tx('NOBROKER TECHNOLOGIES', ref: '1')]);
    expect((await transactions.getAll()).single.category, 'Rent');
  });

  test('a newer category wins a keyword tie with a built-in', () async {
    await categories.add(name: 'Office lunch', iconKey: 'cafe', keywords: 'swiggy');
    expect(await transactions.suggestCategory('Swiggy'), 'Office lunch');
  });

  test('editing a built-in changes its name, keywords and transactions', () async {
    await transactions.insertNewFromScan([tx('Swiggy', ref: '2')]);
    expect((await transactions.getAll()).single.category, 'Food');

    await categories.update(
      await named('Food'),
      name: 'Eating out',
      iconKey: 'food',
      keywords: 'zomato',
    );
    expect((await transactions.getAll()).single.category, 'Eating out');
    expect(await transactions.suggestCategory('Swiggy'), 'Uncategorized');
    expect(await transactions.suggestCategory('Zomato'), 'Eating out');
  });

  test('deleting a built-in stops it being suggested; restore brings it back', () async {
    await transactions.insertNewFromScan([tx('Swiggy', ref: '3')]);
    await categories.delete(await named('Food'));
    expect((await transactions.getAll()).single.category, 'Uncategorized');
    expect(await transactions.suggestCategory('Swiggy'), 'Uncategorized');

    expect(await categories.restoreBuiltIns(), 1);
    expect(await transactions.suggestCategory('Swiggy'), 'Food');
    expect(await categories.restoreBuiltIns(), 0);
  });

  test('deleting all transactions keeps categories, rules and sync position', () async {
    await categories.add(name: 'Rent', iconKey: 'home', keywords: 'nobroker');
    await transactions.insertNewFromScan([tx('NoBroker', ref: '4'), tx('Uber', ref: '5')]);
    await transactions.saveMerchantRule('Uber', 'Rent');
    await transactions.setLastCheckedSmsTimestamp(123);

    expect(await transactions.deleteAllTransactions(), 2);
    expect(await transactions.getAll(), isEmpty);
    expect((await named('Rent')).keywords, ['nobroker']);
    expect(await transactions.suggestCategory('Uber'), 'Rent');
    expect(await transactions.getLastCheckedSmsTimestamp(), 123);
  });
}
