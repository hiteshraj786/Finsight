import 'package:finsight/data/models/parsed_transaction.dart';
import 'package:finsight/data/models/payment_method.dart';
import 'package:finsight/data/models/transaction_status.dart';
import 'package:finsight/data/models/transaction_type.dart';
import 'package:finsight/features/sms/filters/transaction_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1, 10);

  ParsedTransaction tx(
    int rupees, {
    TransactionType type = TransactionType.debit,
    String category = 'Food',
    PaymentMethod method = PaymentMethod.upi,
    TransactionStatus status = TransactionStatus.confirmed,
    required DateTime date,
  }) => ParsedTransaction(
    amountPaise: rupees * 100,
    type: type,
    party: 'Shop',
    category: category,
    date: date,
    status: status,
    paymentMethod: method,
  );

  final octoberLunch = tx(500, date: DateTime(2026, 10, 31, 11));
  final card = tx(
    1500,
    method: PaymentMethod.card,
    category: 'Shopping',
    date: DateTime(2026, 10, 20),
  );
  final salary = tx(
    40000,
    type: TransactionType.credit,
    category: 'Salary',
    method: PaymentMethod.netBanking,
    date: DateTime(2026, 9, 30),
  );
  final pending = tx(
    80,
    status: TransactionStatus.pending,
    date: DateTime(2026, 8, 3),
  );
  final all = [pending, card, octoberLunch, salary];

  test('default filter keeps everything, newest first', () {
    expect(const TransactionFilter().apply(all, now: now), [
      octoberLunch,
      card,
      salary,
      pending,
    ]);
  });

  test('type, method, category and status filters combine', () {
    expect(
      const TransactionFilter(type: TypeFilter.income).apply(all, now: now),
      [salary],
    );
    expect(
      const TransactionFilter(methods: {PaymentMethod.card}).apply(all, now: now),
      [card],
    );
    expect(
      const TransactionFilter(
        categories: {'food'},
        statuses: {TransactionStatus.pending},
      ).apply(all, now: now),
      [pending],
    );
  });

  test('periods are calendar based', () {
    expect(
      const TransactionFilter(period: PeriodFilter.thisMonth).apply(all, now: now),
      isEmpty,
    );
    expect(
      const TransactionFilter(period: PeriodFilter.lastMonth).apply(all, now: now),
      [octoberLunch, card],
    );
    expect(
      const TransactionFilter(period: PeriodFilter.last3Months).apply(all, now: now),
      [octoberLunch, card, salary],
    );
  });

  test('forMonth shows one month and keeps the other filters', () {
    const base = TransactionFilter(methods: {PaymentMethod.upi});
    final octoberFilter = base.forMonth(DateTime(2026, 10), now);
    expect(octoberFilter.period, PeriodFilter.specificMonth);
    expect(octoberFilter.periodLabel, 'Oct 2026');
    expect(octoberFilter.methods, {PaymentMethod.upi});
    expect(octoberFilter.apply(all, now: now), [octoberLunch]);

    final current = base.forMonth(DateTime(2026, 11), now);
    expect(current.period, PeriodFilter.thisMonth);
    expect(current.shownMonth(now), DateTime(2026, 11));
  });

  test('the Activity default shows this month only', () {
    expect(TransactionFilter.thisMonth.shownMonth(now), DateTime(2026, 11));
    expect(TransactionFilter.thisMonth.apply(all, now: now), isEmpty);
    expect(const TransactionFilter().shownMonth(now), isNull);
  });

  test('filters by bank account last 4 digits', () {
    final hdfc = tx(300, date: DateTime(2026, 10, 5)).copyWith(accountLast4: '1234');
    final sbi = tx(700, date: DateTime(2026, 10, 6)).copyWith(accountLast4: '9876');
    final filter = const TransactionFilter(accounts: {'1234'});
    expect(filter.apply([hdfc, sbi, octoberLunch], now: now), [hdfc]);
    expect(filter.activeCount, 1);
    expect(
      const AccountFilterOption(last4: '1234', bankName: 'HDFC Bank').label,
      'HDFC Bank ••1234',
    );
    expect(const AccountFilterOption(last4: '9876').label, 'A/c ••9876');
  });

  test('sorts by amount', () {
    expect(
      const TransactionFilter(sort: SortOrder.highest).apply(all, now: now).first,
      salary,
    );
    expect(
      const TransactionFilter(sort: SortOrder.lowest).apply(all, now: now).first,
      pending,
    );
  });

  test('activeCount ignores sort; cleared keeps sort', () {
    const filter = TransactionFilter(
      type: TypeFilter.expense,
      methods: {PaymentMethod.upi, PaymentMethod.card},
      sort: SortOrder.highest,
    );
    expect(filter.activeCount, 3);
    expect(filter.cleared().activeCount, 0);
    expect(filter.cleared().sort, SortOrder.highest);
  });
}
