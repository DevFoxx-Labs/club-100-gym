import 'package:flutter/material.dart';
import '../../core/printing/print_format.dart';
import '../../core/theme/app_theme.dart';

/// Bottom sheet letting the admin pick a paper format before printing/sharing
/// a bill or receipt: 58mm/80mm thermal roll, or A5/A4 document.
Future<PrintFormat?> showPrintFormatSheet(BuildContext context) {
  return showModalBottomSheet<PrintFormat>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppTheme.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.paddingOf(context).bottom;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + (bottomInset > 0 ? bottomInset : 10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'CHOOSE PAPER FORMAT',
                style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select the printer or paper size for this document',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              for (final format in PrintFormat.values) ...[
                _PrintFormatTile(format: format, onTap: () => Navigator.pop(context, format)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _PrintFormatTile extends StatelessWidget {
  final PrintFormat format;
  final VoidCallback onTap;

  const _PrintFormatTile({required this.format, required this.onTap});

  IconData get _icon => format.isThermal ? Icons.receipt_long_rounded : Icons.description_rounded;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: AppTheme.neonLime, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    format.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
