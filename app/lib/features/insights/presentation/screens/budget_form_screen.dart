import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/currency_service.dart';
import '../../../../core/services/language_service.dart';
import '../../data/insights_repository_provider.dart';
import '../../domain/category_colors.dart';
import '../../domain/currency_formatter.dart';
import '../../domain/models.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;

  const BudgetFormScreen({super.key, this.budget});

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _repo = InsightsRepositoryProvider.current;

  final List<String> _categories = const [
    'Food & Dining',
    'Shopping',
    'Transport',
    'Bills & Utilities',
    'Entertainment',
    'Health',
    'Others',
  ];

  late String _selectedCategory;
  late TextEditingController _amountController;
  late BudgetPeriod _frequency;
  late double _alertThreshold;
  late bool _notifyOnOver;
  bool _saving = false;

  bool get _isEdit => widget.budget != null;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.budget?.categoryId ?? _categories.first;
    final initialRupees = widget.budget != null
        ? (widget.budget!.limitAmountPaise / 100).round()
        : 15000;
    _amountController = TextEditingController(text: initialRupees.toString());
    _frequency = widget.budget?.period ?? BudgetPeriod.monthly;
    _alertThreshold = widget.budget?.alertThreshold ?? 0.8;
    _notifyOnOver = widget.budget?.notifyOnOver ?? true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _addAmount(int addRupees) {
    final current = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() {
      _amountController.text = (current + addRupees).toString();
    });
  }

  Future<void> _save() async {
    final rupees = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (rupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid budget amount'.tr())),
      );
      return;
    }

    setState(() => _saving = true);
    final newBudget = Budget(
      id: widget.budget?.id,
      categoryId: _selectedCategory,
      limitAmountPaise: rupees * 100,
      period: _frequency,
      alertThreshold: _alertThreshold,
      notifyOnOver: _notifyOnOver,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    await _repo.saveBudget(newBudget);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit budget' : 'New budget';

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
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212325),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select category chips row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Select category',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212325),
                    ),
                  ),
                ),
                Text(
                  'Swipe for more',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF91919F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _selectedCategory;
                  final color = CategoryColors.forCategory(cat);
                  final icon = CategoryColors.iconForCategory(cat);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEEE5FF) : const Color(0xFFF1F1FA),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF7F3DFF) : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF7F3DFF) : const Color(0xFF212325),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Limit Target Input
            Center(
              child: Column(
                children: [
                  Text(
                    'MONTHLY LIMIT TARGET',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF91919F),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${CurrencyService.symbolFor(CurrencyService.current)} ',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF7F3DFF),
                        ),
                      ),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF212325),
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Pills (+500, +1000, +5000)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _quickAddChip(500),
                  const SizedBox(width: 10),
                  _quickAddChip(1000),
                  const SizedBox(width: 10),
                  _quickAddChip(5000),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Frequency
            Text(
              'Budget frequency',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212325),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1FA),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  _frequencyOption('Weekly', BudgetPeriod.weekly),
                  _frequencyOption('Monthly', BudgetPeriod.monthly),
                  _frequencyOption('Yearly', BudgetPeriod.yearly),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Alert Threshold Slider
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F1FA)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Alert me when I reach',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212325),
                          ),
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
                          '${(_alertThreshold * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF7F3DFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF7F3DFF),
                      inactiveTrackColor: const Color(0xFFEEE5FF),
                      thumbColor: const Color(0xFF7F3DFF),
                      overlayColor: const Color(0xFF7F3DFF).withValues(alpha: 0.12),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _alertThreshold,
                      min: 0.5,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (v) => setState(() => _alertThreshold = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('50%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF91919F))),
                        Text('75%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF91919F))),
                        Text('100%', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF91919F))),
                      ],
                    ),
                  ),
                  const Divider(height: 28, color: Color(0xFFF1F1FA)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notify me when I go over',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212325),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Instant push notification when limit breached',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF91919F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _notifyOnOver,
                        activeThumbColor: const Color(0xFF7F3DFF),
                        onChanged: (v) => setState(() => _notifyOnOver = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Smart Tracking Tip (Section 5 correction: based on 3 months average spend)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FBF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6F7F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4F7E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF00A86B), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Tracking Tip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212325),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Setting ${CurrencyService.symbolFor(CurrencyService.current)}${_amountController.text} for $_selectedCategory is based on your last 3-month spending average.',
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
            const SizedBox(height: 32),

            // Action Buttons: Save & Cancel
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7F3DFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save budget'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF91919F),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _quickAddChip(int rupees) {
    return GestureDetector(
      onTap: () => _addAmount(rupees),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEEE5FF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '+${CurrencyFormatter.formatRupees(rupees)}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7F3DFF),
          ),
        ),
      ),
    );
  }

  Widget _frequencyOption(String label, BudgetPeriod p) {
    final isSelected = _frequency == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = p),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7F3DFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF91919F),
            ),
          ),
        ),
      ),
    );
  }
}
