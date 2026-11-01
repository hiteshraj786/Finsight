import 'package:flutter/material.dart';
import '../../data/transaction_repository.dart';
import '../../models/parsed_transaction.dart';
import '../../models/transaction_status.dart';
import '../../models/transaction_type.dart';
import '../../utils/currency_formatter.dart';
import '../theme/app_theme.dart';
import '../widgets/category_widgets.dart';
import '../widgets/finsight_app_bar.dart';
import '../widgets/stat_counter.dart';
import '../widgets/transaction_card.dart';
import 'transaction_detail_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  final TransactionRepository repository;
  final VoidCallback onAddManual;

  const TransactionsScreen({
    super.key,
    required this.repository,
    required this.onAddManual,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedCategory;

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
      const months = [
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
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FinSightAppBar(
        title: 'Transactions',
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
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
          final now = DateTime.now();

          // Calculate "This month" totals (confirmed only, not ignored)
          int spentPaise = 0;
          int incomePaise = 0;

          for (final t in all) {
            if (t.status == TransactionStatus.ignored) continue;
            if (t.date.year == now.year && t.date.month == now.month) {
              if (t.type == TransactionType.debit) {
                spentPaise += t.amountPaise;
              } else {
                incomePaise += t.amountPaise;
              }
            }
          }

          final netPaise = incomePaise - spentPaise;
          final netPrefix = netPaise >= 0 ? '+' : '-';
          final netAbs = netPaise.abs();

          // Filter by category if selected
          final filtered = all.where((t) {
            if (_selectedCategory == null) return true;
            return t.category.toLowerCase() == _selectedCategory!.toLowerCase();
          }).toList();

          // Group by date
          final Map<String, List<ParsedTransaction>> grouped = {};
          for (final tx in filtered) {
            final header = _getDateHeader(tx.date);
            grouped.putIfAbsent(header, () => []).add(tx);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              // Summary card for "This month"
              Container(
                padding: const EdgeInsets.all(18),
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
                    const Text(
                      'This month',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: StatCounter(
                            label: 'Spent',
                            value: '₹${formatIndianRupees(spentPaise)}',
                            valueColor: AppColors.debit,
                          ),
                        ),
                        Container(width: 1, height: 36, color: AppColors.border),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: StatCounter(
                              label: 'Income',
                              value: '₹${formatIndianRupees(incomePaise)}',
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
                              value: '$netPrefix₹${formatIndianRupees(netAbs)}',
                              valueColor: netPaise >= 0
                                  ? AppColors.credit
                                  : AppColors.debit,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Category filter chips (All + 8)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoryChip(
                      category: 'All',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    ...CategoryMeta.validCategories.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: CategoryChip(
                          category: c,
                          isSelected: _selectedCategory == c,
                          showIcon: true,
                          onTap: () => setState(() => _selectedCategory = c),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Empty or Grouped List
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: const Text(
                    'No transactions in this category.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      ...entry.value.map((tx) {
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
                      }),
                      const SizedBox(height: 4),
                    ],
                  );
                }),
              const SizedBox(height: 72), // Clearance for bottom nav
            ],
          );
        },
      ),
    );
  }
}

