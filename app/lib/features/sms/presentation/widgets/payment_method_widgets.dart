import 'package:flutter/material.dart';

import '../../models/payment_method.dart';
import '../theme/app_theme.dart';

extension PaymentMethodIcon on PaymentMethod {
  IconData get icon => switch (this) {
    PaymentMethod.upi => Icons.qr_code_2_rounded,
    PaymentMethod.card => Icons.credit_card_rounded,
    PaymentMethod.netBanking => Icons.account_balance_rounded,
    PaymentMethod.atm => Icons.local_atm_rounded,
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.unknown => Icons.more_horiz_rounded,
  };
}

class PaymentMethodTag extends StatelessWidget {
  final PaymentMethod method;

  const PaymentMethodTag({super.key, required this.method});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(method.icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          method.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
