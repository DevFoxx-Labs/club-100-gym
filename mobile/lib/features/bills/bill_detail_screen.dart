import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/billing/bill_pdf_service.dart';
import '../../core/billing/upi_service.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/print_format_sheet.dart';
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
  DateTime? _periodStart;
  DateTime? _periodEnd;
  bool _isLoading = true;
  bool _isRecordingPayment = false;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _loadData();
  }

  Future<void> _loadData() async {
    final gym = await _settingsRepo.getGymInfo();
    final latestBill = await _billRepo.getBillById(_bill.id);
    final bill = latestBill ?? _bill;
    final membership = bill.membershipId != null ? await _memberRepo.getMembershipById(bill.membershipId!) : null;
    if (mounted) {
      setState(() {
        _gymInfo = gym;
        _bill = bill;
        _periodStart = membership?.startDate;
        _periodEnd = membership?.endDate;
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
        SnackBar(content: Text(tr('bill_detail_member_not_found'))),
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
      builder: (ctx) => ConfirmationDialog(
        title: tr('bill_detail_cancel_title'),
        message: tr('bill_detail_cancel_message'),
        confirmText: tr('bill_detail_cancel_confirm'),
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _billRepo.cancelBill(_bill.id);
      AppStateService.instance.notifyBillsChanged();
      _loadData();
    }
  }

  Future<void> _resumeFromToday() async {
    final dateFormat = DateFormat('dd MMM yyyy');
    DateTime resumeDate = DateTime.now();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final bottomInset = MediaQuery.paddingOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + (bottomInset > 0 ? bottomInset : 10)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('bill_detail_resume_sheet_title'),
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr('bill_detail_resume_sheet_message', {
                      'amount': _bill.amount.toStringAsFixed(0),
                      'date': dateFormat.format(_bill.dueDate),
                    }),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    tr('bill_detail_resume_date_label'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: resumeDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null && mounted) setSheetState(() => resumeDate = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.neonLime),
                          const SizedBox(width: 10),
                          Text(dateFormat.format(resumeDate), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: NeonButton(
                          text: tr('common_cancel'),
                          isSecondary: true,
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: NeonButton(
                          text: tr('bill_detail_resume_confirm'),
                          icon: Icons.restart_alt_rounded,
                          onPressed: () => Navigator.pop(ctx, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResuming = true);
    final newBill = await _billRepo.resumeBillFromToday(_bill, resumeDate: resumeDate);
    AppStateService.instance.notifyBillsChanged();
    if (!mounted) return;
    setState(() => _isResuming = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('bill_detail_resume_success', {'number': newBill.billNumber}))),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BillDetailScreen(bill: newBill)),
    );
  }

  Future<void> _deleteBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: tr('bill_detail_delete_title'),
        message: tr('bill_detail_delete_message'),
        confirmText: tr('common_delete'),
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
        title: Text(tr('bill_detail_appbar_title', {'number': _bill.billNumber})),
        actions: [
          // Only fully-unpaid bills can be cancelled — once a partial payment
          // has been received against a bill, cancelling it would orphan that
          // payment record, so the option is hidden.
          if (_bill.status == 'Pending' || _bill.status == 'Overdue')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.statusOverdue),
              tooltip: tr('bill_detail_cancel_confirm'),
              onPressed: _cancelBill,
            ),
          if (_bill.isCancelled)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue),
              tooltip: tr('bill_detail_delete_tooltip'),
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
                              StatusBadge(status: _bill.status, label: tr('bill_status_${_bill.status.toLowerCase()}')),
                            ],
                          ),
                          const Divider(color: AppTheme.darkBorder, height: 24),
                          _RowInfo(label: tr('bill_detail_bill_number'), value: _bill.billNumber),
                          const SizedBox(height: 8),
                          _RowInfo(label: tr('bill_detail_plan'), value: _bill.planName),
                          const SizedBox(height: 8),
                          _RowInfo(label: tr('bill_detail_bill_date'), value: dateFormat.format(_bill.billDate)),
                          const SizedBox(height: 8),
                          _RowInfo(label: tr('bill_detail_due_date'), value: dateFormat.format(_bill.dueDate)),
                          if (_bill.notes != null && _bill.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _RowInfo(label: tr('bill_detail_notes'), value: _bill.notes!),
                          ],
                          const SizedBox(height: 8),
                          _RowInfo(
                            label: tr('bill_detail_bill_amount'),
                            value: '₹${_bill.amount.toStringAsFixed(0)}',
                            isHighlight: _bill.paidAmount <= 0,
                          ),
                          if (_bill.paidAmount > 0) ...[
                            const SizedBox(height: 8),
                            _RowInfo(label: tr('bill_detail_amount_paid'), value: '₹${_bill.paidAmount.toStringAsFixed(0)}'),
                            const SizedBox(height: 8),
                            _RowInfo(
                              label: tr('bill_detail_balance_remaining'),
                              value: '₹${_bill.remainingBalance.toStringAsFixed(0)}',
                              isHighlight: true,
                            ),
                          ],

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
                                    tr('bill_detail_scan_upi', {'amount': _bill.amount.toStringAsFixed(0)}),
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
                                  Text(tr('bill_detail_bank_transfer_details'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                  const SizedBox(height: 8),
                                  if (gym.bankAccountHolder != null && gym.bankAccountHolder!.isNotEmpty) ...[
                                    _RowInfo(label: tr('bill_detail_ac_holder'), value: gym.bankAccountHolder!),
                                    const SizedBox(height: 6),
                                  ],
                                  _RowInfo(label: tr('bill_detail_ac_number'), value: gym.bankAccountNumber ?? '-'),
                                  const SizedBox(height: 6),
                                  _RowInfo(label: tr('bill_detail_ifsc'), value: gym.bankIfsc ?? '-'),
                                  if (gym.bankName != null && gym.bankName!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    _RowInfo(label: tr('bill_detail_bank'), value: gym.bankName!),
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
                        text: _isRecordingPayment ? tr('common_loading') : tr('bill_detail_record_payment'),
                        icon: Icons.add_card_rounded,
                        width: double.infinity,
                        isLoading: _isRecordingPayment,
                        onPressed: _recordPayment,
                      ),
                    if (_bill.isDue) const SizedBox(height: 12),
                    if (_bill.status == 'Overdue')
                      NeonButton(
                        text: _isResuming ? tr('common_loading') : tr('bill_detail_resume_from_today'),
                        icon: Icons.restart_alt_rounded,
                        width: double.infinity,
                        isSecondary: true,
                        isLoading: _isResuming,
                        onPressed: _resumeFromToday,
                      ),
                    if (_bill.status == 'Overdue') const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            text: tr('bill_detail_print_bill'),
                            icon: Icons.print_rounded,
                            isSecondary: true,
                            onPressed: () async {
                              if (_gymInfo == null) return;
                              final format = await resolvePrintFormat(context, _gymInfo!);
                              if (format != null && mounted) {
                                BillPdfService.printBill(
                                  bill: _bill,
                                  gymInfo: _gymInfo!,
                                  format: format,
                                  periodStart: _periodStart,
                                  periodEnd: _periodEnd,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeonButton(
                            text: tr('bill_detail_share_pdf'),
                            icon: Icons.share_rounded,
                            isSecondary: true,
                            onPressed: () async {
                              if (_gymInfo == null) return;
                              final format = await resolvePrintFormat(context, _gymInfo!);
                              if (format != null && mounted) {
                                BillPdfService.shareBill(
                                  bill: _bill,
                                  gymInfo: _gymInfo!,
                                  format: format,
                                  periodStart: _periodStart,
                                  periodEnd: _periodEnd,
                                );
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
