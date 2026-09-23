import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/billing/bill_pdf_service.dart';
import '../../core/billing/upi_service.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/status_badge.dart';
import '../payments/add_payment_screen.dart';

class BillDetailScreen extends StatefulWidget {
  final BillModel bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  final _billRepo = BillRepository();
  final _memberRepo = MemberRepository();
  final _settingsRepo = SettingsRepository();

  late BillModel _bill;
  GymInfoModel? _gymInfo;
  bool _isLoading = true;
  bool _isRecordingPayment = false;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _loadData();
  }

  Future<void> _loadData() async {
    final gym = await _settingsRepo.getGymInfo();
    final latestBill = await _billRepo.getBillById(_bill.id);
    if (mounted) {
      setState(() {
        _gymInfo = gym;
        if (latestBill != null) _bill = latestBill;
        _isLoading = false;
      });
    }
  }

  Future<void> _recordPayment() async {
    setState(() => _isRecordingPayment = true);
    final member = await _memberRepo.getMemberById(_bill.memberId);
    final membership = _bill.membershipId != null ? await _memberRepo.getMembershipById(_bill.membershipId!) : null;
    if (!mounted) return;
    setState(() => _isRecordingPayment = false);

    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member for this bill could not be found')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPaymentScreen(member: member, membership: membership, bill: _bill),
      ),
    );
    _loadData();
  }

  Future<void> _cancelBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Cancel This Bill?',
        message: 'This bill will be marked as cancelled and will no longer count towards outstanding dues.',
        confirmText: 'Cancel Bill',
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _billRepo.cancelBill(_bill.id);
      AppStateService.instance.notifyBillsChanged();
      _loadData();
    }
  }

  Future<void> _deleteBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Delete This Bill?',
        message: 'This cancelled bill will be permanently deleted. This action cannot be undone.',
        confirmText: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _billRepo.deleteCancelledBill(_bill.id);
      AppStateService.instance.notifyBillsChanged();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final gym = _gymInfo;
    final showUpi = gym != null && gym.showUpiQrOnBill && gym.hasUpiConfigured;
    final showBank = gym != null && gym.showBankDetailsOnBill && gym.hasBankDetailsConfigured;

    String? upiUri;
    if (showUpi) {
      upiUri = UpiService.buildPaymentUri(
        upiId: gym.upiId!,
        payeeName: (gym.upiPayeeName != null && gym.upiPayeeName!.trim().isNotEmpty) ? gym.upiPayeeName! : gym.name,
        amount: _bill.amount,
        note: 'Bill ${_bill.billNumber}',
        transactionRefId: _bill.billNumber,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('BILL #${_bill.billNumber}'),
        actions: [
          if (_bill.isDue)
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.statusOverdue),
              tooltip: 'Cancel Bill',
              onPressed: _cancelBill,
            ),
          if (_bill.isCancelled)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue),
              tooltip: 'Delete Bill',
              onPressed: _deleteBill,
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 32 + MediaQuery.paddingOf(context).bottom),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _bill.memberName,
                                      style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 18),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _bill.memberPhone,
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: _bill.status),
                            ],
                          ),
                          const Divider(color: AppTheme.darkBorder, height: 24),
                          _RowInfo(label: 'Bill Number', value: _bill.billNumber),
                          const SizedBox(height: 8),
                          _RowInfo(label: 'Plan', value: _bill.planName),
                          const SizedBox(height: 8),
                          _RowInfo(label: 'Bill Date', value: dateFormat.format(_bill.billDate)),
                          const SizedBox(height: 8),
                          _RowInfo(label: 'Due Date', value: dateFormat.format(_bill.dueDate)),
                          if (_bill.notes != null && _bill.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _RowInfo(label: 'Notes', value: _bill.notes!),
                          ],
                          const SizedBox(height: 8),
                          _RowInfo(
                            label: _bill.isPaid ? 'Amount Paid' : 'Amount Due',
                            value: '₹${_bill.amount.toStringAsFixed(0)}',
                            isHighlight: true,
                          ),

                          if (showUpi && upiUri != null) ...[
                            const Divider(color: AppTheme.darkBorder, height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: QrImageView(data: upiUri, version: QrVersions.auto, size: 150.0),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Scan with any UPI app to pay ₹${_bill.amount.toStringAsFixed(0)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    gym.upiId!,
                                    style: TextStyle(fontSize: 12, color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (showBank) ...[
                            const Divider(color: AppTheme.darkBorder, height: 24),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.darkBackground,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.darkBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('BANK TRANSFER DETAILS', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  if (gym.bankAccountHolder != null && gym.bankAccountHolder!.isNotEmpty) ...[
                                    _RowInfo(label: 'A/C Holder', value: gym.bankAccountHolder!),
                                    const SizedBox(height: 6),
                                  ],
                                  _RowInfo(label: 'A/C Number', value: gym.bankAccountNumber ?? '-'),
                                  const SizedBox(height: 6),
                                  _RowInfo(label: 'IFSC', value: gym.bankIfsc ?? '-'),
                                  if (gym.bankName != null && gym.bankName!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _RowInfo(label: 'Bank', value: gym.bankName!),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_bill.isDue)
                      NeonButton(
                        text: _isRecordingPayment ? 'Loading...' : 'Record Payment',
                        icon: Icons.add_card_rounded,
                        width: double.infinity,
                        isLoading: _isRecordingPayment,
                        onPressed: _recordPayment,
                      ),
                    if (_bill.isDue) const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            text: 'Print Bill',
                            icon: Icons.print_rounded,
                            isSecondary: true,
                            onPressed: () {
                              if (_gymInfo != null) {
                                BillPdfService.printBill(bill: _bill, gymInfo: _gymInfo!);
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
                            onPressed: () {
                              if (_gymInfo != null) {
                                BillPdfService.shareBill(bill: _bill, gymInfo: _gymInfo!);
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
