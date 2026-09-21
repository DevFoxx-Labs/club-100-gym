import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'neon_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.statusOverdue : AppTheme.textWhite,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        Row(
          children: [
            Expanded(
              child: NeonButton(
                text: 'Cancel',
                isSecondary: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? AppTheme.statusOverdue : AppTheme.neonLime,
                  foregroundColor: isDestructive ? AppTheme.textWhite : AppTheme.darkBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                  onConfirm();
                },
                child: Text(
                  confirmText,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

