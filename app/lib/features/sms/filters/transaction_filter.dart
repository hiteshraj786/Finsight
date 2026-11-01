import '../../../data/models/parsed_transaction.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/transaction_status.dart';
import '../../../data/models/transaction_type.dart';

enum TypeFilter {
  all('All'),
  expense('Expenses'),
  income('Income');

  final String label;
  const TypeFilter(this.label);
}

enum PeriodFilter {
  allTime('All time'),
  thisMonth('This month'),
  lastMonth('Last month'),
  last3Months('Last 3 months'),
  thisYear('This year'),

  /// One calendar month, set by [TransactionFilter.month].
  specificMonth('Month');

  final String label;
  const PeriodFilter(this.label);

  /// Periods offered as choices in the filter sheet.
  static const choices = [allTime, thisMonth, lastMonth, last3Months, thisYear];

  /// Start (inclusive) and end (exclusive) of the period, or null for all time.
  /// [month] is only used by [specificMonth].
  (DateTime, DateTime)? range(DateTime now, {DateTime? month}) => switch (this) {
    PeriodFilter.allTime => null,
    PeriodFilter.specificMonth => month == null
        ? null
        : (
            DateTime(month.year, month.month),
            DateTime(month.year, month.month + 1),
          ),
    PeriodFilter.thisMonth => (
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1),
    ),
    PeriodFilter.lastMonth => (
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month),
    ),
    PeriodFilter.last3Months => (
      DateTime(now.year, now.month - 2),
      DateTime(now.year, now.month + 1),
    ),
    PeriodFilter.thisYear => (DateTime(now.year), DateTime(now.year + 1)),
  };
}

enum SortOrder {
  newest('Newest first'),
  oldest('Oldest first'),
  highest('Highest amount'),
  lowest('Lowest amount');

  final String label;
  const SortOrder(this.label);
}

/// What the transaction list shows. Empty sets mean "any".
class TransactionFilter {
  final TypeFilter type;
  final Set<String> categories;
  final Set<PaymentMethod> methods;

  /// Last 4 digits of the bank accounts or cards to show.
  final Set<String> accounts;
  final Set<TransactionStatus> statuses;
  final PeriodFilter period;

  /// First day of the month when [period] is [PeriodFilter.specificMonth].
  final DateTime? month;
  final SortOrder sort;

  const TransactionFilter({
    this.type = TypeFilter.all,
    this.categories = const {},
    this.methods = const {},
    this.accounts = const {},
    this.statuses = const {},
    this.period = PeriodFilter.allTime,
    this.month,
    this.sort = SortOrder.newest,
  });

  /// What the Activity tab opens with: this month's transactions.
  static const thisMonth = TransactionFilter(period: PeriodFilter.thisMonth);

  /// Shows exactly the calendar month starting at [month]. The current month
  /// is stored as [PeriodFilter.thisMonth] so it keeps meaning "this month".
  TransactionFilter forMonth(DateTime month, DateTime now) {
    final isCurrent = month.year == now.year && month.month == now.month;
    return TransactionFilter(
      type: type,
      categories: categories,
      methods: methods,
      accounts: accounts,
      statuses: statuses,
      period: isCurrent ? PeriodFilter.thisMonth : PeriodFilter.specificMonth,
      month: isCurrent ? null : DateTime(month.year, month.month),
      sort: sort,
    );
  }

  /// The single month this filter shows, or null for longer periods.
  DateTime? shownMonth(DateTime now) => switch (period) {
    PeriodFilter.thisMonth => DateTime(now.year, now.month),
    PeriodFilter.lastMonth => DateTime(now.year, now.month - 1),
    PeriodFilter.specificMonth => month,
    _ => null,
  };

  String get periodLabel {
    final m = month;
    if (period != PeriodFilter.specificMonth || m == null) return period.label;
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];
    return '${names[m.month - 1]} ${m.year}';
  }

  /// Number of active filters, for the badge on the Filter button. Sorting
  /// is not a filter and is not counted.
  int get activeCount =>
      (type == TypeFilter.all ? 0 : 1) +
      categories.length +
      methods.length +
      accounts.length +
      statuses.length +
      (period == PeriodFilter.allTime ? 0 : 1);

  bool get hasFilters => activeCount > 0;

  TransactionFilter copyWith({
    TypeFilter? type,
    Set<String>? categories,
    Set<PaymentMethod>? methods,
    Set<String>? accounts,
    Set<TransactionStatus>? statuses,
    PeriodFilter? period,
    SortOrder? sort,
  }) => TransactionFilter(
    type: type ?? this.type,
    categories: categories ?? this.categories,
    methods: methods ?? this.methods,
    accounts: accounts ?? this.accounts,
    statuses: statuses ?? this.statuses,
    period: period ?? this.period,
    // A month only belongs to the specificMonth period.
    month: (period ?? this.period) == PeriodFilter.specificMonth ? month : null,
    sort: sort ?? this.sort,
  );

  /// Clears every filter but keeps the sort order.
  TransactionFilter cleared() => TransactionFilter(sort: sort);

  bool matches(ParsedTransaction t, {DateTime? now, bool ignorePeriod = false}) {
    if (type == TypeFilter.expense && t.type != TransactionType.debit) {
      return false;
    }
    if (type == TypeFilter.income && t.type != TransactionType.credit) {
      return false;
    }
    if (categories.isNotEmpty &&
        !categories.any((c) => c.toLowerCase() == t.category.toLowerCase())) {
      return false;
    }
    if (methods.isNotEmpty && !methods.contains(t.paymentMethod)) return false;
    if (accounts.isNotEmpty && !accounts.contains(t.accountLast4)) return false;
    if (statuses.isNotEmpty && !statuses.contains(t.status)) return false;
    if (!ignorePeriod) {
      final range = period.range(now ?? DateTime.now(), month: month);
      if (range != null &&
          (t.date.isBefore(range.$1) || !t.date.isBefore(range.$2))) {
        return false;
      }
    }
    return true;
  }

  List<ParsedTransaction> apply(List<ParsedTransaction> all, {DateTime? now}) {
    final result = all.where((t) => matches(t, now: now)).toList();
    switch (sort) {
      case SortOrder.newest:
        result.sort((a, b) => b.date.compareTo(a.date));
      case SortOrder.oldest:
        result.sort((a, b) => a.date.compareTo(b.date));
      case SortOrder.highest:
        result.sort((a, b) => b.amountPaise.compareTo(a.amountPaise));
      case SortOrder.lowest:
        result.sort((a, b) => a.amountPaise.compareTo(b.amountPaise));
    }
    return result;
  }
}

/// A bank account or card offered in the filter, identified by the last 4
/// digits that bank SMS mention.
class AccountFilterOption {
  final String last4;

  /// Bank of a saved account with the same last 4 digits, if any.
  final String? bankName;

  const AccountFilterOption({required this.last4, this.bankName});

  String get label => '${bankName ?? 'A/c'} ••$last4';
}
