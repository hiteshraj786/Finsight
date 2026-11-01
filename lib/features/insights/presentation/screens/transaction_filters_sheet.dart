import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/category_colors.dart';
import '../../domain/models.dart';

class TransactionFiltersSheet extends StatefulWidget {
  final TransactionFilter initialFilter;

  const TransactionFiltersSheet({
    super.key,
    required this.initialFilter,
  });

  @override
  State<TransactionFiltersSheet> createState() => _TransactionFiltersSheetState();
}

class _TransactionFiltersSheetState extends State<TransactionFiltersSheet> {
  late String _dateRange;
  late Set<String> _categories;
  late Set<String> _accounts;
  late Set<String> _merchants;
  late String _transactionType;
  final TextEditingController _merchantInputCtrl = TextEditingController();

  final List<String> _allCategories = const [
    'Food & Dining',
    'Shopping',
    'Bills & Utilities',
    'Transport',
    'Entertainment',
    'Health',
  ];

  final List<String> _allAccounts = const [
    'SBI ••4821',
    'HDFC ••1190',
    'ICICI ••3082',
  ];

  @override
  void initState() {
    super.initState();
    _dateRange = widget.initialFilter.dateRange;
    _categories = Set.from(widget.initialFilter.categories);
    _accounts = Set.from(widget.initialFilter.accounts);
    _merchants = Set.from(widget.initialFilter.merchants);
    _transactionType = widget.initialFilter.transactionType;
  }

  @override
  void dispose() {
    _merchantInputCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _dateRange = '30days';
      _categories.clear();
      _accounts.clear();
      _merchants.clear();
      _transactionType = 'debit';
      _merchantInputCtrl.clear();
    });
  }

  TransactionFilter _buildFilter() {
    return TransactionFilter(
      dateRange: _dateRange,
      categories: _categories,
      accounts: _accounts,
      merchants: _merchants,
      transactionType: _transactionType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212325),
                    ),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Text(
                      'Reset',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7F3DFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Date Range
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date range',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                      ),
                      Text(
                        _dateRange == 'today'
                            ? 'Today'
                            : (_dateRange == '7days' ? 'Last 7 days' : 'Last 30 days'),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _datePill('Today', 'today'),
                        const SizedBox(width: 8),
                        _datePill('7 days', '7days'),
                        const SizedBox(width: 8),
                        _datePill('30 days', '30days'),
                        const SizedBox(width: 8),
                        _datePill('Custom', 'custom', icon: Icons.calendar_today_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Category Multi-Select
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category (MULTI-SELECT)',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF91919F), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allCategories.map((cat) {
                      final selected = _categories.contains(cat);
                      final icon = CategoryColors.iconForCategory(cat);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _categories.remove(cat);
                            } else {
                              _categories.add(cat);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF7F3DFF) : const Color(0xFFF1F1FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF7F3DFF)),
                              const SizedBox(width: 6),
                              Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? Colors.white : const Color(0xFF212325),
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check, size: 14, color: Colors.white),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Accounts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allAccounts.map((acc) {
                      final selected = _accounts.contains(acc);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _accounts.remove(acc);
                            } else {
                              _accounts.add(acc);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF7F3DFF) : const Color(0xFFF1F1FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_outlined, size: 14, color: selected ? Colors.white : const Color(0xFF7F3DFF)),
                              const SizedBox(width: 6),
                              Text(
                                acc,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected ? Colors.white : const Color(0xFF212325),
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.check, size: 14, color: Colors.white),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Merchant Search & Selected Tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merchant',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1FA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 18, color: Color(0xFF91919F)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _merchantInputCtrl,
                            onSubmitted: (val) {
                              final trimmed = val.trim();
                              if (trimmed.isNotEmpty) {
                                setState(() {
                                  _merchants.add(trimmed);
                                  _merchantInputCtrl.clear();
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search merchant...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_merchants.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _merchants.map((m) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                m,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7F3DFF),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _merchants.remove(m)),
                                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF7F3DFF)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Transaction Type (All | Debit | Credit)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Type',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1FA),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        _typePill('All', 'all'),
                        _typePill('Debit', 'debit'),
                        _typePill('Credit', 'credit'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Bottom Actions (Reset & Show Results)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFEEE5FF),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7F3DFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _buildFilter());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7F3DFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Show 18 results',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePill(String label, String value, {IconData? icon}) {
    final selected = _dateRange == value;
    return GestureDetector(
      onTap: () => setState(() => _dateRange = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7F3DFF) : const Color(0xFFF1F1FA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF212325)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF212325),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typePill(String label, String value) {
    final selected = _transactionType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _transactionType = value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7F3DFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF91919F),
            ),
          ),
        ),
      ),
    );
  }
}
