import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/gradient_hero_card.dart';
import '../widgets/merchant_avatar.dart';
import 'cashflow_screen.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  bool _loading = true;
  String _selectedFilter = 'all'; // 'all', 'needs_review', 'auto_debited'
  List<RecurringPattern> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getRecurring();
    if (mounted) {
      setState(() {
        _items = data;
        _loading = false;
      });
    }
  }

  int get _totalCommittedPaise =>
      _items.where((i) => i.status != RecurringStatus.ignored).fold<int>(0, (sum, i) => sum + i.amountPaise);

  List<RecurringPattern> get _filteredItems {
    if (_selectedFilter == 'needs_review') {
      return _items.where((i) => i.status == RecurringStatus.detected).toList();
    }
    if (_selectedFilter == 'auto_debited') {
      return _items.where((i) => i.status == RecurringStatus.confirmed).toList();
    }
    return _items.where((i) => i.status != RecurringStatus.ignored).toList();
  }

  @override
  Widget build(BuildContext context) {
    final needsReviewCount = _items.where((i) => i.status == RecurringStatus.detected).length;
    final autoDebitedCount = _items.where((i) => i.status == RecurringStatus.confirmed).length;

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
          'Recurring Payments',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7F3DFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Card
                  GradientHeroCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Committed every month',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'November 2026',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              CurrencyFormatter.formatPaise(_totalCommittedPaise),
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '/ month',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                '${_items.length} recurring payments detected',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // View cashflow forecast link (Section 3 rule)
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CashflowScreen()),
                        );
                      },
                      icon: const Icon(Icons.trending_down_rounded, size: 16, color: Color(0xFF7F3DFF)),
                      label: Text(
                        'View cashflow forecast',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7F3DFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All (${_items.length})', 'all'),
                        const SizedBox(width: 10),
                        _filterChip('Needs Review', 'needs_review', badgeCount: needsReviewCount),
                        const SizedBox(width: 10),
                        _filterChip('Auto-Debited ($autoDebitedCount)', 'auto_debited'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Coming up',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212325),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE5FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_filteredItems.length} Due',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7F3DFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Nov 1 – Nov 12',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // List of items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final item = _filteredItems[i];
                      return _buildRecurringItemCard(item);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEE5FF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEE5FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded, color: Color(0xFF7F3DFF), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Smart Recurring Detection',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212325),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'FinSight detects repeats by matching merchant, amount and timing across your bank SMS.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF91919F),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom manual add
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Auto-scanning reads all bank mandates automatically')),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF7F3DFF)),
                      label: Text(
                        'Add recurring payment manually',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7F3DFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _filterChip(String label, String value, {int badgeCount = 0}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEE5FF) : const Color(0xFFF1F1FA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7F3DFF) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF7F3DFF) : const Color(0xFF212325),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF7F3DFF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringItemCard(RecurringPattern item) {
    final dayNum = item.nextExpectedDate.day.toString();
    final isNeedsReview = item.status == RecurringStatus.detected;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNeedsReview ? const Color(0xFF7F3DFF) : const Color(0xFFF1F1FA),
          width: isNeedsReview ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              // Date box (e.g. 1 NOV)
              Container(
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEE5FF)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNum,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF212325),
                      ),
                    ),
                    Text(
                      'NOV',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7F3DFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Merchant avatar (initials)
              MerchantAvatar(name: item.merchant, size: 42),
              const SizedBox(width: 12),
              // Merchant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.merchant,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212325),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF7F3DFF)),
                        if (isNeedsReview) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEE5FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Detected',
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF7F3DFF)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1FA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Monthly',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF91919F)),
                          ),
                        ),
                        if (item.paymentMethod != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            item.paymentMethod!,
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF91919F)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatPaise(item.amountPaise),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF212325),
                    ),
                  ),
                  Text(
                    isNeedsReview ? 'Review' : 'Due in 2d',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isNeedsReview ? FontWeight.w700 : FontWeight.w500,
                      color: isNeedsReview ? const Color(0xFF7F3DFF) : const Color(0xFF91919F),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Needs Review expanded block
          if (isNeedsReview) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEE5FF)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pattern matched', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F))),
                      Text(item.patternDescription ?? '3rd of every month', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF212325))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last debited', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F))),
                      Text('${CurrencyFormatter.formatPaise(item.amountPaise)} on 3 Oct 2026', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF212325))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF7F3DFF)),
                      const SizedBox(width: 6),
                      Text('Auto-detected recurring subscription', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF7F3DFF))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (item.id != null) {
                        await _repo.ignoreRecurring(item.id!);
                        _loadData();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEE5FF),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      '✕ Not recurring',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF7F3DFF)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (item.id != null) {
                        await _repo.confirmRecurring(item.id!);
                        _loadData();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F3DFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      '✓ Confirm',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
