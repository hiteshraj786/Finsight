import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:finsight/features/sms/data/database.dart';
import 'package:finsight/features/sms/data/transaction_repository.dart';
import 'package:finsight/features/sms/models/payment_method.dart';
import 'package:finsight/features/sms/models/parsed_transaction.dart';
import 'package:finsight/features/sms/services/sms_parser.dart';
import 'package:finsight/features/sms/services/dedupe.dart';
import 'package:finsight/features/sms/models/raw_sms_message.dart';
import 'package:finsight/features/sms/models/transaction_type.dart';

void main() {
  test('parses payment method from UPI transaction SMS', () {
    final transaction = const SmsParser().parse(
      RawSmsMessage(
        sender: 'HDFCBK',
        body: 'Rs.250.00 debited via UPI to Swiggy Ref No 123456789012',
        date: DateTime(2026, 11, 1),
      ),
    );

    expect(transaction, isNotNull);
    expect(transaction!.paymentMethod, PaymentMethod.upi);
  });

  test('custom category keywords are used for new transactions', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = TransactionRepository(db: database);
    await database
        .into(database.customCategories)
        .insert(
          CustomCategoriesCompanion.insert(
            name: 'Subscriptions',
            keywords: const Value('netflix, prime'),
            createdAt: DateTime(2026, 11, 1),
          ),
        );

    expect(
      await repository.suggestCategory('Netflix monthly payment'),
      'Subscriptions',
    );
    await database.close();
  });

  test('deduplicates equivalent transactions within the delivery window', () {
    final dedupe = TransactionDeduplicator();
    final first = ParsedTransaction(
      amountPaise: 25000,
      type: TransactionType.debit,
      party: 'Cafe',
      category: 'Food',
      date: DateTime(2026, 11, 1, 23, 58),
    );
    final second = first.copyWith(date: DateTime(2026, 11, 2, 0, 3));

    expect(dedupe.isDuplicate(first), isFalse);
    expect(dedupe.isDuplicate(second), isTrue);
  });
}
