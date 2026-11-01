import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/insights_repository_provider.dart';
import '../../domain/category_colors.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import 'transaction_filters_sheet.dart';

class TransactionSearchScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialMerchant;

  const TransactionSearchScreen({
    super.key,
    this.initialCategory,
    this.initialMerchant,
  });

  @override
  State<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends State<TransactionSearchScreen> {
  final _repo = InsightsRepositoryProvider.current;
  final TextEditingController _queryCtrl = TextEditingController();

  late TransactionFilter _filter;
  bool _loading = true;
  List<InsightTransaction> _results = [];

  @override
  void initState() {
    super.initState();
    _filter = TransactionFilter(
      categories: widget.initialCategory != null ? {widget.initialCategory!} : {},
      merchants: widget.initialMerchant != null ? {widget.initialMerchant!} : {},
    );
    if (widget.initialCategory != null) {
      _queryCtrl.text = widget.initialCategory!;
    } else if (widget.initialMerchant != null) {
      _queryCtrl.text = widget.initialMerchant!;
    }
    _search();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final data = await _repo.searchTransactions(
      filter: _filter,
      query: _queryCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _results = data;
        _loading = false;
      });
    }
  }

  void _openFilters() async {
    final updated = await showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFiltersSheet(initialFilter: _filter),
    );
    if (updated != null) {
      setState(() => _filter = updated);
      _search();
    }
  }

  int get _totalSpendPaise =>
      _results.where((t) => t.isDebit).fold<int>(0, (sum, t) => sum + t.amountPaise);

  Map<String, List<InsightTransaction>> get _groupedResults {
    final map = <String, List<InsightTransaction>>{};
    final now = DateTime.now();
    for (final t in _results) {
      final d = t.occurredAt;
      final String group;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        group = 'TODAY';
      } else if (d.year == now.year && d.month == now.month && d.day == now.day - 1) {
        group = 'YESTERDAY';
      } else {
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        group = '${d.day} ${months[d.month - 1]} ${d.year}';
      }
      map.putIfAbsent(group, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filterCount = _filter.activeFilterCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF212325)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 20, color: Color(0xFF91919F)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _queryCtrl,
                            onChanged: (_) => _search(),
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF212325)),
                            decoration: const InputDecoration(
                              hintText: 'Search transactions...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_queryCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _queryCtrl.clear();
                              _search();
                            },
                            child: const Icon(Icons.cancel, size: 16, color: Color(0xFF91919F)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onTap: _openFilters,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEE5FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFF7F3DFF), size: 22),
                      ),
                    ),
                    if (filterCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7F3DFF),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filterCount.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active Removable Filter Chips
          if (!_filter.isDefault || _filter.categories.isNotEmpty || _filter.merchants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_filter.dateRange != '30days')
                      _activeFilterChip(_filter.dateRange, () {
                        setState(() => _filter = _filter.copyWith(dateRange: '30days'));
                        _search();
                      }),
                    ..._filter.categories.map((c) => _activeFilterChip(c, () {
                      final updated = Set<String>.from(_filter.categories)..remove(c);
                      setState(() => _filter = _filter.copyWith(categories: updated));
                      _search();
                    })),
                    ..._filter.merchants.map((m) => _activeFilterChip(m, () {
                      final updated = Set<String>.from(_filter.merchants)..remove(m);
                      setState(() => _filter = _filter.copyWith(merchants: updated));
                      _search();
                    })),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filter = const TransactionFilter();
                          _queryCtrl.clear();
                        });
                        _search();
                      },
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Summary row: N transactions · ₹Amount | Filtered view
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFFAFAFD),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_results.length} transactions · ${CurrencyFormatter.formatPaise(_totalSpendPaise)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212325),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF7F3DFF)),
                    const SizedBox(width: 4),
                    Text(
                      'Filtered view',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7F3DFF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transaction Timeline List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F3DFF)))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF91919F)),
                            const SizedBox(height: 12),
                            Text(
                              'No matching transactions',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF212325)),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        children: [
                          for (final entry in _groupedResults.entries) ...[
                            _buildDateGroup(entry.key, entry.value),
                            const SizedBox(height: 18),
                          ],
                          const SizedBox(height: 24),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEEE5FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 14, color: Color(0xFF7F3DFF)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'All matching entries loaded',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF91919F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7F3DFF)),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF7F3DFF)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String title, List<InsightTransaction> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF91919F),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final t = items[i];
            final color = CategoryColors.forCategory(t.category);
            final icon = CategoryColors.iconForCategory(t.category);
            final isCredit = !t.isDebit;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F1FA)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isCredit
                          ? const Color(0xFFE6F7F0)
                          : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isCredit ? Icons.account_balance_wallet_outlined : icon,
                      color: isCredit ? const Color(0xFF00A86B) : color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.merchant,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212325),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${t.account ?? 'Account'} · ${t.subtitle ?? t.category}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF91919F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isCredit ? '+' : '-'}${CurrencyFormatter.formatPaise(t.amountPaise)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isCredit ? const Color(0xFF00A86B) : const Color(0xFF212325),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
