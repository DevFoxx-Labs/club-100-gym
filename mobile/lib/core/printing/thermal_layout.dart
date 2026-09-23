import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Shared building blocks for narrow (58mm/80mm) thermal-printer PDF layouts,
/// styled to resemble a real POS receipt printout.
class ThermalLayout {
  static pw.Widget dashedDivider() => pw.Divider(
        borderStyle: pw.BorderStyle.dashed,
        color: PdfColors.grey600,
        height: 12,
        thickness: 0.75,
      );

  static pw.Widget center(String text, {double fontSize = 9, pw.FontWeight? fontWeight}) => pw.Center(
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        ),
      );

  static pw.Widget row(String label, String value, {double fontSize = 9, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: fontSize)),
            pw.SizedBox(width: 6),
            pw.Flexible(
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : null),
              ),
            ),
          ],
        ),
      );
}
