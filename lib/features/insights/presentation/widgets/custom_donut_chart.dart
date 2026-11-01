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
    final total = widget.items.fold<int>(0, (sum, i) => sum + i.amountPaise);
    if (widget.items.isEmpty || total <= 0) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size * 0.76,
              height: widget.size * 0.76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF1F1FA), width: widget.size * 0.12),
              ),
            ),
            if (widget.centerWidget != null)
              widget.centerWidget!
            else
              const Text('No spend yet', style: TextStyle(color: Color(0xFF91919F), fontSize: 13)),
          ],
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
