import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/features/insights/domain/engines.dart';
import 'package:finsight/features/insights/domain/models.dart';

final _now = DateTime(2026, 10, 20, 12);
DateTime fixedClock() => _now;

InsightTransaction tx(int id, int amount, DateTime date, {
  String merchant = 'Merchant', String category = 'Food', bool debit = true,
}) => InsightTransaction(
  id: id, amountPaise: amount, isDebit: debit, merchant: merchant,
  normalizedMerchant: normalizeMerchant(merchant), category: category, occurredAt: date,
);

void main() {
  group('RecurringDetector', () {
    test('detects monthly equal payments and calculates the next expected date', () {
      final found = RecurringDetector(clock: fixedClock).detect([
        tx(1, 64900, DateTime(2026, 7, 3), merchant: 'Netflix'),
        tx(2, 65000, DateTime(2026, 8, 3), merchant: 'NETFLIX'),
        tx(3, 64800, DateTime(2026, 9, 3), merchant: 'Netflix!'),
      ]);
      expect(found, hasLength(1));
      expect(found.single.intervalDays, 30);
      expect(found.single.nextExpectedDate, DateTime(2026, 10, 3));
    });

    test('does not overwrite confirmed or ignored decisions', () {
      final found = RecurringDetector(clock: fixedClock).detect([
        tx(1, 10000, DateTime(2026, 8, 1), merchant: 'Gym'),
        tx(2, 10000, DateTime(2026, 8, 8), merchant: 'Gym'),
        tx(3, 10000, DateTime(2026, 8, 15), merchant: 'Gym'),
      ], existing: [RecurringPattern(
        merchant: 'Gym', amountPaise: 10000, intervalDays: 7,
        nextExpectedDate: _now, status: RecurringStatus.confirmed,
        lastSeenAt: _now, confidence: 1,
      )]);
      expect(found, isEmpty);
    });

    test('requires three transactions, similar amounts, and valid gaps', () {
      expect(RecurringDetector(clock: fixedClock).detect([
        tx(1, 100, DateTime(2026, 1, 1)), tx(2, 100, DateTime(2026, 2, 1)),
      ]), isEmpty);
      expect(RecurringDetector(clock: fixedClock).detect([
        tx(1, 100, DateTime(2026, 1, 1)), tx(2, 200, DateTime(2026, 2, 1)), tx(3, 100, DateTime(2026, 3, 1)),
      ]), isEmpty);
    });
  });

  group('AnomalyDetector', () {
    test('flags category outlier, merchant spike, and 48-hour duplicate', () {
      final history = <InsightTransaction>[
        for (var i = 0; i < 5; i++) tx(i, 10000, DateTime(2026, 10, 1 + i), merchant: 'Cafe', category: 'Food'),
        tx(8, 10000, DateTime(2026, 10, 10), merchant: 'Netflix', category: 'Bills'),
        tx(9, 10000, DateTime(2026, 10, 11), merchant: 'Netflix', category: 'Bills'),
        tx(10, 50000, DateTime(2026, 10, 12), merchant: 'Netflix', category: 'Food'),
        tx(11, 50000, DateTime(2026, 10, 13), merchant: 'Netflix', category: 'Food'),
      ];
      final flags = AnomalyDetector(clock: fixedClock).detect(history);
      expect(flags.where((flag) => flag.txnId == 10).single.reason, contains('3x'));
      expect(flags.where((flag) => flag.txnId == 11).single.reason, contains('Possible duplicate'));
    });

    test('has no flags for no data or one transaction', () {
      expect(AnomalyDetector(clock: fixedClock).detect([]), isEmpty);
      expect(AnomalyDetector(clock: fixedClock).detect([tx(1, 100, _now)]), isEmpty);
    });
  });

  group('BudgetEngine', () {
    final engine = BudgetEngine(clock: fixedClock);
    Budget budget() => Budget(
      categoryId: 'Food', limitAmountPaise: 10000, period: BudgetPeriod.monthly,
      alertThreshold: .8, createdAt: _now,
    );

    test('uses threshold boundaries for status', () {
      expect(engine.evaluate(budget(), [tx(1, 7999, _now)]).status, BudgetStatus.onTrack);
      expect(engine.evaluate(budget(), [tx(1, 8000, _now)]).status, BudgetStatus.nearLimit);
      expect(engine.evaluate(budget(), [tx(1, 10000, _now)]).status, BudgetStatus.nearLimit);
      expect(engine.evaluate(budget(), [tx(1, 10001, _now)]).status, BudgetStatus.over);
    });

    test('excludes credits and transactions outside the month boundary', () {
      final result = engine.evaluate(budget(), [
        tx(1, 5000, DateTime(2026, 9, 30, 23, 59)),
        tx(2, 3000, DateTime(2026, 10, 1)),
        tx(3, 9000, DateTime(2026, 10, 2), debit: false),
      ]);
      expect(result.actualPaise, 3000);
    });
  });

  test('CashflowProjector returns daily points, low point and end balance', () {
    final forecast = CashflowProjector(clock: fixedClock).project(
      currentBalancePaise: 100000,
      recurring: [RecurringPattern(merchant: 'Rent', amountPaise: 20000, intervalDays: 30,
        nextExpectedDate: DateTime(2026, 10, 21), status: RecurringStatus.confirmed, lastSeenAt: _now, confidence: 1)],
      history: [tx(1, 6000, DateTime(2026, 10, 19), merchant: 'Coffee')],
      windowDays: 2,
    );
    expect(forecast.points, hasLength(3));
    expect(forecast.lowestPoint.balancePaise, forecast.endBalancePaise);
    expect(forecast.todayBalancePaise, 100000);
    expect(forecast.upcomingOutflows, hasLength(1));
    expect(forecast.upcomingOutflows.single.merchant, 'Rent');
  });

  test('SavingsGoalEngine considers 90 percent of the needed contribution on track', () {
    final goal = SavingsGoal(name: 'Trip', targetAmountPaise: 120000, savedAmountPaise: 0,
      targetDate: DateTime(2027, 10, 20), createdAt: _now);
    final evaluation = SavingsGoalEngine(clock: fixedClock).evaluate(goal, 9000);
    expect(evaluation.neededPerMonthPaise, 10000);
    expect(evaluation.onTrack, isTrue);
  });
}
