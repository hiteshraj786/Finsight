import 'package:flutter/material.dart';
import '../../../data/models/transaction_type.dart';
import '../../../core/utils/currency_formatter.dart';
import '../theme/sms_theme.dart';

class AmountText extends StatelessWidget {
  final int amountPaise;
  final TransactionType type;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isIgnored;

  const AmountText({
    super.key,
    required this.amountPaise,
    required this.type,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.isIgnored = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = type == TransactionType.debit;
    final prefix = isDebit ? '- ' : '+ ';
    final formatted = '$prefix${formatIndianRupees(amountPaise)}';

    final Color color;
    if (isIgnored) {
      color = AppColors.ignoredText;
    } else if (isDebit) {
      color = AppColors.debit;
    } else {
      color = AppColors.credit;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        formatted,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
          decoration: isIgnored ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

