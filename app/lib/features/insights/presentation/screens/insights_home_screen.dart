import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/category_colors.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/custom_donut_chart.dart';
import '../widgets/gradient_hero_card.dart';
import '../widgets/month_switcher.dart';
import '../widgets/period_segmented_control.dart';
import '../widgets/sparkline_card_chart.dart';
import 'alerts_screen.dart';
import 'budgets_screen.dart';
import 'cashflow_screen.dart';
import 'category_analytics_screen.dart';
import 'budget_form_screen.dart';
import 'recurring_payments_screen.dart';
import 'savings_goals_screen.dart';
import 'top_merchants_screen.dart';
import 'transaction_search_screen.dart';

class InsightsHomeScreen extends StatefulWidget {
  const InsightsHomeScreen({super.key});

  @override
  State<InsightsHomeScreen> createState() => _InsightsHomeScreenState();
}

class _InsightsHomeScreenState extends State<InsightsHomeScreen> {
  final _repo = InsightsRepositoryProvider.current;
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool _loading = true;
  List<CategorySpend> _categorySpends = [];
  List<GeneratedInsight> _insights = [];
  List<BudgetEvaluation> _budgets = [];
  List<RecurringPattern> _recurring = [];
  List<AlertItem> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final spends = await _repo.getCategorySpend(period: _selectedPeriod, date: _selectedDate);
    final insights = await _repo.getInsights();
    final budgets = await _repo.getBudgetEvaluations();
    final recurring = await _repo.getRecurring();
    final alerts = await _repo.getAlerts();

    if (mounted) {
      setState(() {
        _categorySpends = spends;
        _insights = insights;
        _budgets = budgets;
        _recurring = recurring;
        _alerts = alerts;
        _loading = false;
      });
    }
  }

  int get _totalSpendPaise =>
      _categorySpends.fold<int>(0, (sum, item) => sum + item.amountPaise);

  double get _periodChange {
    final values = _categorySpends
        .map((item) => item.percentageChange)
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String get _foodInsightTitle {
    final item = _categorySpends
        .where((spend) => spend.category == 'Food & Dining')
        .firstOrNull;
    if (item == null || item.percentageChange == null) {
      return 'Spending by category'.tr();
    }
    final change = item.percentageChange!.abs().toStringAsFixed(0);
    final direction = item.percentageChange! >= 0 ? 'more'.tr() : 'less'.tr();
    return '${'You spent'.tr()} $change% $direction ${'on Food this period'.tr()}.';
  }

  int get _periodDays {
    if (_selectedPeriod == 'week') return 7;
    if (_selectedPeriod == 'year') {
      return DateTime(_selectedDate.year + 1)
          .difference(DateTime(_selectedDate.year))
          .inDays;
    }
    return DateUtils.getDaysInMonth(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final unreadAlerts = _alerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEEE5FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF7F3DFF), size: 24),
          ),
        ),
        title: Text(
          'Insights'.tr(),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF212325), size: 26),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AlertsScreen()),
                  );
                  _loadData();
                },
              ),
              if (unreadAlerts > 0)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFD3C4A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
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
                    // Period Segmented Control (Week | Month | Year)
                    PeriodSegmentedControl(
                      selected: _selectedPeriod,
                      onChanged: (p) {
                        setState(() => _selectedPeriod = p);
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 14),

                    // Month Switcher
                    MonthSwitcher(
                      selectedMonth: _selectedDate,
                      period: _selectedPeriod,
                      onMonthChanged: (d) {
                        setState(() => _selectedDate = d);
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 18),

                    // Hero Card: Total spent with trend sparkline
                    _buildHeroCard(),
                    const SizedBox(height: 28),

                    // Spending by Category Donut Section
                    _buildSpendingByCategorySection(),
                    const SizedBox(height: 28),

                    // Smart Insights Carousel
                    _buildSmartInsightsSection(),
                    const SizedBox(height: 28),

                    // Explore 2x2 Grid
                    _buildExploreSection(),
                    const SizedBox(height: 16),

                    // Cashflow Forecast Card (Section 3 addition)
                    _buildCashflowCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return GradientHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total spent'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${_periodChange.abs().toStringAsFixed(0)}% vs previous',
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
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatPaise(_totalSpendPaise),
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily pacing'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Text(
                'Avg ${CurrencyFormatter.formatPaise((_totalSpendPaise / _periodDays).round())}/day',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SparklineCardChart(),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Spending by category'.tr(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212325),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryAnalyticsScreen()),
                );
                _loadData();
              },
              child: Text(
                'Details >'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7F3DFF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F1FA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              CustomDonutChart(
                items: _categorySpends,
                size: 210,
                centerWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF91919F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(_totalSpendPaise),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF212325),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_periodDays days',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00A86B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Category rows
              ..._categorySpends.take(5).map((item) {
                final color = CategoryColors.forCategory(item.category);
                final icon = CategoryColors.iconForCategory(item.category);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212325),
                              ),
                            ),
                            Text(
                              '${item.sharePercentage.toStringAsFixed(1)}% of monthly spend',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF91919F),
                              ),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212325),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Smart insights'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212325),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF7F3DFF)),
              ],
            ),
            Text(
              '${_alerts.length} ${'alerts'.tr()}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF91919F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 136,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _smartInsightCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFFCAC12),
                iconBg: const Color(0xFFFFF7E6),
                title: _foodInsightTitle,
                actionText: 'View food expenses →'.tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionSearchScreen(
                        initialCategory: 'Food & Dining',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              _smartInsightCard(
                icon: Icons.trending_up_rounded,
                iconColor: const Color(0xFFFD3C4A),
                iconBg: const Color(0xFFFFECEF),
                title: '${'Shopping is over budget for'.tr()} '
                    '${DateFormat('MMMM').format(_selectedDate)}.',
                actionText: 'Adjust budget →'.tr(),
                onTap: () {
                  final shoppingBudget = _budgets.where(
                    (b) => b.budget.categoryId == 'Shopping',
                  ).firstOrNull ?? (_budgets.isNotEmpty ? _budgets.first : null);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetFormScreen(budget: shoppingBudget?.budget),
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              _smartInsightCard(
                icon: Icons.repeat_rounded,
                iconColor: const Color(0xFF7F3DFF),
                iconBg: const Color(0xFFEEE5FF),
                title: '${_recurring.length} ${'subscriptions renew soon'.tr()}.',
                actionText: 'View recurring →'.tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecurringPaymentsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smartInsightCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F1FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212325),
              height: 1.3,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7F3DFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore'.tr(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.2,
          children: [
            _exploreTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budgets'.tr(),
              subtitle: '${_budgets.length} ${'active'.tr()}',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                );
                _loadData();
              },
            ),
            _exploreTile(
              icon: Icons.repeat_rounded,
              title: 'Recurring'.tr(),
              subtitle: '${_recurring.length} ${'scheduled'.tr()}',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecurringPaymentsScreen()),
                );
                _loadData();
              },
            ),
            _exploreTile(
              icon: Icons.storefront_outlined,
              title: 'Merchants'.tr(),
              subtitle: 'Tap to view'.tr(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TopMerchantsScreen()),
                );
                _loadData();
              },
            ),
            _exploreTile(
              icon: Icons.savings_outlined,
              title: 'Savings goals'.tr(),
              subtitle: 'Tap to view'.tr(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
                );
                _loadData();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _exploreTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F1FA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEEE5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF7F3DFF), size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212325),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF91919F),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashflowCard() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CashflowScreen()),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF9FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEEE5FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF7F3DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.show_chart_rounded, color: Color(0xFF7F3DFF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cashflow forecast'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212325),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View projected balance and upcoming outflows'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF91919F),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7F3DFF)),
          ],
        ),
      ),
    );
  }
}
