import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusTagType {
  auto,
  pending,
  needsCheck,
  ignored,
  debit,
  credit,
}

class StatusTag extends StatelessWidget {
  final StatusTagType type;
  final String? customLabel;

  const StatusTag({
    super.key,
    required this.type,
    this.customLabel,
  });

  const StatusTag.auto({super.key})
      : type = StatusTagType.auto,
        customLabel = null;

  const StatusTag.pending({super.key})
      : type = StatusTagType.pending,
        customLabel = null;

  const StatusTag.needsCheck({super.key})
      : type = StatusTagType.needsCheck,
        customLabel = null;

  const StatusTag.ignored({super.key})
      : type = StatusTagType.ignored,
        customLabel = null;

  const StatusTag.debit({super.key})
      : type = StatusTagType.debit,
        customLabel = null;

  const StatusTag.credit({super.key})
      : type = StatusTagType.credit,
        customLabel = null;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case StatusTagType.auto:
        bg = AppColors.autoTagBg;
        fg = AppColors.autoTagText;
        label = customLabel ?? 'Auto';
        break;
      case StatusTagType.pending:
        bg = AppColors.pendingBg;
        fg = AppColors.pendingText;
        label = customLabel ?? 'Pending';
        break;
      case StatusTagType.needsCheck:
        bg = AppColors.needsCheckBg;
        fg = AppColors.needsCheckText;
        label = customLabel ?? 'Needs check';
        break;
      case StatusTagType.ignored:
        bg = AppColors.ignoredBg;
        fg = AppColors.ignoredText;
        label = customLabel ?? 'Ignored';
        break;
      case StatusTagType.debit:
        bg = AppColors.debitLight;
        fg = AppColors.debit;
        label = customLabel ?? 'Debit';
        break;
      case StatusTagType.credit:
        bg = AppColors.creditLight;
        fg = AppColors.credit;
        label = customLabel ?? 'Credit';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

