import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/receipt/qr_service.dart';
import '../../data/repositories/payment_repository.dart';

enum _VerifyOutcome { valid, notFound, invalid }

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _paymentRepo = PaymentRepository();
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        _verifyPayload(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _verifyPayload(String rawPayload) async {
    final result = QrService.verifyQrPayload(rawPayload);

    // A matching signature only proves the QR content wasn't tampered with —
    // it says nothing about whether the receipt still exists on this device.
    // Since the signing secret is baked into every install, a receipt QR from
    // any copy of the app (including one wiped/reinstalled) would otherwise
    // "verify" forever. Cross-check against the local receipts table too.
    var outcome = _VerifyOutcome.invalid;
    if (result != null) {
      final recNo = result['recNo'] as String?;
      final receipt = recNo != null ? await _paymentRepo.getReceiptByNumber(recNo) : null;
      final matches = receipt != null &&
          receipt.memberName == result['member'] &&
          receipt.amount == (result['amount'] as num).toDouble();
      outcome = matches ? _VerifyOutcome.valid : _VerifyOutcome.notFound;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              outcome == _VerifyOutcome.valid ? Icons.verified_rounded : Icons.error_rounded,
              color: outcome == _VerifyOutcome.valid ? AppTheme.neonLime : AppTheme.statusOverdue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                switch (outcome) {
                  _VerifyOutcome.valid => 'VALID RECEIPT ✓',
                  _VerifyOutcome.notFound => 'NOT FOUND IN SYSTEM',
                  _VerifyOutcome.invalid => 'INVALID / TAMPERED',
                },
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: outcome == _VerifyOutcome.valid ? AppTheme.neonLime : AppTheme.statusOverdue,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: outcome == _VerifyOutcome.valid
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receipt No: ${result!['recNo']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  Text('Member: ${result['member']}', style: const TextStyle(color: AppTheme.textWhite)),
                  Text('Amount: ₹${result['amount']}', style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
                  Text('Plan: ${result['plan']}', style: const TextStyle(color: AppTheme.textMuted)),
                  Text('Date: ${result['date']}', style: const TextStyle(color: AppTheme.textMuted)),
                ],
              )
            : Text(
                outcome == _VerifyOutcome.notFound
                    ? 'This receipt\'s signature is genuine, but no matching record exists in this app\'s current data. It may have been deleted, or the app data was reset/reinstalled since this receipt was generated.'
                    : 'This QR signature could not be verified. The receipt data may have been altered or generated outside Elite Fitness Gym.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanned = false);
            },
            child: const Text('Scan Another'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OFFLINE QR VERIFIER'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neonLime, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: const Text(
                'Align receipt QR code within frame to verify authenticity offline.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textWhite, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

