import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/gym_info_model.dart';
import '../printing/pdf_theme_service.dart';
import '../printing/print_format.dart';
import '../printing/thermal_layout.dart';

class ReceiptPdfService {
  static Future<Uint8List> generateReceiptPdf({
    required ReceiptModel receipt,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
  }) async {
    final theme = await PdfThemeService.getTheme();
    final pdf = pw.Document(theme: theme);
    final dateFormat = DateFormat('dd MMM yyyy');
    final hasPt = receipt.personalTrainingFee > 0;
    final baseFee = hasPt ? (receipt.amount - receipt.personalTrainingFee) : receipt.amount;

    pdf.addPage(
      pw.Page(
        pageFormat: format.pdfPageFormat,
        margin: format.isThermal ? pw.EdgeInsets.zero : const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return format.isThermal
              ? _buildThermalReceipt(receipt: receipt, gymInfo: gymInfo, dateFormat: dateFormat, hasPt: hasPt, baseFee: baseFee, format: format)
              : _buildStandardReceipt(receipt: receipt, gymInfo: gymInfo, dateFormat: dateFormat, hasPt: hasPt, baseFee: baseFee);
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildStandardReceipt({
    required ReceiptModel receipt,
    required GymInfoModel gymInfo,
    required DateFormat dateFormat,
    required bool hasPt,
    required double baseFee,
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
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    gymInfo.name.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    gymInfo.address,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    'Phone: ${gymInfo.phone}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                  if (gymInfo.website != null && gymInfo.website!.trim().isNotEmpty)
                    pw.Text(
                      'Website: ${gymInfo.website!.trim()}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey800),
                    ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'OFFICIAL RECEIPT',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          // Receipt Info Grid
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Receipt No: ${receipt.receiptNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Text('Date: ${dateFormat.format(receipt.paymentDate)}', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 10),

          // Member Details
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MEMBER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(receipt.memberName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(receipt.memberPhone, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Membership & PT Fee Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item / Plan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Validity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Payment Mode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      hasPt ? '${receipt.planName} (Base Plan)' : receipt.planName,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('${dateFormat.format(receipt.startDate)} - ${dateFormat.format(receipt.endDate)}', style: const pw.TextStyle(fontSize: 8)),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(receipt.paymentMethod, style: const pw.TextStyle(fontSize: 9))),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('₹${baseFee.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                  ),
                ],
              ),
              if (hasPt)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Personal Trainer: ${receipt.trainerName ?? "Assigned Trainer"}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Cycle PT', style: const pw.TextStyle(fontSize: 8)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(receipt.paymentMethod, style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('₹${receipt.personalTrainingFee.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('TOTAL PAID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('')),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('₹${receipt.amount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // QR Code & Status Footer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: receipt.qrPayload,
                    width: 55,
                    height: 55,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Scan to verify offline', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green700),
                    ),
                    child: pw.Text('STATUS: PAID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.green900)),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text('Thank you for choosing ${gymInfo.name}!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildThermalReceipt({
    required ReceiptModel receipt,
    required GymInfoModel gymInfo,
    required DateFormat dateFormat,
    required bool hasPt,
    required double baseFee,
    required PrintFormat format,
  }) {
    final qrSize = format == PrintFormat.thermal58 ? 100.0 : 120.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        ThermalLayout.center(gymInfo.name.toUpperCase(), fontSize: 12, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 3),
        ThermalLayout.center(gymInfo.address, fontSize: 8),
        ThermalLayout.center('Phone: ${gymInfo.phone}', fontSize: 8),
        pw.SizedBox(height: 6),
        ThermalLayout.center('*** OFFICIAL RECEIPT ***', fontSize: 9, fontWeight: pw.FontWeight.bold),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Receipt No', receipt.receiptNumber, bold: true),
        ThermalLayout.row('Date', dateFormat.format(receipt.paymentDate)),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row('Member', receipt.memberName, bold: true),
        ThermalLayout.row('Phone', receipt.memberPhone),
        ThermalLayout.dashedDivider(),

        ThermalLayout.row(hasPt ? '${receipt.planName} (Base)' : receipt.planName, '₹${baseFee.toStringAsFixed(0)}'),
        ThermalLayout.row('Validity', '${dateFormat.format(receipt.startDate)} - ${dateFormat.format(receipt.endDate)}', fontSize: 7.5),
        ThermalLayout.row('Payment Mode', receipt.paymentMethod),
        if (hasPt) ...[
          ThermalLayout.row('PT: ${receipt.trainerName ?? "Assigned Trainer"}', '₹${receipt.personalTrainingFee.toStringAsFixed(0)}'),
        ],
        ThermalLayout.dashedDivider(),
        ThermalLayout.row('TOTAL PAID', '₹${receipt.amount.toStringAsFixed(0)}', fontSize: 11, bold: true),
        ThermalLayout.dashedDivider(),

        pw.SizedBox(height: 4),
        ThermalLayout.center('STATUS: PAID', fontSize: 9, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: receipt.qrPayload, width: qrSize, height: qrSize),
        ),
        pw.SizedBox(height: 6),
        ThermalLayout.center('Scan to verify offline', fontSize: 7.5),
        ThermalLayout.dashedDivider(),

        pw.SizedBox(height: 4),
        ThermalLayout.center('Thank you for choosing', fontSize: 8, fontWeight: pw.FontWeight.bold),
        ThermalLayout.center(gymInfo.name, fontSize: 8, fontWeight: pw.FontWeight.bold),
        pw.SizedBox(height: 6),
      ],
    );
  }

  static Future<void> printReceipt({
    required ReceiptModel receipt,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
  }) async {
    final pdfBytes = await generateReceiptPdf(receipt: receipt, gymInfo: gymInfo, format: format);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => pdfBytes,
      name: 'Receipt_${receipt.receiptNumber}',
      format: format.pdfPageFormat,
      dynamicLayout: false,
      forceCustomPrintPaper: format.isThermal,
    );
  }

  static Future<void> shareReceipt({
    required ReceiptModel receipt,
    required GymInfoModel gymInfo,
    PrintFormat format = PrintFormat.a5,
  }) async {
    final pdfBytes = await generateReceiptPdf(receipt: receipt, gymInfo: gymInfo, format: format);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Receipt_${receipt.receiptNumber}.pdf',
    );
  }
}
