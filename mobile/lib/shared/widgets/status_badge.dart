import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    final lower = status.toLowerCase();

    if (lower.contains('overdue')) {
      bg = AppTheme.statusOverdue.withValues(alpha: 0.15);
      fg = AppTheme.statusOverdue;
      icon = Icons.warning_rounded;
    } else if (lower.contains('due') || lower.contains('expiring')) {
      bg = AppTheme.statusDueSoon.withValues(alpha: 0.15);
      fg = AppTheme.statusDueSoon;
      icon = Icons.access_time_rounded;
    } else if (lower.contains('active') || lower.contains('paid')) {
      bg = AppTheme.statusActive.withValues(alpha: 0.15);
      fg = AppTheme.statusActive;
      icon = Icons.check_circle_rounded;
    } else {
      bg = AppTheme.textMuted.withValues(alpha: 0.15);
      fg = AppTheme.textMuted;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label ?? status,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

