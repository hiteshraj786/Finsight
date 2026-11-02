import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/currency_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';
import '../widgets/gradient_hero_card.dart';
import '../widgets/status_chip.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final _repo = InsightsRepositoryProvider.current;
  bool _loading = true;
  List<SavingsGoalEvaluation> _evaluations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repo.getSavingsGoalEvaluations();
    if (mounted) {
      setState(() {
        _evaluations = data;
        _loading = false;
      });
    }
  }

  int get _totalSavedPaise =>
      _evaluations.fold<int>(0, (sum, e) => sum + e.goal.savedAmountPaise);

  int get _totalTargetPaise =>
      _evaluations.fold<int>(0, (sum, e) => sum + e.goal.targetAmountPaise);

  double get _overallProgress =>
      _totalTargetPaise == 0 ? 0.0 : _totalSavedPaise / _totalTargetPaise;

  void _showAddGoalDialog() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final savedCtrl = TextEditingController(text: '0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Add savings goal',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Goal name (e.g. Goa trip)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Target amount (${CurrencyService.symbolFor(CurrencyService.current)})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: savedCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Already saved (${CurrencyService.symbolFor(CurrencyService.current)})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final target = int.tryParse(targetCtrl.text.trim()) ?? 0;
                    final saved = int.tryParse(savedCtrl.text.trim()) ?? 0;
                    if (name.isNotEmpty && target > 0) {
                      await _repo.addGoal(SavingsGoal(
                        name: name,
                        targetAmountPaise: target * 100,
                        savedAmountPaise: saved * 100,
                        targetDate: DateTime.now().add(const Duration(days: 90)),
                        createdAt: DateTime.now(),
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F3DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save goal',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMoneySheet(SavingsGoal goal) {
    final amountCtrl = TextEditingController(text: '1000');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Add money to ${goal.name}',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF212325)),
              ),
              const SizedBox(height: 8),
              Text(
                'Current progress: ${CurrencyFormatter.formatPaise(goal.savedAmountPaise)} / ${CurrencyFormatter.formatPaise(goal.targetAmountPaise)}',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF91919F)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '${CurrencyService.symbolFor(CurrencyService.current)} ',
                  labelText: 'Amount to add',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (amount > 0 && goal.id != null) {
                      await _repo.addMoneyToGoal(goal.id!, amount * 100);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F3DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add money',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_overallProgress * 100).toStringAsFixed(1);

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
          'Savings Goals',
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
                            Expanded(
                              child: Text(
                                'Saved so far',
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
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00A86B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'across ${_evaluations.length} goals',
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
                              CurrencyFormatter.formatPaise(_totalSavedPaise),
                              style: GoogleFonts.inter(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '/ ${CurrencyFormatter.formatPaise(_totalTargetPaise)} total',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: _overallProgress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF00A86B)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up, size: 14, color: Color(0xFF00A86B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Overall pace',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                            Text(
                              '$pct% completed',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Active Goals',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212325),
                                ),
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
                                '${_evaluations.length} active',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF91919F)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by date ⌵',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7F3DFF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Goals list
                  if (_evaluations.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No savings goals created yet. Tap + to add one!',
                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF91919F)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _evaluations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final item = _evaluations[i];
                        return _buildGoalCard(item);
                      },
                    ),
                  const SizedBox(height: 20),

                  // Computed Smart Tip Card (Section 5 rule)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF9FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEEE5FF)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEEE5FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF7F3DFF), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save ${CurrencyFormatter.formatPaise(80000)} more this month?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212325),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Save ${CurrencyFormatter.formatPaise(80000)} more this month to stay on track for Emergency fund.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF91919F),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _showAddGoalDialog,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Add goal',
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

  Widget _buildGoalCard(SavingsGoalEvaluation item) {
    final pct = (item.progress * 100).round();
    final isBehind = !item.onTrack;
    final ringColor = isBehind ? const Color(0xFFFCAC12) : const Color(0xFF7F3DFF);

    return InkWell(
      onTap: () => _showAddMoneySheet(item.goal),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Circular progress percentage ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: item.progress,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFFF1F1FA),
                        valueColor: AlwaysStoppedAnimation(ringColor),
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212325),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.goal.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF212325),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: item.onTrack ? 'On track' : 'Slightly behind',
                            kind: item.onTrack ? StatusChipKind.onTrack : StatusChipKind.nearLimit,
                            icon: item.onTrack ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Target: ${item.goal.targetDate.day} Dec ${item.goal.targetDate.year}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF91919F),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF212325)),
                children: [
                  TextSpan(
                    text: CurrencyFormatter.formatPaise(item.goal.savedAmountPaise),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' of ${CurrencyFormatter.formatPaise(item.goal.targetAmountPaise)}',
                    style: GoogleFonts.inter(color: const Color(0xFF91919F)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF7F3DFF)),
                  const SizedBox(width: 6),
                  Text(
                    'needs ${CurrencyFormatter.formatPaise(item.neededPerMonthPaise)} / month · Tap to add money',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF212325),
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
}
