import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PeriodSegmentedControl extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> periods;

  const PeriodSegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    this.periods = const ['Week', 'Month', 'Year'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((period) {
          final isSelected = selected.toLowerCase() == period.toLowerCase();
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period.toLowerCase()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7F3DFF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7F3DFF).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF91919F),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
