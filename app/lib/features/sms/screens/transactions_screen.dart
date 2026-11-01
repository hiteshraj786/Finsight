import 'package:flutter/material.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/parsed_transaction.dart';
import '../../../data/models/transaction_status.dart';
import '../../../data/models/transaction_type.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/backend/finance_data_service.dart';
import '../filters/transaction_filter.dart';
import '../theme/sms_theme.dart';
import '../widgets/finsight_app_bar.dart';
import '../widgets/payment_method_widgets.dart';
import '../widgets/stat_counter.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_filter_sheet.dart';
import 'transaction_detail_sheet.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class TransactionsScreen extends StatefulWidget {
  final TransactionRepository repository;
  final VoidCallback onAddManual;
  final String title;

  /// App bar actions. Defaults to a single "add manually" button.
  final List<Widget>? actions;

  /// Shown above the summary card, e.g. a "to review" banner.
  final Widget? header;
  final TransactionFilter initialFilter;

  const TransactionsScreen({
    super.key,
    required this.repository,
    required this.onAddManual,
    this.title = 'Transactions',
    this.actions,
    this.header,
    this.initialFilter = const TransactionFilter(),
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late TransactionFilter _filter = widget.initialFilter;

  /// Bank name of each saved account, keyed by its last 4 digits.
  Map<String, String> _bankByLast4 = const {};

  /// Accounts seen in the latest transactions, most used first.
  List<AccountFilterOption> _accountOptions = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedAccounts();
  }

  Future<void> _loadSavedAccounts() async {
    try {
      final accounts = await FinanceDataService.getCachedAccounts();
      final byLast4 = <String, String>{};
      for (final account in accounts) {
        final digits = account.maskedAccountNumber.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 4) {
          byLast4[digits.substring(digits.length - 4)] = account.providerName;
        }
      }
      if (mounted) setState(() => _bankByLast4 = byLast4);
    } catch (_) {
      // Names are optional; options still show the last 4 digits.
    }
  }

  List<AccountFilterOption> _accountsIn(List<ParsedTransaction> all) {
    final counts = <String, int>{};
    for (final t in all) {
      final last4 = t.accountLast4;
      if (last4 != null && last4.isNotEmpty) {
        counts[last4] = (counts[last4] ?? 0) + 1;
      }
    }
    final ordered = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return [
      for (final last4 in ordered)
        AccountFilterOption(last4: last4, bankName: _bankByLast4[last4]),
    ];
  }

  /// Month the summary card shows when the list covers a longer period.
  DateTime _independentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  /// First day of the month shown in the summary card. When the list shows a
  /// single month, the card follows it.
  DateTime get _summaryMonth =>
      _filter.shownMonth(DateTime.now()) ?? _independentMonth;

  /// Moves the summary card, and the list if it shows a single month.
  void _goToMonth(DateTime month) {
    setState(() {
      if (_filter.shownMonth(DateTime.now()) != null) {
        _filter = _filter.forMonth(month, DateTime.now());
      } else {
        _independentMonth = month;
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (_isSameDay(itemDate, today)) {
      return 'Today';
    } else if (_isSameDay(itemDate, yesterday)) {
      return 'Yesterday';
    } else {
      final month = _monthNames[dt.month - 1].substring(0, 3);
      return '${dt.day.toString().padLeft(2, '0')} $month ${dt.year}';
    }
  }

  bool _inMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  Future<void> _openFilters() async {
    final result = await TransactionFilterSheet.show(
      context,
      _filter,
      accounts: _accountOptions,
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    AppColors.rebuildOnThemeChange(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FinSightAppBar(
        title: widget.title,
        actions: widget.actions ?? [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            tooltip: 'Add manually',
            onPressed: widget.onAddManual,
          ),
        ],
      ),
      body: StreamBuilder<List<ParsedTransaction>>(
        stream: widget.repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data ?? [];
          _accountOptions = _accountsIn(all);
          final filtered = _filter.apply(all);

          // Flatten into header + card rows so the list can build lazily.
          final groupByDay =
              _filter.sort == SortOrder.newest ||
              _filter.sort == SortOrder.oldest;
          final rows = <Object>[];
          String? lastHeader;
          for (final tx in filtered) {
            if (groupByDay) {
              final header = _getDateHeader(tx.date);
              if (header != lastHeader) {
                rows.add(header);
                lastHeader = header;
              }
            }
            rows.add(tx);
          }

          final top = <Widget>[
            ?widget.header,
            _buildSummaryCard(all),
            const SizedBox(height: 14),
            _buildFilterBar(filtered.length),
            if (_filter.hasFilters) ...[
              const SizedBox(height: 10),
              _buildActiveFilterChips(),
            ],
            const SizedBox(height: 8),
            if (filtered.isEmpty) _buildEmptyResults(all.isEmpty),
          ];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: top.length + rows.length,
            itemBuilder: (context, index) {
              if (index < top.length) return top[index];
              final row = rows[index - top.length];
              if (row is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Text(
                    row,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              final tx = row as ParsedTransaction;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TransactionCard(
                  transaction: tx,
                  showActions: false,
                  onTap: () {
                    TransactionDetailSheet.show(
                      context,
                      transaction: tx,
                      repository: widget.repository,
                      onSaved: () => setState(() {}),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Spent / income / net for [_summaryMonth]. Respects the active filters
  /// (except the period, which the month switcher replaces) and leaves out
  /// ignored transactions.
  Widget _buildSummaryCard(List<ParsedTransaction> all) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final isCurrentMonth = _summaryMonth == currentMonth;

    int spentPaise = 0;
    int incomePaise = 0;
    int count = 0;
    for (final t in all) {
      if (t.status == TransactionStatus.ignored) continue;
      if (!_inMonth(t.date, _summaryMonth)) continue;
      if (!_filter.matches(t, ignorePeriod: true)) continue;
      count++;
      if (t.type == TransactionType.debit) {
        spentPaise += t.amountPaise;
      } else {
        incomePaise += t.amountPaise;
      }
    }
    final netPaise = incomePaise - spentPaise;
    final netPrefix = netPaise >= 0 ? '+' : '-';

    final previousMonth = DateTime(_summaryMonth.year, _summaryMonth.month - 1);
    final previousHasData = all.any(
      (t) =>
          t.status != TransactionStatus.ignored &&
          _inMonth(t.date, previousMonth),
    );
    final monthLabel =
        '${_monthNames[_summaryMonth.month - 1]} ${_summaryMonth.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A7F3DFF),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _goToMonth(previousMonth),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      isCurrentMonth ? 'This month' : monthLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentMonth || _filter.hasFilters)
                      Text(
                        [
                          if (isCurrentMonth) monthLabel,
                          if (_filter.hasFilters) 'filtered',
                        ].join(' · '),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: isCurrentMonth
                    ? null
                    : () => _goToMonth(
                        DateTime(_summaryMonth.year, _summaryMonth.month + 1),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: StatCounter(
                    label: 'Spent',
                    value: formatIndianRupees(spentPaise),
                    valueColor: AppColors.debit,
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: StatCounter(
                      label: 'Income',
                      value: formatIndianRupees(incomePaise),
                      valueColor: AppColors.credit,
                      indicatorColor: AppColors.credit,
                    ),
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: StatCounter(
                      label: 'Net',
                      value: '$netPrefix${formatIndianRupees(netPaise.abs())}',
                      valueColor: netPaise >= 0
                          ? AppColors.credit
                          : AppColors.debit,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (count == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'No transactions in $monthLabel yet.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (previousHasData)
                    TextButton(
                      onPressed: () => _goToMonth(previousMonth),
                      child: Text(
                        'See ${_monthNames[previousMonth.month - 1]}',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(int resultCount) {
    final active = _filter.activeCount;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text(active == 0 ? 'Filter' : 'Filter · $active'),
          style: OutlinedButton.styleFrom(
            foregroundColor: active == 0
                ? AppColors.textPrimary
                : AppColors.primary,
            backgroundColor: active == 0
                ? AppColors.surface
                : AppColors.primaryContainer,
            side: BorderSide(
              color: active == 0 ? AppColors.borderLight : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<SortOrder>(
          tooltip: 'Sort',
          initialValue: _filter.sort,
          onSelected: (sort) =>
              setState(() => _filter = _filter.copyWith(sort: sort)),
          itemBuilder: (_) => [
            for (final sort in SortOrder.values)
              PopupMenuItem(value: sort, child: Text(sort.label)),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _filter.sort.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          '$resultCount',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// One removable chip per active filter, plus "Clear all".
  Widget _buildActiveFilterChips() {
    final f = _filter;
    final chips = <Widget>[
      if (f.type != TypeFilter.all)
        _activeChip(
          f.type.label,
          () => _filter = f.copyWith(type: TypeFilter.all),
        ),
      if (f.period != PeriodFilter.allTime)
        _activeChip(
          f.periodLabel,
          () => _filter = f.copyWith(period: PeriodFilter.allTime),
        ),
      for (final method in f.methods)
        _activeChip(
          method.label,
          () => _filter = f.copyWith(methods: {...f.methods}..remove(method)),
          icon: method.icon,
        ),
      for (final last4 in f.accounts)
        _activeChip(
          AccountFilterOption(
            last4: last4,
            bankName: _bankByLast4[last4],
          ).label,
          () => _filter = f.copyWith(accounts: {...f.accounts}..remove(last4)),
          icon: Icons.account_balance_rounded,
        ),
      for (final category in f.categories)
        _activeChip(
          category,
          () => _filter = f.copyWith(
            categories: {...f.categories}..remove(category),
          ),
        ),
      for (final status in f.statuses)
        _activeChip(
          switch (status) {
            TransactionStatus.pending => 'To review',
            TransactionStatus.confirmed => 'Confirmed',
            TransactionStatus.ignored => 'Ignored',
          },
          () => _filter = f.copyWith(statuses: {...f.statuses}..remove(status)),
        ),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...chips,
        TextButton(
          onPressed: () => setState(() => _filter = _filter.cleared()),
          child: const Text('Clear all'),
        ),
      ],
    );
  }

  Widget _activeChip(String label, VoidCallback remove, {IconData? icon}) {
    return InputChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 14, color: AppColors.primary),
      label: Text(label),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      backgroundColor: AppColors.primaryContainer,
      side: BorderSide.none,
      deleteIconColor: AppColors.primary,
      onDeleted: () => setState(remove),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyResults(bool noTransactionsAtAll) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            noTransactionsAtAll
                ? 'No transactions yet.'
                : 'No transactions match these filters.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (!noTransactionsAtAll && _filter.hasFilters)
            TextButton(
              onPressed: () => setState(() => _filter = _filter.cleared()),
              child: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }
}
