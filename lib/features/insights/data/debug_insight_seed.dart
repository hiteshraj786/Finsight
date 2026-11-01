import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../sms/data/database.dart';

/// Deliberately opt-in debug data. Enable only with
/// `--dart-define=FINSIGHT_DEMO_DATA=true`; release builds always no-op.
class DebugInsightSeed {
  static const _requested = bool.fromEnvironment('FINSIGHT_DEMO_DATA');

  static Future<void> seedIfRequested(AppDatabase database) async {
    if (!kDebugMode || !_requested) return;
    final count = await database.select(database.transactions).get().then((rows) => rows.length);
    if (count != 0) return;
    final now = DateTime.now().toUtc();
    const merchants = <(String, String, int)>[
      ('Swiggy', 'Food', 64000), ('Netflix', 'Entertainment', 64900),
      ('Uber', 'Transport', 35000), ('DMart', 'Shopping', 245000),
    ];
    for (var index = 0; index < merchants.length; index++) {
      final item = merchants[index];
      await database.into(database.transactions).insert(TransactionsCompanion.insert(
        amountPaise: item.$3, type: 'debit', party: item.$1, category: item.$2,
        date: now.subtract(Duration(days: index * 7)), status: 'confirmed',
        senderId: 'debug', dedupeKey: 'debug-insight-$index', createdAt: now,
        normalizedParty: Value(item.$1.toLowerCase()), categorySource: const Value('debug'),
      ));
    }
  }
}
