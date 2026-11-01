import 'package:flutter/material.dart';
import '../theme/sms_theme.dart';

class FinSightLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final double fontSize;

  const FinSightLogo({
    super.key,
    this.size = 36,
    this.showText = true,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337F3DFF),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'F',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.6,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
      ),
    );

    if (!showText) return iconBox;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        iconBox,
        const SizedBox(width: 10),
        Text(
          'FinSight',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

