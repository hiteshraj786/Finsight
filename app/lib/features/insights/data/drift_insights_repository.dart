import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/services/finance_data_service.dart';
import '../../sms/data/database.dart' as local;
import '../../sms/models/transaction_status.dart';
import '../../sms/models/transaction_type.dart';
import '../domain/engines.dart';
import '../domain/models.dart';
import 'insights_repository.dart';

/// SQL-backed implementation. The Phase 2 tables are deliberately accessed by
/// SQL so they can be added without regenerating Phase 1's Drift data classes.
class DriftInsightsRepository implements InsightsRepository {
  final local.AppDatabase _db;
  final Future<List<FinanceAccount>> Function() _accounts;
  DriftInsightsRepository({local.AppDatabase? database, Future<List<FinanceAccount>> Function()? accountsLoader})
      : _db = database ?? local.AppDatabase(), _accounts = accountsLoader ?? FinanceDataService.getCachedAccounts;

  @override
  Future<List<InsightTransaction>> confirmedTransactions({DateTime? from, DateTime? to}) async {
    final query = _db.select(_db.transactions)..where((t) => t.status.equals(TransactionStatus.confirmed.name));
    if (from != null) query.where((t) => t.date.isBiggerOrEqualValue(from.toUtc()));
    if (to != null) query.where((t) => t.date.isSmallerThanValue(to.toUtc()));
    return (await query.get()).map((row) => InsightTransaction(
      id: row.id, amountPaise: row.amountPaise, isDebit: row.type == TransactionType.debit.name,
      merchant: row.party, normalizedMerchant: row.normalizedParty.isEmpty ? normalizeMerchant(row.party) : row.normalizedParty,
      category: row.category, occurredAt: row.date.toLocal(),
    )).toList();
  }

  @override
  Future<List<CategorySpend>> categorySpend(DateTime from, DateTime to) => _aggregate(
    'category', 'category', from, to).then((rows) => rows.map((row) => CategorySpend(
      category: row.$1,
      amountPaise: row.$2,
      transactionCount: row.$3,
    )).toList());

  @override
  Future<List<MerchantSpend>> topMerchants(DateTime from, DateTime to, {int limit = 10}) async {
    final rows = await _db.customSelect('''SELECT party AS label, SUM(amount_paise) AS total, COUNT(*) AS count
      FROM transactions WHERE status=? AND type=? AND date>=? AND date<?
      GROUP BY normalized_party, party ORDER BY total DESC LIMIT ?''', variables: [
      Variable.withString('confirmed'), Variable.withString('debit'), Variable.withDateTime(from.toUtc()),
      Variable.withDateTime(to.toUtc()), Variable.withInt(limit),
    ]).get();
    var rank = 1;
    final totalSpend = rows.fold<int>(0, (sum, r) => sum + r.read<int>('total'));
    return rows.map((row) {
      final total = row.read<int>('total');
      final count = row.read<int>('count');
      return MerchantStat(
        rank: rank++,
        merchant: row.read<String>('label'),
        amountPaise: total,
        transactionCount: count,
        avgAmountPaise: count > 0 ? (total ~/ count) : 0,
        relativeShare: totalSpend > 0 ? (total / totalSpend) : 0.0,
      );
    }).toList();
  }

  Future<List<(String, int, int)>> _aggregate(String select, String group, DateTime from, DateTime to) async {
    final rows = await _db.customSelect('''SELECT $select AS label, SUM(amount_paise) AS total, COUNT(*) AS count
      FROM transactions WHERE status=? AND type=? AND date>=? AND date<?
      GROUP BY $group ORDER BY total DESC''', variables: [
      Variable.withString('confirmed'), Variable.withString('debit'), Variable.withDateTime(from.toUtc()), Variable.withDateTime(to.toUtc()),
    ]).get();
    return rows.map((row) => (row.read<String>('label'), row.read<int>('total'), row.read<int>('count'))).toList();
  }

  @override
  Future<List<Budget>> getBudgets() async {
    return (await _rows('SELECT * FROM budgets')).map((r) => Budget(
      id: r.read<int>('id'), categoryId: r.read<String>('category_id'), limitAmountPaise: r.read<int>('limit_amount'),
      period: BudgetPeriod.values.byName(r.read<String>('period')), alertThreshold: r.read<double>('alert_threshold'),
      notifyOnOver: (r.data['notify_on_over'] == 1 || r.data['notify_on_over'] == true), createdAt: _date(r, 'created_at'),
    )).toList();
  }

  @override
  Future<int> saveBudget(Budget value) => value.id == null
      ? _db.customInsert('INSERT INTO budgets (category_id,limit_amount,period,alert_threshold,notify_on_over,created_at) VALUES (?,?,?,?,?,?)',
          variables: [_s(value.categoryId), _i(value.limitAmountPaise), _s(value.period.name), _d(value.alertThreshold), _b(value.notifyOnOver), _time(value.createdAt)])
      : _db.customUpdate('UPDATE budgets SET category_id=?,limit_amount=?,period=?,alert_threshold=?,notify_on_over=?,created_at=? WHERE id=?',
          variables: [_s(value.categoryId), _i(value.limitAmountPaise), _s(value.period.name), _d(value.alertThreshold), _b(value.notifyOnOver), _time(value.createdAt), _i(value.id!)]);

  @override
  Future<List<RecurringPattern>> getRecurringPatterns() async => (await _rows('SELECT * FROM recurring_patterns')).map((r) => RecurringPattern(
    id: r.read<int>('id'), merchant: r.read<String>('merchant'), amountPaise: r.read<int>('amount'), intervalDays: r.read<int>('interval_days'),
    nextExpectedDate: _date(r, 'next_expected_date'), status: RecurringStatus.values.byName(r.read<String>('status')),
    lastSeenAt: _date(r, 'last_seen_at'), confidence: r.read<double>('confidence'),
  )).toList();

  @override
  Future<void> saveDetectedPatterns(Iterable<RecurringPattern> patterns) async {
    for (final value in patterns) {
      final found = await _rows('SELECT id,status FROM recurring_patterns WHERE merchant=? AND amount=?', [_s(value.merchant), _i(value.amountPaise)]);
      if (found.isNotEmpty && found.single.read<String>('status') != 'detected') continue;
      final args = [_s(value.merchant), _i(value.amountPaise), _i(value.intervalDays), _time(value.nextExpectedDate), _s(value.status.name), _time(value.lastSeenAt), _d(value.confidence)];
      if (found.isEmpty) {
        await _db.customInsert('INSERT INTO recurring_patterns (merchant,amount,interval_days,next_expected_date,status,last_seen_at,confidence) VALUES (?,?,?,?,?,?,?)', variables: args);
      } else {
        await _db.customUpdate('UPDATE recurring_patterns SET merchant=?,amount=?,interval_days=?,next_expected_date=?,status=?,last_seen_at=?,confidence=? WHERE id=?', variables: [...args, _i(found.single.read<int>('id'))]);
      }
    }
  }

  @override
  Future<void> setRecurringStatus(int id, RecurringStatus status) => _db.customUpdate('UPDATE recurring_patterns SET status=? WHERE id=?', variables: [_s(status.name), _i(id)]);

  @override
  Future<List<SavingsGoal>> getSavingsGoals() async {
    return (await _rows('SELECT * FROM savings_goals')).map((r) => SavingsGoal(
      id: r.read<int>('id'), name: r.read<String>('name'), targetAmountPaise: r.read<int>('target_amount'), savedAmountPaise: r.read<int>('saved_amount'),
      targetDate: _date(r, 'target_date'), createdAt: _date(r, 'created_at'),
    )).toList();
  }

  @override
  Future<int> saveSavingsGoal(SavingsGoal value) => value.id == null
      ? _db.customInsert('INSERT INTO savings_goals (name,target_amount,saved_amount,target_date,created_at) VALUES (?,?,?,?,?)', variables: [_s(value.name), _i(value.targetAmountPaise), _i(value.savedAmountPaise), _time(value.targetDate), _time(value.createdAt)])
      : _db.customUpdate('UPDATE savings_goals SET name=?,target_amount=?,saved_amount=?,target_date=?,created_at=? WHERE id=?', variables: [_s(value.name), _i(value.targetAmountPaise), _i(value.savedAmountPaise), _time(value.targetDate), _time(value.createdAt), _i(value.id!)]);

  @override
  Future<void> addMoneyToGoal(int id, int amountPaise) => _db.customUpdate('UPDATE savings_goals SET saved_amount=saved_amount+? WHERE id=?', variables: [_i(amountPaise), _i(id)]);

  @override
  Future<List<UnusualFlag>> getUnusualFlags({UnusualStatus status = UnusualStatus.open}) async => (await _rows('SELECT * FROM unusual_flags WHERE status=?', [_s(status.name)])).map((r) => UnusualFlag(
    id: r.read<int>('id'), txnId: r.read<int>('txn_id'), reason: r.read<String>('reason'), status: UnusualStatus.values.byName(r.read<String>('status')), createdAt: _date(r, 'created_at'),
  )).toList();

  @override
  Future<void> saveUnusualFlags(Iterable<UnusualFlag> flags) async { for (final flag in flags) { if ((await _rows('SELECT id FROM unusual_flags WHERE txn_id=?', [_i(flag.txnId)])).isEmpty) await _db.customInsert('INSERT INTO unusual_flags (txn_id,reason,status,created_at) VALUES (?,?,?,?)', variables: [_i(flag.txnId), _s(flag.reason), _s(flag.status.name), _time(flag.createdAt)]); } }
  @override
  Future<void> setUnusualStatus(int id, UnusualStatus status) => _db.customUpdate('UPDATE unusual_flags SET status=? WHERE id=?', variables: [_s(status.name), _i(id)]);

  @override
  Future<List<GeneratedInsight>> getGeneratedInsights({bool unreadOnly = false}) async => (await _rows('SELECT * FROM insights${unreadOnly ? ' WHERE is_read=0' : ''} ORDER BY generated_at DESC')).map((r) => GeneratedInsight(
    id: r.read<int>('id'),
    type: r.read<String>('type'), message: r.read<String>('message'), generatedAt: _date(r, 'generated_at'),
    relatedTransactionIds: (jsonDecode(r.read<String>('related_txn_ids')) as List).whereType<num>().map((n) => n.toInt()).toList(),
    isRead: r.data['is_read'] == 1 || r.data['is_read'] == true,
  )).toList();

  @override
  Future<void> saveGeneratedInsights(Iterable<GeneratedInsight> values) async { for (final value in values) { if ((await _rows('SELECT id FROM insights WHERE type=? AND message=?', [_s(value.type), _s(value.message)])).isEmpty) await _db.customInsert('INSERT INTO insights (type,message,generated_at,related_txn_ids,is_read) VALUES (?,?,?,?,0)', variables: [_s(value.type), _s(value.message), _time(value.generatedAt), _s(value.relatedTransactionIdsJson)]); } }
  @override
  Future<void> markInsightRead(int id) => _db.customUpdate('UPDATE insights SET is_read=1 WHERE id=?', variables: [_i(id)]);

  @override
  Future<List<RecurringPattern>> getRecurring() async {
    var list = await getRecurringPatterns();
    if (list.isEmpty) {
      final txns = await confirmedTransactions();
      final detected = RecurringDetector(clock: DateTime.now).detect(txns);
      if (detected.isNotEmpty) {
        await saveDetectedPatterns(detected);
        list = await getRecurringPatterns();
      }
    }
    return list;
  }

  @override
  Future<void> confirmRecurring(int id) => setRecurringStatus(id, RecurringStatus.confirmed);

  @override
  Future<void> ignoreRecurring(int id) => setRecurringStatus(id, RecurringStatus.ignored);

  @override
  Future<int> addGoal(SavingsGoal goal) => saveSavingsGoal(goal);

  @override
  Future<List<UnusualFlag>> getUnusual() async {
    var flags = await getUnusualFlags();
    if (flags.isEmpty) {
      final txns = await confirmedTransactions();
      final detected = AnomalyDetector(clock: DateTime.now).detect(txns);
      if (detected.isNotEmpty) {
        await saveUnusualFlags(detected);
        flags = await getUnusualFlags();
      }
    }
    return flags;
  }

  @override
  Future<void> dismissUnusual(int id) => setUnusualStatus(id, UnusualStatus.dismissed);

  @override
  Future<List<GeneratedInsight>> getInsights() async {
    var list = await getGeneratedInsights();
    if (list.isEmpty) {
      final budgetEvals = await getBudgetEvaluations();
      final recurring = await getRecurringPatterns();
      final now = DateTime.now();
      final currentSpends = await categorySpend(DateTime(now.year, now.month), DateTime(now.year, now.month + 1));
      final prevSpends = await categorySpend(DateTime(now.year, now.month - 1), DateTime(now.year, now.month));
      final generated = InsightGenerator(clock: DateTime.now).generate(
        budgets: budgetEvals,
        recurring: recurring,
        currentCategorySpend: {for (final c in currentSpends) c.category: c.amountPaise},
        previousCategorySpend: {for (final p in prevSpends) p.category: p.amountPaise},
      );
      if (generated.isNotEmpty) {
        await saveGeneratedInsights(generated);
        list = await getGeneratedInsights();
      }
    }
    return list;
  }

  @override
  Future<List<BudgetEvaluation>> getBudgetEvaluations() async {
    final budgets = await getBudgets();
    final txns = await confirmedTransactions();
    return [for (final b in budgets) BudgetEngine(clock: DateTime.now).evaluate(b, txns)];
  }

  @override
  Future<List<SavingsGoalEvaluation>> getSavingsGoalEvaluations() async {
    final goals = await getSavingsGoals();
    return [for (final g in goals) SavingsGoalEngine(clock: DateTime.now).evaluate(g, 0)];
  }

  @override
  Future<List<CategorySpend>> getCategorySpend({String period = 'month', DateTime? date}) async {
    final selected = date ?? DateTime.now();
    final (start, end) = _periodRange(period, selected);
    final (previousStart, previousEnd) = _previousPeriodRange(period, selected);
    final current = await categorySpend(start, end);
    final previous = await categorySpend(previousStart, previousEnd);
    final prevMap = {for (final p in previous) p.category: p.amountPaise};
    final total = current.fold<int>(0, (sum, c) => sum + c.amountPaise);
    return current.map((c) {
      final prev = prevMap[c.category];
      final change = prev != null && prev > 0 ? ((c.amountPaise - prev) / prev * 100) : null;
      final share = total > 0 ? (c.amountPaise / total * 100) : 0.0;
      return CategorySpend(
        category: c.category,
        amountPaise: c.amountPaise,
        transactionCount: c.transactionCount,
        sharePercentage: share,
        previousAmountPaise: prev,
        percentageChange: change,
      );
    }).toList();
  }

  @override
  Future<CashflowForecast> getCashflow() async {
    final cash = await currentCashBalancePaise();
    final patterns = await getRecurringPatterns();
    final history = await confirmedTransactions();
    return CashflowProjector(clock: DateTime.now).project(
      currentBalancePaise: cash,
      recurring: patterns,
      history: history,
      windowDays: 30,
    );
  }

  @override
  Future<List<AlertItem>> getAlerts({String filter = 'all'}) async {
    final list = await getGeneratedInsights();
    final alerts = list.map((g) => AlertItem(
      id: g.id ?? g.message.hashCode.abs(),
      type: g.type.startsWith('budget')
          ? AlertType.budget
          : (g.type.startsWith('recurring')
              ? AlertType.recurring
              : (g.type.startsWith('unusual')
                  ? AlertType.unusual
                  : (g.type.startsWith('goal') ? AlertType.goal : AlertType.trend))),
      title: g.message,
      subtitle: 'FinSight insight',
      timeAgo: 'Recently',
      isRead: g.isRead,
    )).toList();

    if (alerts.isEmpty) {
      alerts.add(const AlertItem(
        id: 1,
        type: AlertType.trend,
        title: 'FinSight smart detection is active',
        subtitle: 'Monitoring incoming bank SMS for budgets & recurring bills',
        timeAgo: 'Just now',
      ));
    }

    final normalizedFilter = filter == 'budgets' ? 'budget' : filter;
    if (normalizedFilter == 'all') return alerts;
    return alerts.where((a) => a.type.name == normalizedFilter).toList();
  }

  @override
  Future<void> markAlertRead(int id) async {
    await _db.customUpdate(
      'UPDATE insights SET is_read=1 WHERE id=?',
      variables: [_i(id)],
    );
  }

  @override
  Future<void> markAllAlertsRead() async {
    await _db.customUpdate('UPDATE insights SET is_read=1');
  }

  @override
  Future<List<InsightTransaction>> searchTransactions({TransactionFilter? filter, String? query}) async {
    DateTime? from;
    DateTime? to;
    if (filter != null) {
      final now = DateTime.now();
      switch (filter.dateRange) {
        case 'today':
          from = DateTime(now.year, now.month, now.day);
          to = from.add(const Duration(days: 1));
          break;
        case '7days':
          from = now.subtract(const Duration(days: 7));
          to = now;
          break;
        case '30days':
          from = now.subtract(const Duration(days: 30));
          to = now;
          break;
        case 'custom':
          from = filter.customStart;
          to = filter.customEnd;
          break;
      }
    }

    var list = await confirmedTransactions(from: from, to: to);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      list = list.where((t) =>
        t.merchant.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q) ||
        (t.subtitle?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    if (filter != null) {
      if (filter.categories.isNotEmpty) {
        list = list.where((t) => filter.categories.contains(t.category)).toList();
      }
      if (filter.merchants.isNotEmpty) {
        list = list.where((t) => filter.merchants.contains(t.merchant)).toList();
      }
      if (filter.accounts.isNotEmpty) {
        list = list.where((t) => t.account != null && filter.accounts.contains(t.account)).toList();
      }
      if (filter.transactionType == 'debit') {
        list = list.where((t) => t.isDebit).toList();
      } else if (filter.transactionType == 'credit') {
        list = list.where((t) => !t.isDebit).toList();
      }
    }
    return list;
  }

  @override
  Future<int> currentCashBalancePaise() async {
    final accounts = await _accounts();
    final depositAccounts = accounts.where((a) => a.isDepositAccount);
    final totalRupees = depositAccounts.fold<double>(0.0, (sum, a) => sum + (a.latestBalance ?? 0.0));
    return (totalRupees * 100).round();
  }

  @override
  Future<List<MerchantStat>> getTopMerchants({String period = 'month', String sortBy = 'amount'}) async {
    final (from, to) = _periodRange(period, DateTime.now());
    final merchants = await topMerchants(from, to, limit: 20);
    if (sortBy == 'count') {
      merchants.sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    } else {
      merchants.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
    }
    return merchants;
  }

  Future<List<QueryRow>> _rows(String sql, [List<Variable> variables = const []]) => _db.customSelect(sql, variables: variables).get();

  DateTime _date(QueryRow row, String column) {
    final val = row.data[column];
    if (val is int) {
      if (val < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(val * 1000, isUtc: true).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true).toLocal();
    } else if (val is String) {
      return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
    } else if (val is DateTime) {
      return val.toLocal();
    }
    return DateTime.now();
  }

  Variable<String> _s(String value) => Variable.withString(value);
  Variable<int> _i(int value) => Variable.withInt(value);
  Variable<double> _d(double value) => Variable.withReal(value);
  Variable<int> _b(bool value) => Variable.withInt(value ? 1 : 0);
  Variable<int> _time(DateTime value) => Variable.withInt(value.toUtc().millisecondsSinceEpoch);

  (DateTime, DateTime) _periodRange(String period, DateTime selected) {
    final day = DateTime(selected.year, selected.month, selected.day);
    switch (period.toLowerCase()) {
      case 'week':
        final start = day.subtract(Duration(days: day.weekday - 1));
        return (start, start.add(const Duration(days: 7)));
      case 'year':
        return (DateTime(day.year), DateTime(day.year + 1));
      case 'month':
      default:
        return (DateTime(day.year, day.month), DateTime(day.year, day.month + 1));
    }
  }

  (DateTime, DateTime) _previousPeriodRange(String period, DateTime selected) {
    final day = DateTime(selected.year, selected.month, selected.day);
    switch (period.toLowerCase()) {
      case 'week':
        final currentStart = day.subtract(Duration(days: day.weekday - 1));
        return (currentStart.subtract(const Duration(days: 7)), currentStart);
      case 'year':
        return (DateTime(day.year - 1), DateTime(day.year));
      case 'month':
      default:
        return (DateTime(day.year, day.month - 1), DateTime(day.year, day.month));
    }
  }
}
