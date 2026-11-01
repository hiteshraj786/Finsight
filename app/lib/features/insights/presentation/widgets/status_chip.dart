import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatusChipKind { onTrack, nearLimit, overBudget, custom }

class StatusChip extends StatelessWidget {
  final String label;
  final StatusChipKind kind;
  final Color? customBackground;
  final Color? customTextColor;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    this.kind = StatusChipKind.onTrack,
    this.customBackground,
    this.customTextColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (kind) {
      case StatusChipKind.onTrack:
        bg = const Color(0xFFE6F7F0);
        fg = const Color(0xFF00A86B);
        break;
      case StatusChipKind.nearLimit:
        bg = const Color(0xFFFFF7E6);
        fg = const Color(0xFFE69100);
        break;
      case StatusChipKind.overBudget:
        bg = const Color(0xFFFFECEF);
        fg = const Color(0xFFFD3C4A);
        break;
      case StatusChipKind.custom:
        bg = customBackground ?? const Color(0xFFF1F1FA);
        fg = customTextColor ?? const Color(0xFF7F3DFF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
