import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/category_colors.dart';
import '../../domain/models.dart';

class CustomDonutChart extends StatefulWidget {
  final List<CategorySpend> items;
  final Widget? centerWidget;
  final double size;

  const CustomDonutChart({
    super.key,
    required this.items,
    this.centerWidget,
    this.size = 220,
  });

  @override
  State<CustomDonutChart> createState() => _CustomDonutChartState();
}

class _CustomDonutChartState extends State<CustomDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(color: Color(0xFF91919F)),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 3,
              centerSpaceRadius: widget.size * 0.32,
              sections: List.generate(widget.items.length, (i) {
                final item = widget.items[i];
                final isTouched = i == _touchedIndex;
                final radius = isTouched ? widget.size * 0.16 : widget.size * 0.13;
                final color = CategoryColors.forCategory(item.category);

                return PieChartSectionData(
                  color: color,
                  value: item.amountPaise.toDouble(),
                  title: '',
                  radius: radius,
                  showTitle: false,
                );
              }),
            ),
          ),
          if (widget.centerWidget != null) widget.centerWidget!,
        ],
      ),
    );
  }
}
