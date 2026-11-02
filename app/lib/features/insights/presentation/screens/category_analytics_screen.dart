import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/category_colors.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/category_icon_tile.dart';
import '../widgets/custom_donut_chart.dart';
import '../widgets/month_switcher.dart';
import '../widgets/period_segmented_control.dart';
import 'transaction_search_screen.dart';

class CategoryAnalyticsScreen extends StatefulWidget {
  const CategoryAnalyticsScreen({super.key});

  @override
  State<CategoryAnalyticsScreen> createState() => _CategoryAnalyticsScreenState();
}

class _CategoryAnalyticsScreenState extends State<CategoryAnalyticsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  String _selectedPeriod = 'month';
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool _loading = true;
  List<CategorySpend> _spends = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getCategorySpend(period: _selectedPeriod, date: _selectedDate);
    if (mounted) {
      setState(() {
        _spends = data;
        _loading = false;
      });
    }
  }

  int get _totalSpendPaise =>
      _spends.fold<int>(0, (sum, item) => sum + item.amountPaise);

  DateTime get _previousPeriodDate {
    switch (_selectedPeriod) {
      case 'week':
        return _selectedDate.subtract(const Duration(days: 7));
      case 'year':
        return DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day);
      default:
        return DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
    }
  }

  String get _previousPeriodLabel {
    switch (_selectedPeriod) {
      case 'week':
        return DateFormat('d MMM').format(_previousPeriodDate);
      case 'year':
        return DateFormat('yyyy').format(_previousPeriodDate);
      default:
        return DateFormat('MMM').format(_previousPeriodDate);
    }
  }

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
          'Category Analytics'.tr(),
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
                  PeriodSegmentedControl(
                    selected: _selectedPeriod,
                    onChanged: (p) {
                      setState(() => _selectedPeriod = p);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 14),
                  MonthSwitcher(
                    selectedMonth: _selectedDate,
                    period: _selectedPeriod,
                    onMonthChanged: (d) {
                      setState(() => _selectedDate = d);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Donut chart card
                  _buildDonutCard(),
                  const SizedBox(height: 28),

                  // Previous-period comparison
                  _buildComparisonSection(),
                  const SizedBox(height: 28),

                  // All categories list
                  _buildCategoriesList(),
                  const SizedBox(height: 28),

                  // Export button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${DateFormat('MMMM').format(_selectedDate)} ${'breakdown exported successfully'.tr()}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF7F3DFF)),
                      label: Text(
                        '${'Export'.tr()} ${DateFormat('MMMM').format(_selectedDate)} ${'Breakdown'.tr()}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7F3DFF),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEEE5FF),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  Widget _buildDonutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1FA)),
      ),
      child: Column(
        children: [
          CustomDonutChart(
            items: _spends,
            size: 220,
            centerWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.formatPaise(_totalSpendPaise),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212325),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'Total spent in'.tr()} ${DateFormat('MMM').format(_selectedDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF91919F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _spends.take(3).map((item) {
              final color = CategoryColors.forCategory(item.category);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F1FA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${item.category} ${item.sharePercentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212325),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection() {
    final comparisonItems = _spends.where((s) => s.percentageChange != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'vs'.tr()} ${_previousPeriodLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212325),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top spend differences by period'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF91919F),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _legendDot(const Color(0xFF7F3DFF), DateFormat('MMM').format(_selectedDate)),
                const SizedBox(width: 10),
                _legendDot(const Color(0xFFD3BDFF), _previousPeriodLabel),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...comparisonItems.map((item) {
          final isHigher = (item.percentageChange ?? 0) >= 0;
          final pct = (item.percentageChange ?? 0).abs().toStringAsFixed(0);
          final currentAmount = item.amountPaise;
          final previousAmount = item.previousAmountPaise ?? 0;
          final maxAmount = [currentAmount, previousAmount].reduce((a, b) => a > b ? a : b);
          final currentBar = maxAmount == 0 ? 0.0 : currentAmount / maxAmount;
          final previousBar = maxAmount == 0 ? 0.0 : previousAmount / maxAmount;
          final currentStr = CurrencyFormatter.formatCompact(currentAmount);
          final previousStr = CurrencyFormatter.formatCompact(previousAmount);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.category,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212325),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isHigher ? const Color(0xFFFFECEF) : const Color(0xFFE6F7F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHigher ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 11,
                            color: isHigher ? const Color(0xFFFD3C4A) : const Color(0xFF00A86B),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$pct% ${(isHigher ? 'higher' : 'lower').tr()}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isHigher ? const Color(0xFFFD3C4A) : const Color(0xFF00A86B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: currentBar,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F1FA),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF7F3DFF)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: previousBar,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F1FA),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFFD3BDFF)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currentStr,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF212325)),
                        ),
                        Text(
                          previousStr,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F)),
        ),
      ],
    );
  }

  Widget _buildCategoriesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All categories'.tr(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212325),
              ),
            ),
            Text(
              '${_spends.length} CATEGORIES',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF91919F),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _spends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _spends[index];
            final color = CategoryColors.forCategory(item.category);

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionSearchScreen(
                      initialCategory: item.category,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F1FA)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CategoryIconTile(category: item.category, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212325),
                                ),
                              ),
                              Text(
                                '${item.transactionCount} transactions',
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212325),
                              ),
                            ),
                            Text(
                              '${item.sharePercentage.toStringAsFixed(0)}% share',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7F3DFF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF91919F)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (item.sharePercentage / 30).clamp(0.05, 1.0),
                        minHeight: 4,
                        backgroundColor: const Color(0xFFF1F1FA),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
