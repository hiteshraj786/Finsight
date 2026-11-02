import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MonthSwitcher extends StatelessWidget {
  final DateTime selectedMonth;
  final String period;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSwitcher({
    super.key,
    required this.selectedMonth,
    this.period = 'month',
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (period) {
      'week' => '${DateFormat('d MMM').format(_periodStart)} – '
          '${DateFormat('d MMM').format(_periodStart.add(const Duration(days: 6)))}',
      'year' => DateFormat('yyyy').format(selectedMonth),
      _ => DateFormat('MMMM yyyy').format(selectedMonth),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left_rounded, size: 24, color: scheme.onSurface),
          onPressed: () {
            onMonthChanged(_shift(-1));
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          splashRadius: 20,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.chevron_right_rounded, size: 24, color: scheme.onSurface),
          onPressed: () {
            onMonthChanged(_shift(1));
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          splashRadius: 20,
        ),
      ],
    );
  }

  DateTime get _periodStart {
    final day = DateTime(selectedMonth.year, selectedMonth.month, selectedMonth.day);
    if (period == 'week') {
      return day.subtract(Duration(days: day.weekday - 1));
    }
    if (period == 'year') {
      return DateTime(day.year);
    }
    return DateTime(day.year, day.month);
  }

  DateTime _shift(int amount) {
    if (period == 'week') {
      return selectedMonth.add(Duration(days: amount * 7));
    }
    if (period == 'year') {
      return DateTime(selectedMonth.year + amount, selectedMonth.month, selectedMonth.day);
    }
    return DateTime(selectedMonth.year, selectedMonth.month + amount, selectedMonth.day);
  }
}
