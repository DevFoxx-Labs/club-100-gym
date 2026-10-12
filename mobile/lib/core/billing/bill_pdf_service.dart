import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/gym_info_model.dart';
import '../printing/pdf_filename.dart';
import '../printing/pdf_logo_loader.dart';
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
    final logo = await PdfLogoLoader.load(gymInfo.logoPath);
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
        // After a part payment, only the remaining balance may be requested.
        amount: _amountDue(bill),
        note: 'Bill ${bill.billNumber}',
        transactionRefId: bill.billNumber,
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: format.pdfPageFormat,
        margin: format.isThermal ? null : const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return format.isThermal
              ? _buildThermalBill(bill: bill, gymInfo: gymInfo, dateFormat: dateFormat, showUpi: showUpi, showBank: showBank, upiUri: upiUri, format: format, logo: logo)
              : _buildStandardBill(bill: bill, gymInfo: gymInfo, dateFormat: dateFormat, showUpi: showUpi, showBank: showBank, upiUri: upiUri, logo: logo);
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
    pw.ImageProvider? logo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 1),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(logo, width: 38, height: 38, fit: pw.BoxFit.cover),
                      ),
                      pw.SizedBox(width: 10),
                    ],
                    pw.Expanded(
                      child: pw.Column(
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
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
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
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_money(bill.amount), style: const pw.TextStyle(fontSize: 9))),
                ],
              ),
              if (bill.paidAmount > 0 && !bill.isPaid)
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Less: Paid so far', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('- ${_money(bill.paidAmount)}', style: const pw.TextStyle(fontSize: 9))),
                  ],
                ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_totalLabel(bill), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(_money(_amountDue(bill)), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
                      pw.Text('Amount ${_money(_amountDue(bill))} will auto-fill in your UPI app.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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
    pw.ImageProvider? logo,
  }) {
    final qrSize = format == PrintFormat.thermal58 ? 100.0 : 130.0;
    final logoSize = format == PrintFormat.thermal58 ? 42.0 : 50.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        if (logo != null) ...[
          pw.Center(
            child: pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(logo, width: logoSize, height: logoSize, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(height: 5),
        ],
        ThermalLayout.center(gymInfo.name.toUpperCase(), fontSize: 11, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 3),
        ThermalLayout.center(gymInfo.address, fontSize: 7.5),
        ThermalLayout.center('Phone: ${gymInfo.phone}', fontSize: 7.5),
        pw.SizedBox(height: 6),
        ThermalLayout.center(
          bill.isPaid
              ? '*** PAID ***'
              : (bill.status == 'Overdue'
                  ? '*** OVERDUE ***'
                  : (bill.isPartiallyPaid ? '*** BALANCE DUE ***' : '*** PAYMENT DUE ***')),
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Bill No', bill.billNumber, fontSize: 8, bold: true),
        ThermalLayout.row('Bill Date', dateFormat.format(bill.billDate), fontSize: 8),
        ThermalLayout.row('Due Date', dateFormat.format(bill.dueDate), fontSize: 8),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Member', bill.memberName, fontSize: 8, bold: true),
        ThermalLayout.row('Phone', bill.memberPhone, fontSize: 8),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row(bill.planName, _money(bill.amount), fontSize: 8),
        if (bill.paidAmount > 0 && !bill.isPaid)
          ThermalLayout.row('Paid so far', '- ${_money(bill.paidAmount)}', fontSize: 8),
        ThermalLayout.dashedDivider(),
        ThermalLayout.row(_totalLabel(bill), _money(_amountDue(bill)), fontSize: 10, bold: true),
        ThermalLayout.dashedDivider(),

        if (showUpi && upiUri != null) ...[
          pw.SizedBox(height: 4),
          ThermalLayout.center('SCAN TO PAY VIA UPI', fontSize: 8.5, fontWeight: pw.FontWeight.bold),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: upiUri, width: qrSize, height: qrSize),
          ),
          pw.SizedBox(height: 6),
          ThermalLayout.center('UPI ID: ${gymInfo.upiId}', fontSize: 7.5),
          ThermalLayout.center('Amount ${_money(_amountDue(bill))} auto-fills in your UPI app', fontSize: 7),
          ThermalLayout.dashedDivider(),
        ],

        if (showBank) ...[
          ThermalLayout.center('BANK TRANSFER DETAILS', fontSize: 8, fontWeight: pw.FontWeight.bold),
          pw.SizedBox(height: 3),
          if (gymInfo.bankAccountHolder != null && gymInfo.bankAccountHolder!.isNotEmpty)
            ThermalLayout.row('A/C Holder', gymInfo.bankAccountHolder!, fontSize: 7.5),
          ThermalLayout.row('A/C Number', gymInfo.bankAccountNumber ?? '-', fontSize: 7.5),
          ThermalLayout.row('IFSC', gymInfo.bankIfsc ?? '-', fontSize: 7.5),
          if (gymInfo.bankName != null && gymInfo.bankName!.isNotEmpty)
            ThermalLayout.row('Bank', gymInfo.bankName!, fontSize: 7.5),
          ThermalLayout.dashedDivider(),
        ],

        pw.SizedBox(height: 4),
        ThermalLayout.center('Thank you for choosing', fontSize: 7.5, fontWeight: pw.FontWeight.bold),
        ThermalLayout.center(gymInfo.name, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
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

  static String _money(double v) =>
      '₹${(v - v.roundToDouble()).abs() < 0.005 ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

  /// What the member still has to pay: the remaining balance on an open bill,
  /// or the bill amount for a settled/cancelled one.
  static double _amountDue(BillModel bill) => bill.isDue ? bill.remainingBalance : bill.amount;

  static String _totalLabel(BillModel bill) {
    if (bill.isPaid) return 'TOTAL (PAID)';
    if (bill.paidAmount > 0) return 'BALANCE DUE';
    return 'TOTAL DUE';
  }
}
