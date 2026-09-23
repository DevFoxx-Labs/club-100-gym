import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/gym_info_model.dart';
import '../printing/pdf_filename.dart';
import '../printing/pdf_theme_service.dart';
import '../printing/print_format.dart';
import '../printing/thermal_layout.dart';
import 'upi_service.dart';

class BillPdfService {
  static Future<Uint8List> generateBillPdf({
    required BillModel bill,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
  }) async {
    final theme = await PdfThemeService.getTheme();
    final pdf = pw.Document(theme: theme);
    final dateFormat = DateFormat('dd MMM yyyy');
    final showUpi = gymInfo.showUpiQrOnBill && gymInfo.hasUpiConfigured;
    final showBank = gymInfo.showBankDetailsOnBill && gymInfo.hasBankDetailsConfigured;

    String? upiUri;
    if (showUpi) {
      upiUri = UpiService.buildPaymentUri(
        upiId: gymInfo.upiId!,
        payeeName: (gymInfo.upiPayeeName != null && gymInfo.upiPayeeName!.trim().isNotEmpty)
            ? gymInfo.upiPayeeName!
            : gymInfo.name,
        amount: bill.amount,
        note: 'Bill ${bill.billNumber}',
        transactionRefId: bill.billNumber,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format.pdfPageFormat,
        margin: format.isThermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return format.isThermal
              ? _buildThermalBill(bill: bill, gymInfo: gymInfo, dateFormat: dateFormat, showUpi: showUpi, showBank: showBank, upiUri: upiUri, format: format)
              : _buildStandardBill(bill: bill, gymInfo: gymInfo, dateFormat: dateFormat, showUpi: showUpi, showBank: showBank, upiUri: upiUri);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStandardBill({
    required BillModel bill,
    required GymInfoModel gymInfo,
    required DateFormat dateFormat,
    required bool showUpi,
    required bool showBank,
    required String? upiUri,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    gymInfo.name.toUpperCase(),
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(gymInfo.address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  pw.Text('Phone: ${gymInfo.phone}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: bill.isPaid ? PdfColors.green700 : PdfColors.orange800,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  bill.isPaid ? 'PAID' : (bill.status == 'Overdue' ? 'OVERDUE' : 'PAYMENT DUE'),
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bill No: ${bill.billNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Text('Bill Date: ${dateFormat.format(bill.billDate)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text('Due Date: ${dateFormat.format(bill.dueDate)}', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 10),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILLED TO', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(bill.memberName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(bill.memberPhone, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(bill.planName, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${bill.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9))),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTAL DUE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('₹${bill.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          if (showUpi && upiUri != null) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: upiUri, width: 70, height: 70),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SCAN TO PAY VIA UPI', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 3),
                      pw.Text('UPI ID: ${gymInfo.upiId}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Amount ₹${bill.amount.toStringAsFixed(0)} will auto-fill in your UPI app.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          if (showBank) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BANK TRANSFER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  pw.SizedBox(height: 4),
                  if (gymInfo.bankAccountHolder != null && gymInfo.bankAccountHolder!.isNotEmpty)
                    pw.Text('A/C Holder: ${gymInfo.bankAccountHolder}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('A/C Number: ${gymInfo.bankAccountNumber}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('IFSC: ${gymInfo.bankIfsc}', style: const pw.TextStyle(fontSize: 9)),
                  if (gymInfo.bankName != null && gymInfo.bankName!.isNotEmpty)
                    pw.Text('Bank: ${gymInfo.bankName}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          pw.Text(
            'Thank you for choosing ${gymInfo.name}!',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalBill({
    required BillModel bill,
    required GymInfoModel gymInfo,
    required DateFormat dateFormat,
    required bool showUpi,
    required bool showBank,
    required String? upiUri,
    required PrintFormat format,
  }) {
    final qrSize = format == PrintFormat.thermal58 ? 110.0 : 140.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        ThermalLayout.center(gymInfo.name.toUpperCase(), fontSize: 12, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 3),
        ThermalLayout.center(gymInfo.address, fontSize: 8),
        ThermalLayout.center('Phone: ${gymInfo.phone}', fontSize: 8),
        pw.SizedBox(height: 6),
        ThermalLayout.center(
          bill.isPaid ? '*** PAID ***' : (bill.status == 'Overdue' ? '*** OVERDUE ***' : '*** PAYMENT DUE ***'),
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Bill No', bill.billNumber, bold: true),
        ThermalLayout.row('Bill Date', dateFormat.format(bill.billDate)),
        ThermalLayout.row('Due Date', dateFormat.format(bill.dueDate)),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Member', bill.memberName, bold: true),
        ThermalLayout.row('Phone', bill.memberPhone),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row(bill.planName, '₹${bill.amount.toStringAsFixed(0)}'),
        ThermalLayout.dashedDivider(),
        ThermalLayout.row('TOTAL DUE', '₹${bill.amount.toStringAsFixed(0)}', fontSize: 11, bold: true),
        ThermalLayout.dashedDivider(),

        if (showUpi && upiUri != null) ...[
          pw.SizedBox(height: 4),
          ThermalLayout.center('SCAN TO PAY VIA UPI', fontSize: 9, fontWeight: pw.FontWeight.bold),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: upiUri, width: qrSize, height: qrSize),
          ),
          pw.SizedBox(height: 6),
          ThermalLayout.center('UPI ID: ${gymInfo.upiId}', fontSize: 8),
          ThermalLayout.center('Amount ₹${bill.amount.toStringAsFixed(0)} auto-fills in your UPI app', fontSize: 7.5),
          ThermalLayout.dashedDivider(),
        ],

        if (showBank) ...[
          ThermalLayout.center('BANK TRANSFER DETAILS', fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          pw.SizedBox(height: 3),
          if (gymInfo.bankAccountHolder != null && gymInfo.bankAccountHolder!.isNotEmpty)
            ThermalLayout.row('A/C Holder', gymInfo.bankAccountHolder!, fontSize: 8),
          ThermalLayout.row('A/C Number', gymInfo.bankAccountNumber ?? '-', fontSize: 8),
          ThermalLayout.row('IFSC', gymInfo.bankIfsc ?? '-', fontSize: 8),
          if (gymInfo.bankName != null && gymInfo.bankName!.isNotEmpty)
            ThermalLayout.row('Bank', gymInfo.bankName!, fontSize: 8),
          ThermalLayout.dashedDivider(),
        ],

        pw.SizedBox(height: 4),
        ThermalLayout.center('Thank you for choosing', fontSize: 8, fontWeight: pw.FontWeight.bold),
        ThermalLayout.center(gymInfo.name, fontSize: 8, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 6),
      ],
    );
  }

  /// Builds the share/print file name using the member name and the actual
  /// plan period (e.g. "Bill-Rahul_Sharma-Sep-Oct-2026" for a monthly plan,
  /// "Bill-Rahul_Sharma-Sep-Dec-2026" for a quarterly one). Falls back to the
  /// bill/due dates when the membership's real period isn't available.
  static String _fileName({
    required BillModel bill,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    final start = periodStart ?? (bill.billDate.isBefore(bill.dueDate) ? bill.billDate : bill.dueDate);
    final end = periodEnd ?? (bill.billDate.isBefore(bill.dueDate) ? bill.dueDate : bill.billDate);
    return PdfFileName.build(prefix: 'Bill', memberName: bill.memberName, periodStart: start, periodEnd: end);
  }

  static Future<void> printBill({
    required BillModel bill,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final pdfBytes = await generateBillPdf(bill: bill, gymInfo: gymInfo, format: format);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => pdfBytes,
      name: _fileName(bill: bill, periodStart: periodStart, periodEnd: periodEnd),
      format: format.pdfPageFormat,
      dynamicLayout: false,
      forceCustomPrintPaper: format.isThermal,
    );
  }

  static Future<void> shareBill({
    required BillModel bill,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final pdfBytes = await generateBillPdf(bill: bill, gymInfo: gymInfo, format: format);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${_fileName(bill: bill, periodStart: periodStart, periodEnd: periodEnd)}.pdf',
    );
  }
}
