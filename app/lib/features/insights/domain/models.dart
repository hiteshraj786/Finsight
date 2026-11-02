import 'dart:convert';

enum BudgetPeriod { weekly, monthly, yearly }
enum BudgetStatus { onTrack, nearLimit, over }
enum RecurringStatus { detected, confirmed, ignored }
enum UnusualStatus { open, dismissed }

/// A database-independent transaction shape used by all insight engines.
class InsightTransaction {
  final int id;
  final int amountPaise;
  final bool isDebit;
  final String merchant;
  final String normalizedMerchant;
  final String category;
  final DateTime occurredAt;
  final String? account;
  final String? subtitle;

  const InsightTransaction({
    required this.id,
    required this.amountPaise,
    required this.isDebit,
    required this.merchant,
    required this.normalizedMerchant,
    required this.category,
    required this.occurredAt,
    this.account,
    this.subtitle,
  });
}

class Budget {
  final int? id;
  final String categoryId;
  final int limitAmountPaise;
  final BudgetPeriod period;
  final double alertThreshold;
  final bool notifyOnOver;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.categoryId,
    required this.limitAmountPaise,
    required this.period,
    this.alertThreshold = .8,
    this.notifyOnOver = true,
    required this.createdAt,
  });

  Budget copyWith({
    int? id,
    String? categoryId,
    int? limitAmountPaise,
    BudgetPeriod? period,
    double? alertThreshold,
    bool? notifyOnOver,
    DateTime? createdAt,
  }) => Budget(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    limitAmountPaise: limitAmountPaise ?? this.limitAmountPaise,
    period: period ?? this.period,
    alertThreshold: alertThreshold ?? this.alertThreshold,
    notifyOnOver: notifyOnOver ?? this.notifyOnOver,
    createdAt: createdAt ?? this.createdAt,
  );
}

class BudgetEvaluation {
  final Budget budget;
  final int actualPaise;
  final BudgetStatus status;
  final int safeDailySpendPaise;

  const BudgetEvaluation({
    required this.budget,
    required this.actualPaise,
    required this.status,
    required this.safeDailySpendPaise,
  });

  double get progress => budget.limitAmountPaise == 0
      ? 0
      : actualPaise / budget.limitAmountPaise;
}

class RecurringPattern {
  final int? id;
  final String merchant;
  final int amountPaise;
  final int intervalDays;
  final DateTime nextExpectedDate;
  final RecurringStatus status;
  final DateTime lastSeenAt;
  final double confidence;
  final String? paymentMethod;
  final String? patternDescription;

  const RecurringPattern({
    this.id,
    required this.merchant,
    required this.amountPaise,
    required this.intervalDays,
    required this.nextExpectedDate,
    required this.status,
    required this.lastSeenAt,
    required this.confidence,
    this.paymentMethod,
    this.patternDescription,
  });

  RecurringPattern copyWith({
    int? id,
    String? merchant,
    int? amountPaise,
    int? intervalDays,
    DateTime? nextExpectedDate,
    RecurringStatus? status,
    DateTime? lastSeenAt,
    double? confidence,
    String? paymentMethod,
    String? patternDescription,
  }) => RecurringPattern(
    id: id ?? this.id,
    merchant: merchant ?? this.merchant,
    amountPaise: amountPaise ?? this.amountPaise,
    intervalDays: intervalDays ?? this.intervalDays,
    nextExpectedDate: nextExpectedDate ?? this.nextExpectedDate,
    status: status ?? this.status,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    confidence: confidence ?? this.confidence,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    patternDescription: patternDescription ?? this.patternDescription,
  );
}

class UnusualFlag {
  final int? id;
  final int txnId;
  final String reason;
  final UnusualStatus status;
  final DateTime createdAt;
  final String? merchant;
  final int? amountPaise;
  final DateTime? occurredAt;
  final String? usualDescription;

  const UnusualFlag({
    this.id,
    required this.txnId,
    required this.reason,
    this.status = UnusualStatus.open,
    required this.createdAt,
    this.merchant,
    this.amountPaise,
    this.occurredAt,
    this.usualDescription,
  });

  UnusualFlag copyWith({
    int? id,
    int? txnId,
    String? reason,
    UnusualStatus? status,
    DateTime? createdAt,
    String? merchant,
    int? amountPaise,
    DateTime? occurredAt,
    String? usualDescription,
  }) => UnusualFlag(
    id: id ?? this.id,
    txnId: txnId ?? this.txnId,
    reason: reason ?? this.reason,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    merchant: merchant ?? this.merchant,
    amountPaise: amountPaise ?? this.amountPaise,
    occurredAt: occurredAt ?? this.occurredAt,
    usualDescription: usualDescription ?? this.usualDescription,
  );
}

class SavingsGoal {
  final int? id;
  final String name;
  final int targetAmountPaise;
  final int savedAmountPaise;
  final DateTime targetDate;
  final DateTime createdAt;

  const SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmountPaise,
    required this.savedAmountPaise,
    required this.targetDate,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    int? id,
    String? name,
    int? targetAmountPaise,
    int? savedAmountPaise,
    DateTime? targetDate,
    DateTime? createdAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    targetAmountPaise: targetAmountPaise ?? this.targetAmountPaise,
    savedAmountPaise: savedAmountPaise ?? this.savedAmountPaise,
    targetDate: targetDate ?? this.targetDate,
    createdAt: createdAt ?? this.createdAt,
  );
}

class SavingsGoalEvaluation {
  final SavingsGoal goal;
  final int neededPerMonthPaise;
  final bool onTrack;

  const SavingsGoalEvaluation({
    required this.goal,
    required this.neededPerMonthPaise,
    required this.onTrack,
  });

  double get progress => goal.targetAmountPaise == 0
      ? 0
      : (goal.savedAmountPaise / goal.targetAmountPaise).clamp(0.0, 1.0);
}

class CashflowPoint {
  final DateTime date;
  final int balancePaise;
  final bool isActual;
  const CashflowPoint(this.date, this.balancePaise, {this.isActual = false});
}

class CashflowForecast {
  final List<CashflowPoint> points;
  final CashflowPoint lowestPoint;
  final int endBalancePaise;
  final int todayBalancePaise;
  final int safetyCushionPaise;
  final List<RecurringPattern> upcomingOutflows;

  const CashflowForecast({
    required this.points,
    required this.lowestPoint,
    required this.endBalancePaise,
    this.todayBalancePaise = 0,
    this.safetyCushionPaise = 1000000, // ₹10,000
    this.upcomingOutflows = const [],
  });

  int get projectedNetChangePaise => endBalancePaise - todayBalancePaise;
}

class GeneratedInsight {
  final int? id;
  final String type;
  final String message;
  final DateTime generatedAt;
  final List<int> relatedTransactionIds;
  final String? actionLabel;
  final String? actionRoute;
  final bool isRead;

  const GeneratedInsight({
    this.id,
    required this.type,
    required this.message,
    required this.generatedAt,
    this.relatedTransactionIds = const [],
    this.actionLabel,
    this.actionRoute,
    this.isRead = false,
  });

  String get relatedTransactionIdsJson => jsonEncode(relatedTransactionIds);
}

class CategorySpend {
  final String category;
  final int amountPaise;
  final int transactionCount;
  final double sharePercentage;
  final int? previousAmountPaise;
  final double? percentageChange;

  const CategorySpend({
    required this.category,
    required this.amountPaise,
    required this.transactionCount,
    this.sharePercentage = 0,
    this.previousAmountPaise,
    this.percentageChange,
  });
}

class MerchantStat {
  final int rank;
  final String merchant;
  final int amountPaise;
  final int transactionCount;
  final int avgAmountPaise;
  final double relativeShare;

  const MerchantStat({
    required this.rank,
    required this.merchant,
    required this.amountPaise,
    required this.transactionCount,
    required this.avgAmountPaise,
    required this.relativeShare,
  });
}

enum AlertType { budget, recurring, unusual, goal, trend }

class AlertItem {
  final int id;
  final AlertType type;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isRead;
  final String? actionLabel;
  final String? route;

  const AlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isRead = false,
    this.actionLabel,
    this.route,
  });

  AlertItem copyWith({bool? isRead}) => AlertItem(
    id: id,
    type: type,
    title: title,
    subtitle: subtitle,
    timeAgo: timeAgo,
    isRead: isRead ?? this.isRead,
    actionLabel: actionLabel,
    route: route,
  );
}

class TransactionFilter {
  final String dateRange; // 'today', '7days', '30days', 'custom'
  final Set<String> categories;
  final Set<String> accounts;
  final Set<String> merchants;
  final String transactionType; // 'all', 'debit', 'credit'
  final DateTime? customStart;
  final DateTime? customEnd;

  const TransactionFilter({
    this.dateRange = '30days',
    this.categories = const {},
    this.accounts = const {},
    this.merchants = const {},
    this.transactionType = 'debit',
    this.customStart,
    this.customEnd,
  });

  bool get isDefault =>
      dateRange == '30days' &&
      categories.isEmpty &&
      accounts.isEmpty &&
      merchants.isEmpty &&
      transactionType == 'debit';

  int get activeFilterCount {
    var count = 0;
    if (dateRange != '30days') count++;
    count += categories.length;
    count += accounts.length;
    count += merchants.length;
    if (transactionType != 'all') count++;
    return count;
  }

  TransactionFilter copyWith({
    String? dateRange,
    Set<String>? categories,
    Set<String>? accounts,
    Set<String>? merchants,
    String? transactionType,
    DateTime? customStart,
    DateTime? customEnd,
  }) => TransactionFilter(
    dateRange: dateRange ?? this.dateRange,
    categories: categories ?? this.categories,
    accounts: accounts ?? this.accounts,
    merchants: merchants ?? this.merchants,
    transactionType: transactionType ?? this.transactionType,
    customStart: customStart ?? this.customStart,
    customEnd: customEnd ?? this.customEnd,
  );
}
