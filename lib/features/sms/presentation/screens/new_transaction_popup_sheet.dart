import 'package:flutter/material.dart';
import '../../models/parsed_transaction.dart';
import '../theme/app_theme.dart';
import '../widgets/amount_text.dart';
import '../widgets/category_widgets.dart';
import '../widgets/masking_helpers.dart';
import '../widgets/pill_buttons.dart';

class NewTransactionPopupSheet extends StatefulWidget {
  final ParsedTransaction transaction;
  final ValueChanged<String> onConfirm;
  final VoidCallback onIgnore;
  final VoidCallback onEdit;

  const NewTransactionPopupSheet({
    super.key,
    required this.transaction,
    required this.onConfirm,
    required this.onIgnore,
    required this.onEdit,
  });

  static Future<void> show(
    BuildContext context, {
    required ParsedTransaction transaction,
    required ValueChanged<String> onConfirm,
    required VoidCallback onIgnore,
    required VoidCallback onEdit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NewTransactionPopupSheet(
        transaction: transaction,
        onConfirm: onConfirm,
        onIgnore: onIgnore,
        onEdit: onEdit,
      ),
    );
  }

  @override
  State<NewTransactionPopupSheet> createState() =>
      _NewTransactionPopupSheetState();
}

class _NewTransactionPopupSheetState extends State<NewTransactionPopupSheet> {
  late String _selectedCategory;
  bool _showFullGrid = false;

  final List<String> _topCategories = const [
    'Food',
    'Grocery',
    'Shopping',
    'Travel',
    'Bills',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = CategoryMeta.sanitize(widget.transaction.category);
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final maskedAcct = maskAccount(tx.accountLast4);
    final suggestedCategory = CategoryMeta.sanitize(tx.category);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.cardRadius)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header tag
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.flash_on_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'New transaction detected',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Merchant and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    tx.party,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AmountText(
                  amountPaise: tx.amountPaise,
                  type: tx.type,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$maskedAcct · Just now',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            // Suggested category line
            Text(
              'Suggested: $suggestedCategory',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Category selection: Compact vs Full Grid
            if (!_showFullGrid) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._topCategories.map((c) {
                    final isSelected = _selectedCategory == c;
                    return CategoryChip(
                      category: c,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedCategory = c),
                    );
                  }),
                  InkWell(
                    onTap: () => setState(() => _showFullGrid = true),
                    borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        border: Border.all(color: AppColors.borderLight, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Other…',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
                children: CategoryMeta.validCategories.map((c) {
                  final isSelected = _selectedCategory == c;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = c),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CategoryIcon(
                            category: c,
                            size: 28,
                            iconSize: 16,
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            iconColor: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            // Actions
            Row(
              children: [
                Expanded(
                  child: SecondaryPillButton(
                    label: 'Ignore',
                    outlined: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onIgnore();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryPillButton(
                    label: 'Edit',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onEdit();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryPillButton(
                    label: 'Confirm',
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConfirm(_selectedCategory);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Not answered? We\'ll keep it as $suggestedCategory and mark it for review.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
