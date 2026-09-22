import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'chart_common.dart';

/// A donut chart with a scrollable legend, used for expense-category and
/// payment-method breakdowns. Accepts a pre-sorted (desc) map of label->amount.
class CategoryPieChart extends StatefulWidget {
  final Map<String, double> data;
  final List<Color> palette;

  const CategoryPieChart({super.key, required this.data, required this.palette});

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const EmptyChartState(message: 'No spending recorded for this period yet');
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 38,
              sections: List.generate(entries.length, (i) {
                final entry = entries[i];
                final isTouched = i == _touchedIndex;
                final percent = total == 0 ? 0.0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  color: widget.palette[i % widget.palette.length],
                  value: entry.value,
                  title: percent >= 8 ? '${percent.toStringAsFixed(0)}%' : '',
                  radius: isTouched ? 30 : 26,
                  titleStyle: const TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.w900, fontSize: 11),
                );
              }),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    _touchedIndex = response?.touchedSection?.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: entries.take(6).toList().asMap().entries.map((mapEntry) {
              final i = mapEntry.key;
              final entry = mapEntry.value;
              final color = widget.palette[i % widget.palette.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '₹${entry.value.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
