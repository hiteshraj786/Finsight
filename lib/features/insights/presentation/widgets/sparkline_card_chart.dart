import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SparklineCardChart extends StatelessWidget {
  final List<double> values;
  final double height;

  const SparklineCardChart({
    super.key,
    this.values = const [12, 14, 18, 15, 22, 28, 25, 30, 36, 32, 42],
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final safeValues = values.length >= 2 ? values : const [0.0, 0.0];
    final spots = List.generate(
      safeValues.length,
      (i) => FlSpot(i.toDouble(), safeValues[i]),
    );

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: Colors.white,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot.x == (values.length - 1).toDouble(),
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF7F3DFF),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.25),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
