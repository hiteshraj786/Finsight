import '../../models/parsed_transaction.dart';
import '../../models/payment_method.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';

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
  specificMonth('Month');

  final String label;
  const PeriodFilter(this.label);

  static const choices = [
    allTime,
    thisMonth,
    lastMonth,
    last3Months,
    thisYear,
  ];

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

class AccountFilterOption {
  final String last4;
  final String? bankName;

  const AccountFilterOption({required this.last4, this.bankName});

  String get label => '${bankName ?? 'A/c'} ••$last4';
}

class TransactionFilter {
  final TypeFilter type;
  final Set<String> categories;
  final Set<PaymentMethod> methods;
  final Set<String> accounts;
  final Set<TransactionStatus> statuses;
  final PeriodFilter period;
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

  int get activeCount =>
      (type == TypeFilter.all ? 0 : 1) +
      categories.length +
      methods.length +
      accounts.length +
      statuses.length +
      (period == PeriodFilter.allTime ? 0 : 1);

  bool get hasFilters => activeCount > 0;

  String get periodLabel {
    if (period != PeriodFilter.specificMonth || month == null) {
      return period.label;
    }
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month!.month - 1]} ${month!.year}';
  }

  DateTime? shownMonth(DateTime now) => switch (period) {
    PeriodFilter.thisMonth => DateTime(now.year, now.month),
    PeriodFilter.lastMonth => DateTime(now.year, now.month - 1),
    PeriodFilter.specificMonth => month,
    _ => null,
  };

  TransactionFilter copyWith({
    TypeFilter? type,
    Set<String>? categories,
    Set<PaymentMethod>? methods,
    Set<String>? accounts,
    Set<TransactionStatus>? statuses,
    PeriodFilter? period,
    DateTime? month,
    SortOrder? sort,
  }) {
    final nextPeriod = period ?? this.period;
    return TransactionFilter(
      type: type ?? this.type,
      categories: categories ?? this.categories,
      methods: methods ?? this.methods,
      accounts: accounts ?? this.accounts,
      statuses: statuses ?? this.statuses,
      period: nextPeriod,
      month: nextPeriod == PeriodFilter.specificMonth ? month ?? this.month : null,
      sort: sort ?? this.sort,
    );
  }

  TransactionFilter cleared() => TransactionFilter(sort: sort);

  bool matches(
    ParsedTransaction transaction, {
    DateTime? now,
    bool ignorePeriod = false,
  }) {
    if (type == TypeFilter.expense &&
        transaction.type != TransactionType.debit) {
      return false;
    }
    if (type == TypeFilter.income &&
        transaction.type != TransactionType.credit) {
      return false;
    }
    if (categories.isNotEmpty &&
        !categories.any(
          (category) =>
              category.toLowerCase() == transaction.category.toLowerCase(),
        )) {
      return false;
    }
    if (methods.isNotEmpty && !methods.contains(transaction.paymentMethod)) {
      return false;
    }
    if (accounts.isNotEmpty &&
        !accounts.contains(transaction.accountLast4)) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(transaction.status)) {
      return false;
    }
    if (!ignorePeriod) {
      final range = period.range(now ?? DateTime.now(), month: month);
      if (range != null &&
          (transaction.date.isBefore(range.$1) ||
              !transaction.date.isBefore(range.$2))) {
        return false;
      }
    }
    return true;
  }

  List<ParsedTransaction> apply(
    List<ParsedTransaction> transactions, {
    DateTime? now,
  }) {
    final result =
        transactions.where((tx) => matches(tx, now: now)).toList();
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
