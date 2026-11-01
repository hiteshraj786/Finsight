import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MerchantAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const MerchantAvatar({
    super.key,
    required this.name,
    this.size = 46,
    this.backgroundColor,
    this.textColor,
  });

  String get _initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'TX';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    if (clean.length >= 2) {
      return clean.substring(0, 2).toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? const Color(0xFFEEE5FF);
    final fg = textColor ?? const Color(0xFF7F3DFF);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Text(
        _initials,
        style: GoogleFonts.inter(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
