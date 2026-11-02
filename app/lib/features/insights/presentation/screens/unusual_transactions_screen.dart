import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/merchant_avatar.dart';
import 'transaction_search_screen.dart';

class UnusualTransactionsScreen extends StatefulWidget {
  const UnusualTransactionsScreen({super.key});

  @override
  State<UnusualTransactionsScreen> createState() => _UnusualTransactionsScreenState();
}

class _UnusualTransactionsScreenState extends State<UnusualTransactionsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  bool _loading = true;
  List<UnusualFlag> _flags = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getUnusual();
    if (mounted) {
      setState(() {
        _flags = data;
        _loading = false;
      });
    }
  }

  Future<void> _dismiss(int id) async {
    await _repo.dismissUnusual(id);
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as normal. Baseline updated.'.tr())),
      );
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
          'Unusual Transactions',
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
                  // Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFFD3C4A)),
                            const SizedBox(width: 4),
                            Text(
                              '${_flags.length} FLAGGED THIS MONTH',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFD3C4A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7F3DFF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Smart detection on',
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
                  const SizedBox(height: 8),
                  Text(
                    'Unusual amounts or duplicate charges detected outside your regular spending behavior.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF91919F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_flags.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF00A86B)),
                            const SizedBox(height: 12),
                            Text(
                              'No unusual transactions',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
                            ),
                            Text(
                              'All spending aligns with your normal patterns.',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF91919F)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _flags.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, i) => _buildUnusualCard(_flags[i]),
                    ),
                  const SizedBox(height: 24),

                  // Bottom Shield Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF91919F)),
                      const SizedBox(width: 6),
                      Text(
                        'We compare each payment with your recent average.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildUnusualCard(UnusualFlag flag) {
    final isDuplicate = flag.reason.toLowerCase().contains('duplicate');
    final isSpike = flag.reason.contains('3x');
    final accentColor = isSpike ? const Color(0xFFFCAC12) : const Color(0xFFFD3C4A);

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Accent bar on left edge
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          MerchantAvatar(name: flag.merchant ?? 'TX', size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  flag.merchant ?? 'Merchant',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF212325),
                                  ),
                                ),
                                Text(
                                  DateFormat('d MMM yyyy').format(flag.occurredAt ?? flag.createdAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF91919F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(flag.amountPaise ?? 0),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF212325),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reason box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDuplicate
                                  ? Icons.copy_rounded
                                  : (isSpike ? Icons.bar_chart_rounded : Icons.trending_up_rounded),
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flag.reason,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF212325),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (flag.id != null) _dismiss(flag.id!);
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFEEE5FF),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                '✓ Looks right',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7F3DFF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionSearchScreen(
                                      initialMerchant: flag.merchant,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shield_outlined, size: 14, color: Colors.white),
                              label: Text(
                                'Review',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7F3DFF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
