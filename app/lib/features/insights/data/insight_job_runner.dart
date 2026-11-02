import '../../../core/constants/app_routes.dart';
import '../domain/engines.dart';
import '../domain/models.dart';
import '../domain/currency_formatter.dart';
import 'insight_notification_service.dart';
import 'insights_repository.dart';

/// Idempotent on-device aggregation entry point shared by foreground refreshes
/// and the Workmanager isolate. It deliberately has no network dependency.
class InsightJobRunner {
  final InsightsRepository repository;
  final Clock clock;

  const InsightJobRunner({required this.repository, required this.clock});

  Future<List<GeneratedInsight>> runDaily() async {
    final all = await repository.confirmedTransactions();
    final patterns = await repository.getRecurringPatterns();
    final existingFlags = (await repository.getUnusualFlags()).map((flag) => flag.txnId).toSet();
    final detected = RecurringDetector(clock: clock).detect(all, existing: patterns);
    await repository.saveDetectedPatterns(detected);
    final flags = AnomalyDetector(clock: clock).detect(all);
    await repository.saveUnusualFlags(flags);
    for (final flag in flags.where((flag) => !existingFlags.contains(flag.txnId))) {
      await InsightNotificationService.show(
        id: 500000 + flag.txnId,
        title: 'Unusual transaction',
        body: flag.reason,
        route: AppRoutes.insightsUnusual,
      );
    }
    final generated = await _generate(all);
    final tomorrow = DateTime(clock().year, clock().month, clock().day + 1);
    for (final pattern in await repository.getRecurringPatterns()) {
      if (pattern.status != RecurringStatus.ignored &&
          DateTime(pattern.nextExpectedDate.year, pattern.nextExpectedDate.month, pattern.nextExpectedDate.day) == tomorrow) {
        await InsightNotificationService.show(
          id: 600000 + (pattern.id ?? pattern.merchant.hashCode).abs(),
          title: 'Payment due tomorrow',
          body: '${pattern.merchant} · ${CurrencyFormatter.formatPaise(pattern.amountPaise)}',
          route: AppRoutes.insightsRecurring,
        );
      }
    }
    return generated;
  }

  Future<List<GeneratedInsight>> runPeriodicInsights() async => _generate(
    await repository.confirmedTransactions(),
  );

  Future<List<GeneratedInsight>> _generate(List<InsightTransaction> all) async {
    final now = clock();
    final budgets = await repository.getBudgets();
    final evaluations = [for (final budget in budgets) BudgetEngine(clock: clock).evaluate(budget, all)];
    final start = DateTime(now.year, now.month);
    final previousStart = DateTime(now.year, now.month - 1);
    final current = await repository.categorySpend(start, DateTime(now.year, now.month + 1));
    final previous = await repository.categorySpend(previousStart, start);
    final generated = InsightGenerator(clock: clock).generate(
      budgets: evaluations,
      recurring: await repository.getRecurringPatterns(),
      currentCategorySpend: {for (final item in current) item.category: item.amountPaise},
      previousCategorySpend: {for (final item in previous) item.category: item.amountPaise},
    );
    final prior = (await repository.getGeneratedInsights()).map((item) => '${item.type}:${item.message}').toSet();
    await repository.saveGeneratedInsights(generated);
    for (final insight in generated.where((item) => !prior.contains('${item.type}:${item.message}'))) {
      final budget = evaluations.where((evaluation) =>
        insight.message.startsWith(evaluation.budget.categoryId)).firstOrNull;
      if (insight.type == 'budget_over' && budget != null && !budget.budget.notifyOnOver) continue;
      await InsightNotificationService.show(
        id: insight.message.hashCode.abs(),
        title: insight.type.startsWith('budget') ? 'Budget alert' : 'FinSight insight',
        body: insight.message,
        route: insight.type.startsWith('budget') ? AppRoutes.budget : AppRoutes.insights,
      );
    }
    return generated;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
