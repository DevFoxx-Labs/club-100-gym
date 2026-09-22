import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'chart_common.dart';

/// A single-series line/area trend chart (e.g. Net Profit or Cumulative Member Growth)
/// across a shared set of period labels.
class TrendLineChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;
  final bool isCurrency;

  const TrendLineChart({
    super.key,
    required this.labels,
    required this.values,
    required this.color,
    this.isCurrency = true,
  });

  @override
  Widget build(BuildContext context) {
    if (values.every((v) => v == 0)) {
      return const EmptyChartState();
    }

    final maxValue = values.fold<double>(values.first, (m, v) => v > m ? v : m);
    final minValue = values.fold<double>(values.first, (m, v) => v < m ? v : m);
    final range = (maxValue - minValue).abs();
    final padding = range == 0 ? (maxValue.abs() * 0.2 + 10) : range * 0.25;
    final maxY = maxValue + padding;
    final minY = minValue < 0 ? minValue - padding : (minValue - padding < 0 ? 0.0 : minValue - padding);

    const pointWidth = 56.0;
    final chartWidth = labels.length * pointWidth;

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth < 300 ? 300 : chartWidth,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4 == 0 ? null : (maxY - minY) / 4,
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
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) => Text(
                      isCurrency ? formatCompactAmount(value) : value.toStringAsFixed(0),
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
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppTheme.darkBackground,
                  getTooltipItems: (spots) => spots.map((s) {
                    final text = isCurrency ? '₹${s.y.toStringAsFixed(0)}' : s.y.toStringAsFixed(0);
                    return LineTooltipItem(text, const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 11));
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
