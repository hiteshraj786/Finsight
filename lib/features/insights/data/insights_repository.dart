import '../domain/models.dart';

typedef MerchantSpend = MerchantStat;

/// The UI and scheduled jobs depend on this interface, never directly on Drift.
abstract class InsightsRepository {
  // Existing core methods
  Future<List<InsightTransaction>> confirmedTransactions({DateTime? from, DateTime? to});
  Future<List<CategorySpend>> categorySpend(DateTime from, DateTime to);
  Future<List<MerchantSpend>> topMerchants(DateTime from, DateTime to, {int limit = 10});

  // UI-oriented methods
  Future<List<CategorySpend>> getCategorySpend({String period = 'month', DateTime? date});
  Future<List<BudgetEvaluation>> getBudgetEvaluations();
  Future<List<Budget>> getBudgets();
  Future<int> saveBudget(Budget budget);

  Future<List<RecurringPattern>> getRecurring();
  Future<List<RecurringPattern>> getRecurringPatterns();
  Future<void> saveDetectedPatterns(Iterable<RecurringPattern> patterns);
  Future<void> setRecurringStatus(int id, RecurringStatus status);
  Future<void> confirmRecurring(int id);
  Future<void> ignoreRecurring(int id);

  Future<List<SavingsGoalEvaluation>> getSavingsGoalEvaluations();
  Future<List<SavingsGoal>> getSavingsGoals();
  Future<int> saveSavingsGoal(SavingsGoal goal);
  Future<int> addGoal(SavingsGoal goal);
  Future<void> addMoneyToGoal(int id, int amountPaise);

  Future<List<UnusualFlag>> getUnusual();
  Future<List<UnusualFlag>> getUnusualFlags({UnusualStatus status = UnusualStatus.open});
  Future<void> saveUnusualFlags(Iterable<UnusualFlag> flags);
  Future<void> setUnusualStatus(int id, UnusualStatus status);
  Future<void> dismissUnusual(int id);

  Future<List<MerchantStat>> getTopMerchants({String period = 'month', String sortBy = 'amount'});
  Future<CashflowForecast> getCashflow();

  Future<List<GeneratedInsight>> getInsights();
  Future<List<GeneratedInsight>> getGeneratedInsights({bool unreadOnly = false});
  Future<void> saveGeneratedInsights(Iterable<GeneratedInsight> insights);
  Future<void> markInsightRead(int id);

  Future<List<AlertItem>> getAlerts({String filter = 'all'});
  Future<void> markAlertRead(int id);
  Future<void> markAllAlertsRead();

  Future<List<InsightTransaction>> searchTransactions({TransactionFilter? filter, String? query});

  /// Cash is only active savings/current account balances; credit limits are
  /// intentionally excluded from this number.
  Future<int> currentCashBalancePaise();
}
