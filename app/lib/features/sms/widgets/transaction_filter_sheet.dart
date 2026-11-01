import 'package:flutter/material.dart';

import '../../../core/widgets/bank_logo.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/transaction_status.dart';
import '../filters/transaction_filter.dart';
import '../theme/sms_theme.dart';
import 'category_widgets.dart';
import 'payment_method_widgets.dart';

/// Bottom sheet for editing a [TransactionFilter]. Returns the new filter
/// when the user taps "Show results", or null if dismissed.
class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilter initial;
  final List<AccountFilterOption> accounts;

  const TransactionFilterSheet({
    super.key,
    required this.initial,
    this.accounts = const [],
  });

  static Future<TransactionFilter?> show(
    BuildContext context,
    TransactionFilter initial, {
    List<AccountFilterOption> accounts = const [],
  }) {
    return showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Theme(
          data: AppTheme.current,
          child: TransactionFilterSheet(initial: initial, accounts: accounts),
        ),
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _draft = widget.initial;

  Set<T> _toggle<T>(Set<T> set, T value) {
    final next = {...set};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Filter transactions',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _draft.hasFilters
                    ? () => setState(() => _draft = _draft.cleared())
                    : null,
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              _Section(
                title: 'Type',
                child: _ChipWrap(
                  children: [
                    for (final type in TypeFilter.values)
                      _FilterChip(
                        label: type.label,
                        selected: _draft.type == type,
                        onTap: () =>
                            setState(() => _draft = _draft.copyWith(type: type)),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Period',
                child: _ChipWrap(
                  children: [
                    if (_draft.period == PeriodFilter.specificMonth)
                      _FilterChip(
                        label: _draft.periodLabel,
                        selected: true,
                        onTap: () {},
                      ),
                    for (final period in PeriodFilter.choices)
                      _FilterChip(
                        label: period.label,
                        selected: _draft.period == period,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(period: period),
                        ),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Paid by',
                child: _ChipWrap(
                  children: [
                    for (final method in PaymentMethod.values)
                      _FilterChip(
                        label: method.label,
                        icon: method.icon,
                        selected: _draft.methods.contains(method),
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(
                            methods: _toggle(_draft.methods, method),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.accounts.isNotEmpty)
                _Section(
                  title: 'Bank account',
                  child: _ChipWrap(
                    children: [
                      for (final account in widget.accounts)
                        _FilterChip(
                          label: account.label,
                          avatar: BankLogo(
                            providerName: account.bankName,
                            size: 20,
                            fallbackIcon: Icons.credit_card_rounded,
                          ),
                          selected: _draft.accounts.contains(account.last4),
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              accounts: _toggle(_draft.accounts, account.last4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              _Section(
                title: 'Category',
                child: _ChipWrap(
                  children: [
                    for (final category in CategoryMeta.validCategories)
                      _FilterChip(
                        label: category,
                        icon: CategoryMeta.getIcon(category),
                        selected: _draft.categories.contains(category),
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(
                            categories: _toggle(_draft.categories, category),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Status',
                child: _ChipWrap(
                  children: [
                    for (final status in TransactionStatus.values)
                      _FilterChip(
                        label: switch (status) {
                          TransactionStatus.pending => 'To review',
                          TransactionStatus.confirmed => 'Confirmed',
                          TransactionStatus.ignored => 'Ignored',
                        },
                        selected: _draft.statuses.contains(status),
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(
                            statuses: _toggle(_draft.statuses, status),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _Section(
                title: 'Sort by',
                child: _ChipWrap(
                  children: [
                    for (final sort in SortOrder.values)
                      _FilterChip(
                        label: sort.label,
                        selected: _draft.sort == sort,
                        onTap: () =>
                            setState(() => _draft = _draft.copyWith(sort: sort)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _draft),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Show results'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _ChipWrap extends StatelessWidget {
  final List<Widget> children;
  const _ChipWrap({required this.children});

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  /// Shown instead of [icon], e.g. a bank logo.
  final Widget? avatar;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return FilterChip(
      avatar: avatar ?? (icon == null ? null : Icon(icon, size: 16, color: color)),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.primaryContainer,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: selected ? Colors.transparent : AppColors.borderLight,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
