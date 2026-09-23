import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/receipt/receipt_pdf_service.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/gym_logo_view.dart';
import '../../shared/widgets/print_format_sheet.dart';
import 'qr_scanner_screen.dart';

class ReceiptPreviewScreen extends StatefulWidget {
  final ReceiptModel receipt;

  const ReceiptPreviewScreen({super.key, required this.receipt});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final _settingsRepo = SettingsRepository();
  GymInfoModel? _gymInfo;

  @override
  void initState() {
    super.initState();
    _loadGymInfo();
  }

  Future<void> _loadGymInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    setState(() => _gymInfo = gym);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RECEIPT #${widget.receipt.receiptNumber}'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner_rounded, color: AppTheme.neonLime),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QrScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            children: [
              // Digital Receipt Paper Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonLime.withValues(alpha: 0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              GymLogoView(
                                size: 48,
                                logoPath: _gymInfo?.logoPath,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (_gymInfo?.name ?? 'ELITE FITNESS GYM').toUpperCase(),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_gymInfo?.phone != null && _gymInfo!.phone.isNotEmpty)
                                      Text(
                                        _gymInfo!.phone,
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (_gymInfo?.website != null && _gymInfo!.website!.trim().isNotEmpty)
                                      Text(
                                        _gymInfo!.website!.trim(),
                                        style: TextStyle(fontSize: 11, color: AppTheme.neonLime),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.neonLime,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.darkBorder, height: 24),

                    _RowInfo(label: 'Receipt Number', value: widget.receipt.receiptNumber),
                    const SizedBox(height: 8),
                    _RowInfo(label: 'Member Name', value: widget.receipt.memberName),
                    const SizedBox(height: 8),
                    _RowInfo(label: 'Mobile Number', value: widget.receipt.memberPhone),
                    const SizedBox(height: 8),
                    _RowInfo(label: 'Plan Name', value: widget.receipt.planName),
                    if (widget.receipt.personalTrainingFee > 0) ...[
                      const SizedBox(height: 8),
                      _RowInfo(
                        label: 'Personal Trainer',
                        value: widget.receipt.trainerName ?? 'Assigned Trainer',
                      ),
                      const SizedBox(height: 8),
                      _RowInfo(
                        label: 'Base Plan Fee',
                        value: '₹${(widget.receipt.amount - widget.receipt.personalTrainingFee).toStringAsFixed(0)}',
                      ),
                      const SizedBox(height: 8),
                      _RowInfo(
                        label: 'Personal Training Fee',
                        value: '₹${widget.receipt.personalTrainingFee.toStringAsFixed(0)}',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _RowInfo(label: 'Payment Method', value: widget.receipt.paymentMethod),
                    const SizedBox(height: 8),
                    _RowInfo(label: 'Total Amount Paid', value: '₹${widget.receipt.amount.toStringAsFixed(0)}', isHighlight: true),
                    const Divider(color: AppTheme.darkBorder, height: 24),

                    // QR Code Image Center
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: widget.receipt.qrPayload,
                              version: QrVersions.auto,
                              size: 130.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tamper-Resistant QR Signature',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons Grid
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      text: 'Print Receipt',
                      icon: Icons.print_rounded,
                      onPressed: () async {
                        if (_gymInfo == null) return;
                        final format = await resolvePrintFormat(context, _gymInfo!);
                        if (format != null && mounted) {
                          ReceiptPdfService.printReceipt(receipt: widget.receipt, gymInfo: _gymInfo!, format: format);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      text: 'Share PDF',
                      icon: Icons.share_rounded,
                      isSecondary: true,
                      onPressed: () async {
                        if (_gymInfo == null) return;
                        final format = await resolvePrintFormat(context, _gymInfo!);
                        if (format != null && mounted) {
                          ReceiptPdfService.shareReceipt(receipt: widget.receipt, gymInfo: _gymInfo!, format: format);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const _RowInfo({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isHighlight ? AppTheme.neonLime : AppTheme.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: isHighlight ? 16 : 13,
            ),
          ),
        ),
      ],
    );
  }
}

