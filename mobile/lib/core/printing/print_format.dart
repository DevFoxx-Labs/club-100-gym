import 'package:pdf/pdf.dart';

/// Supported paper formats for printing/sharing bills and receipts.
/// Thermal formats use a fixed roll width with unbounded (continuous) height.
enum PrintFormat { thermal58, thermal80, a5, a4 }

extension PrintFormatX on PrintFormat {
  bool get isThermal => this == PrintFormat.thermal58 || this == PrintFormat.thermal80;

  String get label => switch (this) {
        PrintFormat.thermal58 => '58mm Thermal',
        PrintFormat.thermal80 => '80mm Thermal',
        PrintFormat.a5 => 'A5',
        PrintFormat.a4 => 'A4',
      };

  String get description => switch (this) {
        PrintFormat.thermal58 => 'Narrow receipt printer roll',
        PrintFormat.thermal80 => 'Standard receipt printer roll',
        PrintFormat.a5 => 'Half-page, compact document',
        PrintFormat.a4 => 'Full-page, standard document',
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
