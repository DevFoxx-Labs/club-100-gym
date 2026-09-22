import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Compact axis-label formatting shared by all report charts (e.g. 125000 -> "1.25L").
String formatCompactAmount(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  String result;
  if (abs >= 10000000) {
    result = '${(abs / 10000000).toStringAsFixed(abs % 10000000 == 0 ? 0 : 1)}Cr';
  } else if (abs >= 100000) {
    result = '${(abs / 100000).toStringAsFixed(abs % 100000 == 0 ? 0 : 1)}L';
  } else if (abs >= 1000) {
    result = '${(abs / 1000).toStringAsFixed(abs % 1000 == 0 ? 0 : 1)}K';
  } else {
    result = abs.toStringAsFixed(0);
  }
  return isNegative ? '-$result' : result;
}

/// Shared empty-state placeholder shown inside a chart card when there is no data yet.
class EmptyChartState extends StatelessWidget {
  final String message;

  const EmptyChartState({super.key, this.message = 'No data available for this period yet'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, color: AppTheme.textMuted.withValues(alpha: 0.4), size: 40),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally-wrapping color-swatch legend used beneath comparison charts.
class ChartLegend extends StatelessWidget {
  final List<(Color, String)> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: items.map((item) {
        final (color, label) = item;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }
}
