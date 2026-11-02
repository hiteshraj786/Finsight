import 'package:flutter/material.dart';

import '../../../../core/widgets/bank_logo.dart';
import '../filters/transaction_filter.dart';
import '../../models/payment_method.dart';
import '../../models/transaction_status.dart';
import '../theme/app_theme.dart';
import 'category_widgets.dart';
import 'payment_method_widgets.dart';

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
        heightFactor: 0.88,
        child: TransactionFilterSheet(initial: initial, accounts: accounts),
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _draft = widget.initial;

  Set<T> _toggle<T>(Set<T> values, T value) {
    final next = {...values};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context) => Column(
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
            _section(
              'Type',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final type in TypeFilter.values)
                    _chip(
                      type.label,
                      selected: _draft.type == type,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(type: type),
                      ),
                    ),
                ],
              ),
            ),
            _section(
              'Period',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    _draft.period == PeriodFilter.specificMonth
                        ? _draft.periodLabel
                        : 'Specific month',
                    selected: _draft.period == PeriodFilter.specificMonth,
                    onTap: _pickMonth,
                  ),
                  for (final period in PeriodFilter.choices)
                    _chip(
                      period.label,
                      selected: _draft.period == period,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(period: period),
                      ),
                    ),
                ],
              ),
            ),
            _section(
              'Paid by',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in PaymentMethod.values)
                    _chip(
                      method.label,
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
              _section(
                'Bank account',
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final account in widget.accounts)
                      _chip(
                        account.label,
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
            _section(
              'Category',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in CategoryMeta.validCategories)
                    _chip(
                      category,
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
            _section(
              'Status',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in TransactionStatus.values)
                    _chip(
                      switch (status) {
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
            _section(
              'Sort by',
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sort in SortOrder.values)
                    _chip(
                      sort.label,
                      selected: _draft.sort == sort,
                      onTap: () => setState(
                        () => _draft = _draft.copyWith(sort: sort),
                      ),
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
            child: const Text('Show results'),
          ),
        ),
      ),
    ],
  );

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
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

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.month ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
      helpText: 'Choose transaction month',
    );
    if (!mounted || picked == null) return;
    setState(
      () => _draft = _draft.copyWith(
        period: PeriodFilter.specificMonth,
        month: DateTime(picked.year, picked.month),
      ),
    );
  }

  Widget _chip(
    String label, {
    IconData? icon,
    Widget? avatar,
    required bool selected,
    required VoidCallback onTap,
  }) {
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
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: color,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
