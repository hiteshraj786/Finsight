import 'dart:math' as math;

import 'models.dart';

typedef Clock = DateTime Function();

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

String normalizeMerchant(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

class RecurringDetector {
  const RecurringDetector({required this.clock});
  final Clock clock;

  List<RecurringPattern> detect(
    Iterable<InsightTransaction> transactions, {
    Iterable<RecurringPattern> existing = const [],
  }) {
    final protected = {
      for (final pattern in existing)
        if (pattern.status != RecurringStatus.detected)
          normalizeMerchant(pattern.merchant): pattern,
    };
    final groups = <String, List<InsightTransaction>>{};
    for (final transaction in transactions.where((t) => t.isDebit)) {
      final merchant = transaction.normalizedMerchant.isEmpty
          ? normalizeMerchant(transaction.merchant)
          : transaction.normalizedMerchant;
      if (merchant.isNotEmpty && !protected.containsKey(merchant)) {
        (groups[merchant] ??= []).add(transaction);
      }
    }

    final patterns = <RecurringPattern>[];
    for (final entry in groups.entries) {
      final values = entry.value..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
      if (values.length < 3) continue;
      final sortedAmounts = values.map((t) => t.amountPaise).toList()..sort();
      final median = sortedAmounts[sortedAmounts.length ~/ 2];
      if (median == 0 || values.any((t) => (t.amountPaise - median).abs() / median > .05)) {
        continue;
      }
      final gaps = <int>[
        for (var i = 1; i < values.length; i++)
          _day(values[i].occurredAt).difference(_day(values[i - 1].occurredAt)).inDays,
      ];
      final interval = _bestInterval(gaps);
      if (interval == null) continue;
      final averageGap = gaps.reduce((a, b) => a + b) / gaps.length;
      final proximity = 1 - ((averageGap - interval).abs() / interval).clamp(0, 1);
      final confidence = (.55 + math.min(.25, values.length * .05) + proximity * .2)
          .clamp(0.0, 1.0)
          .toDouble();
      final last = values.last;
      patterns.add(RecurringPattern(
        merchant: last.merchant,
        amountPaise: median,
        intervalDays: interval,
        nextExpectedDate: _day(last.occurredAt).add(Duration(days: interval)),
        status: RecurringStatus.detected,
        lastSeenAt: last.occurredAt,
        confidence: confidence,
      ));
    }
    return patterns;
  }

  int? _bestInterval(List<int> gaps) {
    const candidates = [7, 14, 30, 365];
    int? winner;
    var best = -1;
    for (final candidate in candidates) {
      final matched = gaps.where((gap) => switch (candidate) {
        7 => (gap - 7).abs() <= 2,
        14 => (gap - 14).abs() <= 3,
        30 => gap >= 28 && gap <= 31,
        _ => (gap - 365).abs() <= 14,
      }).length;
      if (matched > best) {
        best = matched;
        winner = candidate;
      }
    }
    return best == gaps.length ? winner : null;
  }
}

class AnomalyDetector {
  const AnomalyDetector({required this.clock});
  final Clock clock;

  List<UnusualFlag> detect(Iterable<InsightTransaction> all) {
    final transactions = all.where((t) => t.isDebit).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final flags = <UnusualFlag>[];
    for (final transaction in transactions) {
      final before = transactions.where((other) =>
          other.id != transaction.id &&
          !other.occurredAt.isAfter(transaction.occurredAt) &&
          other.occurredAt.isAfter(transaction.occurredAt.subtract(const Duration(days: 90))));
      final category = before.where((t) => t.category == transaction.category).toList();
      final merchant = before.where((t) =>
          (t.normalizedMerchant.isEmpty ? normalizeMerchant(t.merchant) : t.normalizedMerchant) ==
          (transaction.normalizedMerchant.isEmpty
              ? normalizeMerchant(transaction.merchant)
              : transaction.normalizedMerchant)).toList();
      final reasons = <String>[];
      if (category.length >= 5) {
        final mean = _mean(category.map((t) => t.amountPaise));
        final deviation = _standardDeviation(category.map((t) => t.amountPaise), mean);
        if (transaction.amountPaise > mean + 2 * deviation) {
          reasons.add('Unusually high for ${transaction.category}');
        }
      }
      if (merchant.isNotEmpty) {
        final average = _mean(merchant.map((t) => t.amountPaise));
        if (average > 0 && transaction.amountPaise > average * 3) {
          reasons.add('More than 3x your usual ${transaction.merchant} payment');
        }
      }
      final duplicate = merchant.any((t) =>
          t.amountPaise == transaction.amountPaise &&
          transaction.occurredAt.difference(t.occurredAt).inHours.abs() <= 48);
      if (duplicate) reasons.add('Possible duplicate charge within 48 hours');
      if (reasons.isNotEmpty) {
        flags.add(UnusualFlag(
          txnId: transaction.id,
          reason: reasons.join(' · '),
          createdAt: clock(),
        ));
      }
    }
    return flags;
  }
}

class BudgetEngine {
  const BudgetEngine({required this.clock});
  final Clock clock;

  BudgetEvaluation evaluate(Budget budget, Iterable<InsightTransaction> transactions) {
    final now = clock();
    final range = _periodRange(now, budget.period);
    final actual = transactions.where((t) =>
      t.isDebit && t.category == budget.categoryId &&
      !t.occurredAt.isBefore(range.$1) && t.occurredAt.isBefore(range.$2))
      .fold(0, (sum, t) => sum + t.amountPaise);
    final ratio = budget.limitAmountPaise == 0 ? 0 : actual / budget.limitAmountPaise;
    final status = ratio > 1
        ? BudgetStatus.over
        : ratio >= budget.alertThreshold ? BudgetStatus.nearLimit : BudgetStatus.onTrack;
    final days = math.max(1, range.$2.difference(_day(now)).inDays);
    return BudgetEvaluation(
      budget: budget,
      actualPaise: actual,
      status: status,
      safeDailySpendPaise: math.max(0, ((budget.limitAmountPaise - actual) / days).floor()),
    );
  }

  (DateTime, DateTime) _periodRange(DateTime now, BudgetPeriod period) => switch (period) {
    BudgetPeriod.weekly => (_day(now).subtract(Duration(days: now.weekday - 1)), _day(now).subtract(Duration(days: now.weekday - 1)).add(const Duration(days: 7))),
    BudgetPeriod.monthly => (DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
    BudgetPeriod.yearly => (DateTime(now.year), DateTime(now.year + 1)),
  };
}

class CashflowProjector {
  const CashflowProjector({required this.clock});
  final Clock clock;

  CashflowForecast project({
    required int currentBalancePaise,
    required Iterable<RecurringPattern> recurring,
    required Iterable<InsightTransaction> history,
    required int windowDays,
  }) {
    final now = _day(clock());
    final recurringMerchants = recurring
        .where((p) => p.status != RecurringStatus.ignored)
        .map((p) => normalizeMerchant(p.merchant)).toSet();
    final recent = history.where((t) =>
      t.isDebit && t.occurredAt.isAfter(now.subtract(const Duration(days: 60))) &&
      !recurringMerchants.contains(t.normalizedMerchant.isEmpty ? normalizeMerchant(t.merchant) : t.normalizedMerchant));
    final sampleStart = now.subtract(const Duration(days: 60));
    final dailyDiscretionary = recent.fold(0, (sum, t) => sum + t.amountPaise) /
        math.max(1, now.difference(sampleStart).inDays);
    final points = <CashflowPoint>[];
    var balance = currentBalancePaise;
    for (var offset = 0; offset <= windowDays; offset++) {
      final day = now.add(Duration(days: offset));
      if (offset > 0) {
        balance -= dailyDiscretionary.round();
        for (final item in recurring.where((p) =>
            p.status != RecurringStatus.ignored && _day(p.nextExpectedDate) == day)) {
          balance -= item.amountPaise;
        }
      }
      points.add(CashflowPoint(day, balance));
    }
    final lowest = points.reduce((a, b) => a.balancePaise <= b.balancePaise ? a : b);
    return CashflowForecast(points: points, lowestPoint: lowest, endBalancePaise: points.last.balancePaise);
  }
}

class SavingsGoalEngine {
  const SavingsGoalEngine({required this.clock});
  final Clock clock;

  SavingsGoalEvaluation evaluate(SavingsGoal goal, int recentMonthlyContributionPaise) {
    final now = _day(clock());
    final months = math.max(1, (goal.targetDate.year - now.year) * 12 + goal.targetDate.month - now.month);
    final needed = math.max(0, ((goal.targetAmountPaise - goal.savedAmountPaise) / months).ceil());
    return SavingsGoalEvaluation(
      goal: goal,
      neededPerMonthPaise: needed,
      onTrack: recentMonthlyContributionPaise >= needed * .9,
    );
  }
}

class InsightGenerator {
  const InsightGenerator({required this.clock});
  final Clock clock;

  List<GeneratedInsight> generate({
    required Iterable<BudgetEvaluation> budgets,
    required Iterable<RecurringPattern> recurring,
    required Map<String, int> currentCategorySpend,
    required Map<String, int> previousCategorySpend,
  }) {
    final generated = <GeneratedInsight>[];
    for (final budget in budgets) {
      if (budget.status == BudgetStatus.over) {
        generated.add(GeneratedInsight(
          type: 'budget_over',
          message: '${budget.budget.categoryId} is ₹${((budget.actualPaise - budget.budget.limitAmountPaise) / 100).toStringAsFixed(0)} over budget',
          generatedAt: clock(),
        ));
      } else if (budget.status == BudgetStatus.nearLimit) {
        generated.add(GeneratedInsight(
          type: 'budget_near',
          message: '${budget.budget.categoryId} reached its budget alert threshold',
          generatedAt: clock(),
        ));
      }
    }
    currentCategorySpend.forEach((category, current) {
      final previous = previousCategorySpend[category] ?? 0;
      if (previous > 0 && current > previous) {
        final percent = ((current - previous) / previous * 100).round();
        if (percent >= 10) generated.add(GeneratedInsight(
          type: 'spending_change', message: 'You spent $percent% more on $category this period', generatedAt: clock()));
      }
    });
    final due = recurring.where((p) => p.status != RecurringStatus.ignored &&
        _day(p.nextExpectedDate).difference(_day(clock())).inDays.between(0, 7)).length;
    if (due > 0) generated.add(GeneratedInsight(
      type: 'recurring_due', message: '$due subscriptions renew in the next 7 days', generatedAt: clock()));
    return generated;
  }
}

extension on int {
  bool between(int min, int max) => this >= min && this <= max;
}

double _mean(Iterable<int> values) {
  final list = values.toList();
  return list.isEmpty ? 0 : list.reduce((a, b) => a + b) / list.length;
}

double _standardDeviation(Iterable<int> values, double mean) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return math.sqrt(list.fold<double>(0, (sum, value) =>
      sum + math.pow(value - mean, 2).toDouble()) / list.length);
}
