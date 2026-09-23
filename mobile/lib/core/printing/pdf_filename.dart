import 'package:intl/intl.dart';

/// Builds human-friendly, filesystem-safe PDF file names for shared bills and
/// receipts, e.g. "Bill-Rahul_Sharma-Sep-Oct-2026.pdf" for a monthly plan or
/// "Receipt-Rahul_Sharma-Sep-Dec-2026.pdf" for a quarterly one.
class PdfFileName {
  static final _monthFormat = DateFormat('MMM');

  /// "Sep-Oct-2026" when the period falls within one year, or
  /// "Sep2026-Mar2027" when it spans a year boundary (e.g. half-yearly plans).
  static String periodLabel(DateTime start, DateTime end) {
    if (start.year == end.year) {
      return '${_monthFormat.format(start)}-${_monthFormat.format(end)}-${end.year}';
    }
    return '${_monthFormat.format(start)}${start.year}-${_monthFormat.format(end)}${end.year}';
  }

  static String _sanitize(String input) {
    final cleaned = input.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return cleaned.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  static String build({
    required String prefix,
    required String memberName,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final namePart = _sanitize(memberName);
    return '$prefix-$namePart-${periodLabel(periodStart, periodEnd)}';
  }
}
