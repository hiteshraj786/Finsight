import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/merchant_avatar.dart';
import '../widgets/period_segmented_control.dart';
import 'transaction_search_screen.dart';

class TopMerchantsScreen extends StatefulWidget {
  const TopMerchantsScreen({super.key});

  @override
  State<TopMerchantsScreen> createState() => _TopMerchantsScreenState();
}

class _TopMerchantsScreenState extends State<TopMerchantsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  String _selectedPeriod = 'month';
  String _sortBy = 'amount'; // 'amount', 'count'
  bool _loading = true;
  List<MerchantStat> _merchants = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getTopMerchants(period: _selectedPeriod, sortBy: _sortBy);
    if (mounted) {
      setState(() {
        _merchants = data;
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
          'Top Merchants',
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
                  Row(
                    children: [
                      Expanded(
                        child: PeriodSegmentedControl(
                          selected: _selectedPeriod,
                          onChanged: (p) {
                            setState(() => _selectedPeriod = p);
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortBy = _sortBy == 'amount' ? 'count' : 'amount';
                          });
                          _loadData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE5FF),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.swap_vert_rounded, size: 16, color: Color(0xFF7F3DFF)),
                              const SizedBox(width: 4),
                              Text(
                                _sortBy == 'amount' ? 'By amount' : 'By count',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7F3DFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF1F1FA)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEE5FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.storefront_outlined, color: Color(0xFF7F3DFF), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You shopped at ${_merchants.length} merchants',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212325),
                                ),
                              ),
                              if (_merchants.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEE5FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up, size: 12, color: Color(0xFF7F3DFF)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Top: ${_merchants.first.merchant}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF7F3DFF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Responsible for ${(_merchants.first.relativeShare * 100).toStringAsFixed(0)}% of monthly spend',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF91919F),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ranked Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ranked by spend'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212325),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF91919F),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Merchant List
                  if (_merchants.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No merchant transactions recorded yet'.tr(),
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF91919F)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _merchants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _merchants[index];
                        return _buildMerchantTile(item);
                      },
                    ),
                  const SizedBox(height: 24),

                  // Bottom Shield Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F7FE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEE5FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF7F3DFF), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Merchant insights automatically aggregated from SMS alerts & UPI payment handles.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF91919F),
                              height: 1.3,
                            ),
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

  Widget _buildMerchantTile(MerchantStat item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionSearchScreen(
              initialMerchant: item.merchant,
            ),
          ),
        );
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
                Text(
                  '#${item.rank}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7F3DFF),
                  ),
                ),
                const SizedBox(width: 10),
                MerchantAvatar(name: item.merchant, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.merchant,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212325),
                        ),
                      ),
                      Text(
                        '${item.transactionCount} transactions · avg ${CurrencyFormatter.formatPaise(item.avgAmountPaise)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatPaise(item.amountPaise),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF212325),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.relativeShare.clamp(0.05, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFF1F1FA),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7F3DFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
