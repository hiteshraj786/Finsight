import '../domain/models.dart';
import 'insights_repository.dart';

class MockInsightsRepository implements InsightsRepository {
  // Dynamic in-memory state so user edits/saves update the screens immediately
  final List<Budget> _budgets = [
    Budget(
      id: 1,
      categoryId: 'Food & Dining',
      limitAmountPaise: 1500000, // ₹15,000
      period: BudgetPeriod.monthly,
      alertThreshold: 0.8,
      notifyOnOver: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Budget(
      id: 2,
      categoryId: 'Shopping',
      limitAmountPaise: 800000, // ₹8,000
      period: BudgetPeriod.monthly,
      alertThreshold: 0.8,
      notifyOnOver: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Budget(
      id: 3,
      categoryId: 'Transport',
      limitAmountPaise: 700000, // ₹7,000
      period: BudgetPeriod.monthly,
      alertThreshold: 0.8,
      notifyOnOver: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Budget(
      id: 4,
      categoryId: 'Bills & Utilities',
      limitAmountPaise: 650000, // ₹6,500
      period: BudgetPeriod.monthly,
      alertThreshold: 0.8,
      notifyOnOver: true,
      createdAt: DateTime(2026, 10, 1),
    ),
    Budget(
      id: 5,
      categoryId: 'Entertainment',
      limitAmountPaise: 400000, // ₹4,000
      period: BudgetPeriod.monthly,
      alertThreshold: 0.8,
      notifyOnOver: true,
      createdAt: DateTime(2026, 10, 1),
    ),
  ];

  final Map<String, int> _categorySpendMap = {
    'Food & Dining': 1245000, // ₹12,450
    'Shopping': 980000,       // ₹9,800
    'Bills & Utilities': 610000, // ₹6,100
    'Transport': 520000,      // ₹5,200
    'Entertainment': 343000,  // ₹3,430
    'Health': 220000,         // ₹2,200
    'Others': 320000,         // ₹3,200
  };

  final List<RecurringPattern> _recurring = [
    RecurringPattern(
      id: 1,
      merchant: 'Rent',
      amountPaise: 1200000,
      intervalDays: 30,
      nextExpectedDate: DateTime(2026, 11, 1),
      status: RecurringStatus.confirmed,
      lastSeenAt: DateTime(2026, 10, 1),
      confidence: 0.98,
      paymentMethod: 'UPI • Landlord',
      patternDescription: '1st of every month',
    ),
    RecurringPattern(
      id: 2,
      merchant: 'Netflix',
      amountPaise: 64900,
      intervalDays: 30,
      nextExpectedDate: DateTime(2026, 11, 3),
      status: RecurringStatus.detected,
      lastSeenAt: DateTime(2026, 10, 3),
      confidence: 0.85,
      paymentMethod: 'Card • Mandate',
      patternDescription: '3rd of every month',
    ),
    RecurringPattern(
      id: 3,
      merchant: 'Jio recharge',
      amountPaise: 59900,
      intervalDays: 84,
      nextExpectedDate: DateTime(2026, 11, 5),
      status: RecurringStatus.confirmed,
      lastSeenAt: DateTime(2026, 8, 15),
      confidence: 0.92,
      paymentMethod: 'Prepaid • 84 Days',
      patternDescription: 'Every 84 days',
    ),
    RecurringPattern(
      id: 4,
      merchant: 'Cult Gym',
      amountPaise: 150000,
      intervalDays: 30,
      nextExpectedDate: DateTime(2026, 11, 8),
      status: RecurringStatus.confirmed,
      lastSeenAt: DateTime(2026, 10, 8),
      confidence: 0.95,
      paymentMethod: 'Fitness • Auto-pay',
      patternDescription: '8th of every month',
    ),
    RecurringPattern(
      id: 5,
      merchant: 'HDFC car EMI',
      amountPaise: 825000,
      intervalDays: 30,
      nextExpectedDate: DateTime(2026, 11, 10),
      status: RecurringStatus.confirmed,
      lastSeenAt: DateTime(2026, 10, 10),
      confidence: 0.99,
      paymentMethod: 'Auto NACH • Loan',
      patternDescription: '10th of every month',
    ),
    RecurringPattern(
      id: 6,
      merchant: 'Spotify',
      amountPaise: 11900,
      intervalDays: 30,
      nextExpectedDate: DateTime(2026, 11, 12),
      status: RecurringStatus.confirmed,
      lastSeenAt: DateTime(2026, 10, 12),
      confidence: 0.90,
      paymentMethod: 'UPI Autopay',
      patternDescription: '12th of every month',
    ),
  ];

  final List<UnusualFlag> _unusualFlags = [
    UnusualFlag(
      id: 1,
      txnId: 101,
      merchant: 'Electronics Store',
      amountPaise: 1849900,
      reason: 'Your usual biggest purchase is about ₹4,200',
      occurredAt: DateTime(2026, 10, 24),
      status: UnusualStatus.open,
      createdAt: DateTime(2026, 10, 24),
      usualDescription: '₹18,499 · Flagged outlier purchase',
    ),
    UnusualFlag(
      id: 2,
      txnId: 102,
      merchant: 'Swiggy',
      amountPaise: 184000,
      reason: '3x your average order of ₹610',
      occurredAt: DateTime(2026, 10, 26),
      status: UnusualStatus.open,
      createdAt: DateTime(2026, 10, 26),
      usualDescription: '₹1,840 · 3x higher than average',
    ),
    UnusualFlag(
      id: 3,
      txnId: 103,
      merchant: 'Netflix',
      amountPaise: 64900,
      reason: '₹649 charged twice in 2 days • Possible duplicate',
      occurredAt: DateTime(2026, 10, 27),
      status: UnusualStatus.open,
      createdAt: DateTime(2026, 10, 27),
      usualDescription: '₹649 · Duplicate charge',
    ),
  ];

  final List<SavingsGoal> _goals = [
    SavingsGoal(
      id: 1,
      name: 'Goa trip',
      targetAmountPaise: 3000000, // ₹30,000
      savedAmountPaise: 1800000,  // ₹18,000
      targetDate: DateTime(2026, 12, 15),
      createdAt: DateTime(2026, 8, 1),
    ),
    SavingsGoal(
      id: 2,
      name: 'Emergency fund',
      targetAmountPaise: 10000000, // ₹1,00,000
      savedAmountPaise: 4500000,   // ₹45,000
      targetDate: DateTime(2027, 3, 31),
      createdAt: DateTime(2026, 1, 1),
    ),
    SavingsGoal(
      id: 3,
      name: 'New laptop',
      targetAmountPaise: 7200000, // ₹72,000
      savedAmountPaise: 3300000,  // ₹33,000
      targetDate: DateTime(2027, 1, 31),
      createdAt: DateTime(2026, 6, 1),
    ),
  ];

  final List<AlertItem> _alerts = [
    const AlertItem(
      id: 1,
      type: AlertType.budget,
      title: 'Shopping went over budget by ₹1,800',
      subtitle: 'Monthly budget · 2h ago',
      timeAgo: '2h ago',
      route: '/budget',
    ),
    const AlertItem(
      id: 2,
      type: AlertType.recurring,
      title: 'Netflix renews tomorrow · ₹649',
      subtitle: 'Recurring mandate · 5h ago',
      timeAgo: '5h ago',
      route: '/insights/recurring',
    ),
    const AlertItem(
      id: 3,
      type: AlertType.unusual,
      title: 'Unusual: ₹18,499 at Electronics store',
      subtitle: 'Flagged purchase · Yesterday',
      timeAgo: 'Yesterday',
      actionLabel: 'Review >',
      route: '/insights/unusual',
    ),
    const AlertItem(
      id: 4,
      type: AlertType.goal,
      title: "You're on track to save ₹6,200 this month",
      subtitle: 'Savings goal · 2 days ago',
      timeAgo: '2 days ago',
      route: '/insights',
    ),
    const AlertItem(
      id: 5,
      type: AlertType.trend,
      title: 'Food spending is 20% higher than September',
      subtitle: 'Category trend · 3 days ago',
      timeAgo: '3 days ago',
      route: '/insights',
    ),
  ];

  final List<InsightTransaction> _transactions = [
    InsightTransaction(
      id: 1,
      merchant: 'Swiggy',
      normalizedMerchant: 'swiggy',
      amountPaise: 64000,
      isDebit: true,
      category: 'Food & Dining',
      occurredAt: DateTime(2026, 10, 31, 20, 42),
      account: 'SBI ••4821',
      subtitle: 'Food Delivery',
    ),
    InsightTransaction(
      id: 2,
      merchant: 'Upwork payout',
      normalizedMerchant: 'upwork',
      amountPaise: 1500000,
      isDebit: false,
      category: 'Income',
      occurredAt: DateTime(2026, 10, 31, 15, 15),
      account: 'SBI ••4821',
      subtitle: 'Freelance Credit',
    ),
    InsightTransaction(
      id: 3,
      merchant: 'Starbucks Coffee',
      normalizedMerchant: 'starbucks',
      amountPaise: 35000,
      isDebit: true,
      category: 'Food & Dining',
      occurredAt: DateTime(2026, 10, 31, 11, 20),
      account: 'HDFC ••1190',
      subtitle: 'Beverages',
    ),
    InsightTransaction(
      id: 4,
      merchant: 'Zomato',
      normalizedMerchant: 'zomato',
      amountPaise: 48000,
      isDebit: true,
      category: 'Food & Dining',
      occurredAt: DateTime(2026, 10, 30, 21, 10),
      account: 'SBI ••4821',
      subtitle: 'Dinner Out',
    ),
    InsightTransaction(
      id: 5,
      merchant: 'Blinkit Commerce',
      normalizedMerchant: 'blinkit',
      amountPaise: 89000,
      isDebit: true,
      category: 'Shopping',
      occurredAt: DateTime(2026, 10, 30, 18, 30),
      account: 'SBI ••4821',
      subtitle: 'Quick Groceries',
    ),
    InsightTransaction(
      id: 6,
      merchant: 'FreshMenu',
      normalizedMerchant: 'freshmenu',
      amountPaise: 31000,
      isDebit: true,
      category: 'Food & Dining',
      occurredAt: DateTime(2026, 10, 30, 13, 15),
      account: 'SBI ••4821',
      subtitle: 'Lunch Combo',
    ),
    InsightTransaction(
      id: 7,
      merchant: 'DMart',
      normalizedMerchant: 'dmart',
      amountPaise: 245000,
      isDebit: true,
      category: 'Shopping',
      occurredAt: DateTime(2026, 10, 27, 19, 45),
      account: 'SBI ••4821',
      subtitle: 'Household',
    ),
    InsightTransaction(
      id: 8,
      merchant: 'Chai Point',
      normalizedMerchant: 'chai point',
      amountPaise: 14000,
      isDebit: true,
      category: 'Food & Dining',
      occurredAt: DateTime(2026, 10, 27, 16, 10),
      account: 'HDFC ••1190',
      subtitle: 'Snacks & Chai',
    ),
    InsightTransaction(
      id: 9,
      merchant: 'Cred Cashback',
      normalizedMerchant: 'cred',
      amountPaise: 5000,
      isDebit: false,
      category: 'Income',
      occurredAt: DateTime(2026, 10, 27, 10, 0),
      account: 'SBI ••4821',
      subtitle: 'Bill Reward',
    ),
  ];

  @override
  Future<List<InsightTransaction>> confirmedTransactions({DateTime? from, DateTime? to}) async {
    return _transactions;
  }

  @override
  Future<List<CategorySpend>> categorySpend(DateTime from, DateTime to) async {
    return getCategorySpend();
  }

  @override
  Future<List<MerchantSpend>> topMerchants(DateTime from, DateTime to, {int limit = 10}) async {
    return getTopMerchants();
  }

  @override
  Future<List<CategorySpend>> getCategorySpend({String period = 'month', DateTime? date}) async {
    return [
      CategorySpend(
        category: 'Food & Dining',
        amountPaise: _categorySpendMap['Food & Dining']!,
        transactionCount: 38,
        sharePercentage: 29.4,
        previousAmountPaise: 1090000,
        percentageChange: 14.0,
      ),
      CategorySpend(
        category: 'Shopping',
        amountPaise: _categorySpendMap['Shopping']!,
        transactionCount: 19,
        sharePercentage: 23.1,
        previousAmountPaise: 900000,
        percentageChange: 8.0,
      ),
      CategorySpend(
        category: 'Bills & Utilities',
        amountPaise: _categorySpendMap['Bills & Utilities']!,
        transactionCount: 6,
        sharePercentage: 14.4,
        previousAmountPaise: 640000,
        percentageChange: -5.0,
      ),
      CategorySpend(
        category: 'Transport',
        amountPaise: _categorySpendMap['Transport']!,
        transactionCount: 27,
        sharePercentage: 12.3,
      ),
      CategorySpend(
        category: 'Entertainment',
        amountPaise: _categorySpendMap['Entertainment']!,
        transactionCount: 11,
        sharePercentage: 8.1,
      ),
      CategorySpend(
        category: 'Health',
        amountPaise: _categorySpendMap['Health']!,
        transactionCount: 4,
        sharePercentage: 5.2,
      ),
      CategorySpend(
        category: 'Others',
        amountPaise: _categorySpendMap['Others']!,
        transactionCount: 5,
        sharePercentage: 7.5,
      ),
    ];
  }

  @override
  Future<List<Budget>> getBudgets() async => List.unmodifiable(_budgets);

  @override
  Future<List<BudgetEvaluation>> getBudgetEvaluations() async {
    final list = <BudgetEvaluation>[];
    for (final budget in _budgets) {
      final actual = _categorySpendMap[budget.categoryId] ?? 0;
      final ratio = budget.limitAmountPaise == 0 ? 0.0 : actual / budget.limitAmountPaise;
      final status = ratio > 1.0
          ? BudgetStatus.over
          : (ratio >= budget.alertThreshold ? BudgetStatus.nearLimit : BudgetStatus.onTrack);
      const remainingDays = 11;
      final remaining = budget.limitAmountPaise - actual;
      final safeDaily = remaining > 0 ? (remaining / remainingDays).floor() : 0;
      list.add(BudgetEvaluation(
        budget: budget,
        actualPaise: actual,
        status: status,
        safeDailySpendPaise: safeDaily,
      ));
    }
    return list;
  }

  @override
  Future<int> saveBudget(Budget budget) async {
    final index = _budgets.indexWhere((b) => b.categoryId == budget.categoryId);
    if (index >= 0) {
      _budgets[index] = budget.copyWith(id: _budgets[index].id);
      return _budgets[index].id!;
    } else {
      final newId = _budgets.length + 1;
      _budgets.add(budget.copyWith(id: newId));
      return newId;
    }
  }

  @override
  Future<List<RecurringPattern>> getRecurring() async => List.unmodifiable(_recurring);

  @override
  Future<List<RecurringPattern>> getRecurringPatterns() async => List.unmodifiable(_recurring);

  @override
  Future<void> saveDetectedPatterns(Iterable<RecurringPattern> patterns) async {
    for (final p in patterns) {
      final idx = _recurring.indexWhere((r) => r.merchant == p.merchant);
      if (idx >= 0) {
        if (_recurring[idx].status == RecurringStatus.detected) {
          _recurring[idx] = p.copyWith(id: _recurring[idx].id);
        }
      } else {
        _recurring.add(p.copyWith(id: _recurring.length + 1));
      }
    }
  }

  @override
  Future<void> setRecurringStatus(int id, RecurringStatus status) async {
    final index = _recurring.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _recurring[index] = _recurring[index].copyWith(status: status);
    }
  }

  @override
  Future<void> confirmRecurring(int id) async => setRecurringStatus(id, RecurringStatus.confirmed);

  @override
  Future<void> ignoreRecurring(int id) async => setRecurringStatus(id, RecurringStatus.ignored);

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async => List.unmodifiable(_goals);

  @override
  Future<List<SavingsGoalEvaluation>> getSavingsGoalEvaluations() async {
    return [
      SavingsGoalEvaluation(
        goal: _goals[0],
        neededPerMonthPaise: 400000, // ₹4,000 / month
        onTrack: true,
      ),
      SavingsGoalEvaluation(
        goal: _goals[1],
        neededPerMonthPaise: 550000, // ₹5,500 / month
        onTrack: false, // Slightly behind
      ),
      SavingsGoalEvaluation(
        goal: _goals[2],
        neededPerMonthPaise: 390000, // ₹3,900 / month
        onTrack: true,
      ),
    ];
  }

  @override
  Future<int> saveSavingsGoal(SavingsGoal goal) async => addGoal(goal);

  @override
  Future<int> addGoal(SavingsGoal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      _goals[index] = goal;
      return goal.id!;
    }
    final newId = _goals.length + 1;
    _goals.add(goal.copyWith(id: newId));
    return newId;
  }

  @override
  Future<void> addMoneyToGoal(int id, int amountPaise) async {
    final index = _goals.indexWhere((g) => g.id == id);
    if (index >= 0) {
      _goals[index] = _goals[index].copyWith(
        savedAmountPaise: _goals[index].savedAmountPaise + amountPaise,
      );
    }
  }

  @override
  Future<List<UnusualFlag>> getUnusual() async =>
      _unusualFlags.where((f) => f.status == UnusualStatus.open).toList();

  @override
  Future<List<UnusualFlag>> getUnusualFlags({UnusualStatus status = UnusualStatus.open}) async =>
      _unusualFlags.where((f) => f.status == status).toList();

  @override
  Future<void> saveUnusualFlags(Iterable<UnusualFlag> flags) async {
    for (final f in flags) {
      if (!_unusualFlags.any((item) => item.txnId == f.txnId)) {
        _unusualFlags.add(f.copyWith(id: _unusualFlags.length + 1));
      }
    }
  }

  @override
  Future<void> setUnusualStatus(int id, UnusualStatus status) async {
    final index = _unusualFlags.indexWhere((f) => f.id == id);
    if (index >= 0) {
      _unusualFlags[index] = _unusualFlags[index].copyWith(status: status);
    }
  }

  @override
  Future<void> dismissUnusual(int id) async => setUnusualStatus(id, UnusualStatus.dismissed);

  @override
  Future<List<MerchantStat>> getTopMerchants({String period = 'month', String sortBy = 'amount'}) async {
    final list = [
      const MerchantStat(rank: 1, merchant: 'Swiggy', amountPaise: 842000, transactionCount: 14, avgAmountPaise: 60100, relativeShare: 1.0),
      const MerchantStat(rank: 2, merchant: 'Amazon', amountPaise: 735000, transactionCount: 8, avgAmountPaise: 91900, relativeShare: 0.87),
      const MerchantStat(rank: 3, merchant: 'DMart', amountPaise: 485000, transactionCount: 3, avgAmountPaise: 161700, relativeShare: 0.58),
      const MerchantStat(rank: 4, merchant: 'Uber', amountPaise: 390000, transactionCount: 11, avgAmountPaise: 35500, relativeShare: 0.46),
      const MerchantStat(rank: 5, merchant: 'Zomato', amountPaise: 312000, transactionCount: 7, avgAmountPaise: 44600, relativeShare: 0.37),
    ];
    if (sortBy == 'count') {
      list.sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    }
    return list;
  }

  @override
  Future<CashflowForecast> getCashflow() async {
    return CashflowForecast(
      points: [
        CashflowPoint(DateTime(2026, 11, 1), 5840000, isActual: true), // 1 Nov: ₹58,400
        CashflowPoint(DateTime(2026, 11, 5), 4500000, isActual: true), // 5 Nov
        CashflowPoint(DateTime(2026, 11, 8), 3500000, isActual: false), // 8 Nov
        CashflowPoint(DateTime(2026, 11, 10), 980000, isActual: false), // 10 Nov: Low point ₹9,800
        CashflowPoint(DateTime(2026, 11, 15), 1800000, isActual: false),
        CashflowPoint(DateTime(2026, 11, 20), 2400000, isActual: false),
        CashflowPoint(DateTime(2026, 11, 25), 2300000, isActual: false),
        CashflowPoint(DateTime(2026, 11, 30), 2130000, isActual: false), // 30 Nov: End ₹21,300
      ],
      lowestPoint: CashflowPoint(DateTime(2026, 11, 10), 980000),
      endBalancePaise: 2130000, // ₹21,300
      todayBalancePaise: 5840000, // ₹58,400
      safetyCushionPaise: 1000000, // ₹10,000
      upcomingOutflows: [
        RecurringPattern(
          id: 1,
          merchant: 'Rent',
          amountPaise: 1200000,
          intervalDays: 30,
          nextExpectedDate: DateTime(2026, 11, 1),
          status: RecurringStatus.confirmed,
          lastSeenAt: DateTime(2026, 10, 1),
          confidence: 1.0,
          paymentMethod: 'UPI • Landlord',
        ),
        RecurringPattern(
          id: 4,
          merchant: 'Gym',
          amountPaise: 150000,
          intervalDays: 30,
          nextExpectedDate: DateTime(2026, 11, 8),
          status: RecurringStatus.confirmed,
          lastSeenAt: DateTime(2026, 10, 8),
          confidence: 1.0,
          paymentMethod: 'Fitness auto-pay',
        ),
        RecurringPattern(
          id: 5,
          merchant: 'HDFC Car EMI',
          amountPaise: 825000,
          intervalDays: 30,
          nextExpectedDate: DateTime(2026, 11, 10),
          status: RecurringStatus.confirmed,
          lastSeenAt: DateTime(2026, 10, 10),
          confidence: 1.0,
          paymentMethod: 'ACH Mandate',
        ),
      ],
    );
  }

  @override
  Future<List<GeneratedInsight>> getInsights() async {
    return [
      GeneratedInsight(
        type: 'spending_change',
        message: 'You spent 20% more on Food this month.',
        generatedAt: DateTime(2026, 10, 31),
        actionLabel: 'View food expenses →',
        actionRoute: '/search?category=Food%20%26%20Dining',
      ),
      GeneratedInsight(
        type: 'budget_over',
        message: 'Shopping is over budget for October.',
        generatedAt: DateTime(2026, 10, 31),
        actionLabel: 'Adjust budget →',
        actionRoute: '/budget/form?category=Shopping',
      ),
      GeneratedInsight(
        type: 'recurring_due',
        message: '6 subscriptions renew in the next 12 days',
        generatedAt: DateTime(2026, 10, 31),
        actionLabel: 'View subscriptions →',
        actionRoute: '/insights/recurring',
      ),
    ];
  }

  @override
  Future<List<GeneratedInsight>> getGeneratedInsights({bool unreadOnly = false}) async => getInsights();

  @override
  Future<void> saveGeneratedInsights(Iterable<GeneratedInsight> insights) async {}

  @override
  Future<void> markInsightRead(int id) async {}

  @override
  Future<List<AlertItem>> getAlerts({String filter = 'all'}) async {
    if (filter == 'budgets' || filter == 'budget') {
      return _alerts.where((a) => a.type == AlertType.budget).toList();
    }
    if (filter == 'recurring') {
      return _alerts.where((a) => a.type == AlertType.recurring).toList();
    }
    if (filter == 'unusual') {
      return _alerts.where((a) => a.type == AlertType.unusual).toList();
    }
    return List.unmodifiable(_alerts);
  }

  @override
  Future<void> markAlertRead(int id) async {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAlertsRead() async {
    for (var i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].copyWith(isRead: true);
    }
  }

  @override
  Future<List<InsightTransaction>> searchTransactions({TransactionFilter? filter, String? query}) async {
    var result = List<InsightTransaction>.from(_transactions);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      result = result.where((t) =>
        t.merchant.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q) ||
        (t.subtitle?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (filter != null) {
      if (filter.categories.isNotEmpty) {
        result = result.where((t) => filter.categories.contains(t.category)).toList();
      }
      if (filter.accounts.isNotEmpty) {
        result = result.where((t) => t.account != null && filter.accounts.any((a) => t.account!.contains(a))).toList();
      }
      if (filter.merchants.isNotEmpty) {
        result = result.where((t) => filter.merchants.any((m) => t.merchant.toLowerCase().contains(m.toLowerCase()))).toList();
      }
      if (filter.transactionType != 'all') {
        final debitOnly = filter.transactionType == 'debit';
        result = result.where((t) => t.isDebit == debitOnly).toList();
      }
    }
    return result;
  }

  @override
  Future<int> currentCashBalancePaise() async => 5840000; // ₹58,400
}
