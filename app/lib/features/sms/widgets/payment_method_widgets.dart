import 'package:flutter/material.dart';

import '../../../data/models/payment_method.dart';
import '../theme/sms_theme.dart';

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

/// Small "UPI" / "Card" pill shown on transaction cards.
class PaymentMethodTag extends StatelessWidget {
  final PaymentMethod method;

  const PaymentMethodTag({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

/// Row of choice chips for picking how a transaction was paid.
class PaymentMethodPicker extends StatelessWidget {
  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in PaymentMethod.values)
          ChoiceChip(
            avatar: Icon(
              method.icon,
              size: 16,
              color: method == selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            label: Text(method.label),
            selected: method == selected,
            showCheckmark: false,
            selectedColor: AppColors.primaryContainer,
            labelStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: method == selected ? FontWeight.w700 : FontWeight.w500,
              color: method == selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            onSelected: (_) => onChanged(method),
          ),
      ],
    );
  }
}
