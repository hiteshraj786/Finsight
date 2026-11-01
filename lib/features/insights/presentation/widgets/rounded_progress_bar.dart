import 'package:flutter/material.dart';

class RoundedProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0+
  final Color color;
  final Color backgroundColor;
  final double height;

  const RoundedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = const Color(0xFFF1F1FA),
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final filledWidth = totalWidth * clamped;

        return Container(
          width: totalWidth,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: filledWidth,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      },
    );
  }
}
