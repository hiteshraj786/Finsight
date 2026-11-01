import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/category_icon_tile.dart';
import '../widgets/gradient_hero_card.dart';
import '../widgets/status_chip.dart';
import 'budget_form_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  bool _loading = true;
  List<BudgetEvaluation> _budgets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getBudgetEvaluations();
    if (mounted) {
      setState(() {
        _budgets = data;
        _loading = false;
      });
    }
  }

  int get _totalBudgetPaise =>
      _budgets.fold<int>(0, (sum, b) => sum + b.budget.limitAmountPaise);

  int get _totalUsedPaise =>
      _budgets.fold<int>(0, (sum, b) => sum + b.actualPaise);

  int get _totalLeftPaise =>
      (_totalBudgetPaise - _totalUsedPaise).clamp(0, double.infinity).toInt();

  double get _overallProgress =>
      _totalBudgetPaise == 0 ? 0.0 : (_totalUsedPaise / _totalBudgetPaise);

  @override
  Widget build(BuildContext context) {
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
          'Budgets',
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
          : RefreshIndicator(
              color: const Color(0xFF7F3DFF),
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Monthly budget left Hero Card
                    _buildHeroCard(),
                    const SizedBox(height: 16),

                    // Daily safe spend banner
                    _buildSafeDailyBanner(),
                    const SizedBox(height: 28),

                    // Category budgets section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Category budgets',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212325),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F1FA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_budgets.length} active',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF91919F),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Filter ⎘',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7F3DFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Budgets List
                    if (_budgets.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Text(
                            'No category budgets set yet. Tap below to create your first budget!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF91919F)),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _budgets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildBudgetCard(_budgets[index]);
                        },
                      ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetFormScreen()),
              );
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Create budget',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F3DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final pct = (_overallProgress * 100).round();

    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Monthly budget left',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCAC12),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pacing fast · $pct% spent',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatPaise(_totalLeftPaise),
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'of ${CurrencyFormatter.formatPaise(_totalBudgetPaise)} total · 11 days to go',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          // White progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: _overallProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatPaise(_totalUsedPaise)} used',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${CurrencyFormatter.formatPaise(_totalBudgetPaise)} limit',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafeDailyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEEE5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_outlined, color: Color(0xFF7F3DFF), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF212325)),
                children: [
                  const TextSpan(text: 'Daily safe spend is '),
                  TextSpan(
                    text: '₹320/day',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF7F3DFF)),
                  ),
                  const TextSpan(text: ' to last month-end.'),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF7F3DFF), size: 20),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetEvaluation item) {
    StatusChipKind kind;
    String statusLabel;
    Color barColor;

    switch (item.status) {
      case BudgetStatus.onTrack:
        kind = StatusChipKind.onTrack;
        statusLabel = 'On track';
        barColor = const Color(0xFF00A86B);
        break;
      case BudgetStatus.nearLimit:
        kind = StatusChipKind.nearLimit;
        statusLabel = 'Near limit';
        barColor = const Color(0xFFFCAC12);
        break;
      case BudgetStatus.over:
        kind = StatusChipKind.overBudget;
        statusLabel = 'Over budget';
        barColor = const Color(0xFFFD3C4A);
        break;
    }

    final pct = (item.progress * 100).round();

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BudgetFormScreen(budget: item.budget),
          ),
        );
        if (result == true) _loadData();
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F1FA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CategoryIconTile(category: item.budget.categoryId, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.budget.categoryId,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212325),
                        ),
                      ),
                      Text(
                        'Monthly budget',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ],
                  ),
                ),
                StatusChip(label: statusLabel, kind: kind),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF212325)),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.formatPaise(item.actualPaise),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' of ${CurrencyFormatter.formatPaise(item.budget.limitAmountPaise)}',
                          style: GoogleFonts.inter(color: const Color(0xFF91919F)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F1FA),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
