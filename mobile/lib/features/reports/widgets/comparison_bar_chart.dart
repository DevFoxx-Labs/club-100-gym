import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'chart_common.dart';

/// A grouped bar chart comparing two amount series (e.g. Income vs Expenses)
/// across a shared set of period labels. Horizontally scrollable so it stays
/// readable even with 12+ periods on narrow screens.
class ComparisonBarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> seriesA;
  final List<double> seriesB;
  final Color colorA;
  final Color colorB;
  final String labelA;
  final String labelB;

  const ComparisonBarChart({
    super.key,
    required this.labels,
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
    required this.labelA,
    required this.labelB,
  });

  @override
  Widget build(BuildContext context) {
    final allValues = [...seriesA, ...seriesB];
    final maxValue = allValues.fold<double>(0, (m, v) => v > m ? v : m);

    if (maxValue <= 0) {
      return const EmptyChartState();
    }

    final maxY = maxValue * 1.25;
    const groupWidth = 52.0;
    final chartWidth = labels.length * groupWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth < 300 ? 300 : chartWidth,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.darkBorder, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: maxY / 4 == 0 ? null : maxY / 4,
                        getTitlesWidget: (value, meta) => Text(
                          formatCompactAmount(value),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[i],
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(labels.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(toY: seriesA[i], color: colorA, width: 10, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: seriesB[i], color: colorB, width: 10, borderRadius: BorderRadius.circular(4)),
                      ],
                    );
                  }),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.darkBackground,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final seriesLabel = rodIndex == 0 ? labelA : labelB;
                        return BarTooltipItem(
                          '$seriesLabel\n₹${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 11),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ChartLegend(items: [(colorA, labelA), (colorB, labelB)]),
      ],
    );
  }
}
