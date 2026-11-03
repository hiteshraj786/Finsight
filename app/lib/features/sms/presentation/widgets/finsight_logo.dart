import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final iconBox = Container(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/finsight_logo.png',
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
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
            color: scheme.onSurface,
            letterSpacing: -0.5,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}
