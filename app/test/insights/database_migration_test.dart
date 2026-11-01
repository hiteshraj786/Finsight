import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/features/sms/data/database.dart';

void main() {
  test('creates all Phase 1 and Phase 2 tables on schemaVersion 3', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final rows = await database.customSelect("SELECT name FROM sqlite_master WHERE type = 'table'").get();
    final tables = rows.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 3);
    expect(tables, containsAll(<String>[
      'transactions', 'merchant_rules', 'app_states', 'budgets', 'recurring_patterns',
      'savings_goals', 'insights', 'unusual_flags',
    ]));
    await database.close();
  });
}
