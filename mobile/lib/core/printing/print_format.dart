import 'package:pdf/pdf.dart';
import '../localization/app_translations.dart';

/// Supported paper formats for printing/sharing bills and receipts.
/// Thermal formats use a fixed roll width with unbounded (continuous) height.
enum PrintFormat { thermal58, thermal80, a5, a4 }

extension PrintFormatX on PrintFormat {
  bool get isThermal => this == PrintFormat.thermal58 || this == PrintFormat.thermal80;

  String get label => switch (this) {
        PrintFormat.thermal58 => tr('print_format_thermal58_label'),
        PrintFormat.thermal80 => tr('print_format_thermal80_label'),
        PrintFormat.a5 => tr('print_format_a5_label'),
        PrintFormat.a4 => tr('print_format_a4_label'),
      };

  String get description => switch (this) {
        PrintFormat.thermal58 => tr('print_format_thermal58_desc'),
        PrintFormat.thermal80 => tr('print_format_thermal80_desc'),
        PrintFormat.a5 => tr('print_format_a5_desc'),
        PrintFormat.a4 => tr('print_format_a4_desc'),
      };

  PdfPageFormat get pdfPageFormat => switch (this) {
        PrintFormat.thermal58 => const PdfPageFormat(
            58 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 4.5 * PdfPageFormat.mm,
            marginRight: 4.5 * PdfPageFormat.mm,
            marginTop: 8 * PdfPageFormat.mm,
            marginBottom: 8 * PdfPageFormat.mm,
          ),
        PrintFormat.thermal80 => const PdfPageFormat(
            80 * PdfPageFormat.mm,
            double.infinity,
            marginLeft: 6 * PdfPageFormat.mm,
            marginRight: 6 * PdfPageFormat.mm,
            marginTop: 8 * PdfPageFormat.mm,
            marginBottom: 8 * PdfPageFormat.mm,
          ),
        PrintFormat.a5 => PdfPageFormat.a5,
        PrintFormat.a4 => PdfPageFormat.a4,
      };
}

/// Looks up a [PrintFormat] by its enum name (as persisted in gym settings),
/// returning null if [name] is null/blank or unrecognized.
PrintFormat? printFormatFromName(String? name) {
  if (name == null || name.trim().isEmpty) return null;
  for (final format in PrintFormat.values) {
    if (format.name == name) return format;
  }
  return null;
}
