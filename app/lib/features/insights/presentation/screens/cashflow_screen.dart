import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/gradient_hero_card.dart';

class CashflowScreen extends StatefulWidget {
  const CashflowScreen({super.key});

  @override
  State<CashflowScreen> createState() => _CashflowScreenState();
}

class _CashflowScreenState extends State<CashflowScreen> {
  final _repo = InsightsRepositoryProvider.current;
  bool _loading = true;
  CashflowForecast? _forecast;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getCashflow();
    if (mounted) {
      setState(() {
        _forecast = data;
        _loading = false;
      });
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
          'Cashflow'.tr(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading || _forecast == null
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
                            Expanded(
                              child: Text(
                                '${'Expected balance on'.tr()} ${DateFormat('d MMM').format(_forecast!.points.last.date)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
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
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Today ${CurrencyFormatter.formatPaise(_forecast!.todayBalancePaise)}',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.formatPaise(_forecast!.endBalancePaise, showDecimals: true),
                          style: GoogleFonts.inter(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '-${CurrencyFormatter.formatPaise(_forecast!.projectedNetChangePaise.abs())} ${'projected net change'.tr()}',
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
                  const SizedBox(height: 20),

                  // 30-Day Trajectory Card
                  _buildTrajectoryChartCard(),
                  const SizedBox(height: 18),

                  // Liquidity Buffer Notice (without move button as per section 5)
                  _buildLiquidityNotice(),
                  const SizedBox(height: 24),

                  // Upcoming Outflows Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upcoming outflows'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212325),
                        ),
                      ),
                      Text(
                        '${_forecast!.upcomingOutflows.length} ${'scheduled'.tr()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7F3DFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Outflows list
                  ..._forecast!.upcomingOutflows.map((outflow) {
                    final dayStr = outflow.nextExpectedDate.day < 10
                        ? '0${outflow.nextExpectedDate.day}'
                        : '${outflow.nextExpectedDate.day}';
                    return _buildOutflowTile(outflow, dayStr);
                  }),
                  const SizedBox(height: 20),

                  // Footer note
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF7F3DFF)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Based on your recurring payments and average daily spend.'.tr(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTrajectoryChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30-Day Trajectory',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212325),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Projected from your recurring payments',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF91919F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEE5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${DateFormat('d MMM').format(_forecast!.points.first.date)} – '
                  '${DateFormat('d MMM').format(_forecast!.points.last.date)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7F3DFF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dip marker label
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF212325),
                borderRadius: BorderRadius.circular(16),
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
                    'Dip: ${CurrencyFormatter.formatPaise(_forecast!.lowestPoint.balancePaise)} · '
                    '${DateFormat('d MMM').format(_forecast!.lowestPoint.date)}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Trajectory Line Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 6500000,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) {
                    if (val == 1000000) {
                      return FlLine(
                        color: const Color(0xFFFCAC12).withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                      );
                    }
                    return FlLine(
                      color: const Color(0xFFF1F1FA),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final index = val.round();
                        if (index < 0 || index >= _forecast!.points.length) {
                          return const SizedBox.shrink();
                        }
                        final point = _forecast!.points[index];
                        final text = DateFormat('d MMM').format(point.date);
                        final isHighlight = point.date == _forecast!.lowestPoint.date;
                        if (text.isEmpty) return const SizedBox.shrink();
                        return Text(
                          text,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                            color: isHighlight ? const Color(0xFFFCAC12) : const Color(0xFF91919F),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _forecast!.points.length >= 2
                        ? List.generate(_forecast!.points.length, (i) {
                            return FlSpot(i.toDouble(), _forecast!.points[i].balancePaise.toDouble());
                          })
                        : const [FlSpot(0, 0), FlSpot(1, 0)],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF7F3DFF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) => spot.x == 0 || spot.x == 3 || spot.x == 7,
                      getDotPainter: (spot, percent, barData, index) {
                        if (spot.x == 3) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: const Color(0xFFFCAC12),
                            strokeWidth: 2.5,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF7F3DFF),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF7F3DFF).withValues(alpha: 0.18),
                          const Color(0xFF7F3DFF).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 14, height: 4, decoration: BoxDecoration(color: const Color(0xFF7F3DFF), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text('Actual'.tr(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF212325))),
                  const SizedBox(width: 14),
                  Container(width: 14, height: 2, color: const Color(0xFF7F3DFF)),
                  const SizedBox(width: 6),
                  Text('Projected'.tr(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF91919F))),
                  const SizedBox(width: 14),
                  Container(width: 14, height: 2, color: const Color(0xFFFCAC12)),
                  const SizedBox(width: 6),
                  Text(
                    '${CurrencyFormatter.formatPaise(_forecast!.safetyCushionPaise)} safety cushion',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFFCAC12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE8B8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8B8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE69100), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liquidity Buffer Notice'.tr(),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF996100),
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF996100), height: 1.4),
                    children: [
                      TextSpan(text: 'Your balance may dip below '.tr()),
                      TextSpan(
                        text: CurrencyFormatter.formatPaise(_forecast!.safetyCushionPaise),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' around your next scheduled payment.'.tr(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutflowTile(RecurringPattern outflow, String dayStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1FA)),
      ),
      child: Row(
        children: [
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
                  DateFormat('MMM').format(outflow.nextExpectedDate).toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF7F3DFF)),
                ),
                Text(
                  dayStr,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF212325)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        outflow.merchant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Due in ${outflow.nextExpectedDate.difference(DateTime.now()).inDays.clamp(0, 999)}d',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFFD3C4A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM').format(outflow.nextExpectedDate)} · '
                  '${outflow.paymentMethod ?? 'Scheduled'}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF91919F)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${CurrencyFormatter.formatPaise(outflow.amountPaise)}',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF212325)),
              ),
              Text(
                outflow.paymentMethod ?? 'Auto-pay'.tr(),
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF91919F)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
