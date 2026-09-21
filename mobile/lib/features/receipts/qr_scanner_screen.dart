import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../core/receipt/qr_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
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

  void _verifyPayload(String rawPayload) {
    final result = QrService.verifyQrPayload(rawPayload);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result != null ? Icons.verified_rounded : Icons.error_rounded,
              color: result != null ? AppTheme.neonLime : AppTheme.statusOverdue,
            ),
            const SizedBox(width: 10),
            Text(
              result != null ? 'VALID RECEIPT ✓' : 'INVALID / TAMPERED',
              style: TextStyle(
                color: result != null ? AppTheme.neonLime : AppTheme.statusOverdue,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: result != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receipt No: ${result['recNo']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  Text('Member: ${result['member']}', style: const TextStyle(color: AppTheme.textWhite)),
                  Text('Amount: ₹${result['amount']}', style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
                  Text('Plan: ${result['plan']}', style: const TextStyle(color: AppTheme.textMuted)),
                  Text('Date: ${result['date']}', style: const TextStyle(color: AppTheme.textMuted)),
                ],
              )
            : const Text(
                'This QR signature could not be verified. The receipt data may have been altered or generated outside Elite Fitness Gym.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
            bottom: 40,
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

