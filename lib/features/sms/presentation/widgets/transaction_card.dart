import 'package:flutter/material.dart';
import '../../models/parsed_transaction.dart';
import '../../models/transaction_status.dart';
import '../theme/app_theme.dart';
import 'amount_text.dart';
import 'category_widgets.dart';
import 'masking_helpers.dart';
import 'status_tag.dart';

class TransactionCard extends StatelessWidget {
  final ParsedTransaction transaction;
  final VoidCallback? onTap;
  final ValueChanged<TransactionStatus>? onStatusChanged;
  final bool showActions;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onStatusChanged,
    this.showActions = false,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    return '$day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isIgnored = tx.status == TransactionStatus.ignored;
    final maskedAcct = maskAccount(tx.accountLast4);
    final dateStr = _formatDate(tx.date);
    final isAuto = tx.categorySource == 'auto' &&
        tx.category.trim().isNotEmpty &&
        tx.category.toLowerCase() != 'uncategorized';
    final categoryName = isAuto ? CategoryMeta.sanitize(tx.category) : 'Uncategorized';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F7F3DFF),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CategoryIcon(
                  category: isAuto ? categoryName : 'Uncategorized',
                  size: 42,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.party,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isIgnored
                              ? AppColors.ignoredText
                              : AppColors.textPrimary,
                          decoration:
                              isIgnored ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$categoryName · $maskedAcct · $dateStr',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: isAuto ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isAuto ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (isAuto) const StatusTag.auto(),
                          if (tx.status == TransactionStatus.pending)
                            const StatusTag.pending(),
                          if (tx.lowConfidence)
                            const StatusTag.needsCheck(),
                          if (isIgnored) const StatusTag.ignored(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 105),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AmountText(
                        amountPaise: tx.amountPaise,
                        type: tx.type,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        isIgnored: isIgnored,
                      ),
                      if (showActions && onStatusChanged != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () => onStatusChanged!(
                                TransactionStatus.confirmed,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: tx.status == TransactionStatus.confirmed
                                      ? AppColors.credit
                                      : const Color(0xFFD4CFE2),
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => onStatusChanged!(
                                TransactionStatus.ignored,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.block_rounded,
                                  color: isIgnored
                                      ? AppColors.debit
                                      : const Color(0xFFD4CFE2),
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

