import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_translations.dart';
import '../../core/receipt/qr_service.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../receipts/receipt_preview_screen.dart';

class AddPaymentScreen extends StatefulWidget {
  final MemberModel member;
  final MembershipModel? membership;
  final BillModel? bill;

  const AddPaymentScreen({
    super.key,
    required this.member,
    this.membership,
    this.bill,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentRepo = PaymentRepository();
  final _billRepo = BillRepository();
  final _trainerRepo = TrainerRepository();
  final _planRepo = PlanRepository();

  late TextEditingController _amountController;
  late TextEditingController _notesController;

  TrainerModel? _trainer;
  String? _trainerName;
  double _ptFee = 0.0;
  double _baseFee = 0.0;

  String _paymentMethod = 'Cash';
  final DateTime _paymentDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String _generatedReceiptNo = '';

  // The bill this payment will be applied to, if any — used to show the
  // total/already-paid/remaining breakdown and to cap the entered amount so
  // a partial payment can never overshoot what's actually still owed.
  BillModel? _resolvedBill;

  // Full fee for one cycle of this membership (plan + PT). When no bill exists
  // yet, paying less than this is a part payment: a bill for the full fee is
  // raised on save so the remaining balance stays tracked.
  double _membershipFee = 0.0;

  @override
  void initState() {
    super.initState();
    _ptFee = widget.membership?.personalTrainingFee ?? 0.0;
    final totalFee = widget.membership?.feeAmount ?? 1500.0;
    _membershipFee = totalFee;
    _baseFee = (totalFee > _ptFee) ? (totalFee - _ptFee) : 0.0;

    _resolvedBill = widget.bill;
    final initialAmount = _resolvedBill != null ? _resolvedBill!.remainingBalance : totalFee;
    _amountController = TextEditingController(text: _fmt(initialAmount));
    _amountController.addListener(_onAmountChanged);
    _notesController = TextEditingController();

    if (widget.membership != null) {
      if (widget.bill != null) {
        // Settling a specific bill: the receipt must cover exactly the cycle
        // that bill was raised for (its dueDate is that cycle's start date),
        // e.g. the first bill raised on onboarding is due on the membership's
        // own start date, not on its end date.
        _applyDatesForBill(widget.bill!);
      } else {
        // No bill passed in yet — assume an ad-hoc renewal (extend from the
        // current cycle's end date, or from today if already lapsed) until
        // the async lookup below finds a real outstanding bill to anchor on.
        _applyDatesForRenewal();
      }

      if (widget.membership!.trainerId != null && widget.membership!.trainerId!.isNotEmpty) {
        _loadTrainer(widget.membership!.trainerId!);
      }
      _resolveBasePlanFee();

      // No bill was passed in explicitly — look up the oldest outstanding
      // bill for this membership so a second/third partial payment made from
      // a generic "Add Payment" entry point (e.g. member profile) still
      // settles the SAME bill/cycle instead of extending membership dates
      // again on top of what an earlier partial payment already granted.
      if (widget.bill == null) {
        _resolveOutstandingBill();
      }
    }

    _loadReceiptNumber();
  }

  /// Formats money without trailing ".00" but keeps paise when present, so a
  /// ₹333.33 balance can actually be paid off instead of leaving ₹0.33 open.
  static String _fmt(double v) =>
      (v - v.roundToDouble()).abs() < 0.005 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double get _enteredAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;

  /// What is owed before this payment: the bill's remaining balance, or the
  /// full cycle fee when no bill exists yet.
  double get _owedBefore => _resolvedBill?.remainingBalance ?? _membershipFee;

  double get _balanceAfter {
    final left = _owedBefore - _enteredAmount;
    return left < 0.01 ? 0.0 : left;
  }

  /// True when this payment leaves part of the cycle fee unpaid.
  bool get _isPartial => widget.membership != null && _enteredAmount > 0 && _enteredAmount < _owedBefore - 0.01;

  // Preserves the membership's actual plan length (30/90/180/365 days) so
  // the receipt's validity span matches the plan, not a hardcoded month.
  void _applyDatesForBill(BillModel bill) {
    final cycleDuration = widget.membership!.endDate.difference(widget.membership!.startDate);
    _startDate = bill.dueDate;
    _endDate = _startDate.add(cycleDuration);
  }

  void _applyDatesForRenewal() {
    final cycleDuration = widget.membership!.endDate.difference(widget.membership!.startDate);
    _startDate = widget.membership!.endDate.isBefore(DateTime.now()) ? DateTime.now() : widget.membership!.endDate;
    _endDate = _startDate.add(cycleDuration);
  }

  Future<void> _resolveOutstandingBill() async {
    if (widget.membership == null) return;
    final bill = await _billRepo.getOldestDueBillForMembership(widget.membership!.id);
    if (bill != null && mounted) {
      setState(() {
        _resolvedBill = bill;
        _amountController.text = _fmt(bill.remainingBalance);
        // A real outstanding bill was found after all — anchor the
        // membership period on it instead of the ad-hoc renewal guess above,
        // so this payment settles that bill's cycle exactly once.
        _applyDatesForBill(bill);
      });
    }
  }

  void _onAmountChanged() {
    if (!mounted) return;
    setState(() {
      // With no bill, an amount ABOVE the cycle fee is a custom price for
      // this cycle, so the plan/PT breakdown follows it. A smaller amount is a
      // part payment and must not shrink the fee breakdown.
      final entered = _enteredAmount;
      if (_resolvedBill == null && _ptFee > 0 && entered > _membershipFee) {
        _baseFee = entered - _ptFee;
      }
    });
  }

  Future<void> _resolveBasePlanFee() async {
    if (widget.membership == null) return;
    if (_baseFee <= 0) {
      final plan = await _planRepo.getPlanById(widget.membership!.planId);
      if (plan != null && plan.defaultFee > 0) {
        if (mounted) {
          setState(() {
            _baseFee = plan.defaultFee;
            _membershipFee = _baseFee + _ptFee;
            // Never overwrite a bill's remaining balance with the plan fee.
            if (_resolvedBill == null) {
              _amountController.text = _fmt(_membershipFee);
            }
          });
        }
      }
    }
  }

  void _setAmount(double value) {
    _amountController.text = _fmt(value);
    _amountController.selection = TextSelection.collapsed(offset: _amountController.text.length);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainer(String trainerId) async {
    try {
      final trainer = await _trainerRepo.getTrainerById(trainerId);
      if (mounted && trainer != null) {
        setState(() {
          _trainer = trainer;
          _trainerName = trainer.name;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReceiptNumber() async {
    final recNo = await _paymentRepo.generateNextReceiptNumber();
    if (mounted) {
      setState(() => _generatedReceiptNo = recNo);
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final paymentId = uuid.v4();
      final receiptId = uuid.v4();
      final amount = double.parse(_amountController.text.trim());
      final effectivePtFee = (_ptFee <= amount) ? _ptFee : amount;
      // Re-generate right before saving: the number shown on screen may have
      // been taken meanwhile (e.g. by a receipt synced from another phone).
      final receiptNumber = await _paymentRepo.generateNextReceiptNumber();

      // Resolve the bill being settled (explicit, or the oldest outstanding
      // bill for this membership) up front so its number can be stamped on
      // the receipt itself.
      BillModel? targetBill = _resolvedBill ??
          (widget.membership != null ? await _billRepo.getOldestDueBillForMembership(widget.membership!.id) : null);

      // Part payment with no bill for this cycle yet: raise one for the FULL
      // cycle fee so the unpaid balance is tracked, reminded and shown
      // everywhere instead of silently disappearing.
      BillModel? newBill;
      if (targetBill == null && widget.membership != null && amount < _membershipFee - 0.01) {
        newBill = BillModel(
          id: uuid.v4(),
          billNumber: await _billRepo.generateNextBillNumber(),
          memberId: widget.member.id,
          memberName: widget.member.name,
          memberPhone: widget.member.phone,
          membershipId: widget.membership!.id,
          planName: widget.membership!.planName,
          amount: _membershipFee,
          billDate: now,
          dueDate: _startDate,
          status: 'Pending',
          isAutoGenerated: false,
          cycleKey: BillRepository.cycleKeyFor(widget.membership!.id, _startDate),
          createdAt: now,
          updatedAt: now,
        );
        targetBill = newBill;
      }

      final receipt = ReceiptModel(
        id: receiptId,
        paymentId: paymentId,
        receiptNumber: receiptNumber,
        billNumber: targetBill?.billNumber,
        memberName: widget.member.name,
        memberPhone: widget.member.phone,
        planName: widget.membership?.planName ?? tr('add_payment_monthly_membership'),
        trainerName: _trainerName ?? _trainer?.name,
        personalTrainingFee: effectivePtFee,
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _paymentDate,
        startDate: _startDate,
        endDate: _endDate,
        qrPayload: '',
        createdAt: now,
      );

      final qrPayload = QrService.generateQrPayload(receipt);

      final payment = PaymentModel(
        id: paymentId,
        memberId: widget.member.id,
        membershipId: widget.membership?.id,
        billId: targetBill?.id,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        receiptId: receiptId,
        receiptNumber: receiptNumber,
        createdAt: now,
        updatedAt: now,
        memberName: widget.member.name,
      );

      // Membership becomes active for the full cycle, keeping trainer and the
      // full PT fee intact even when only part of the fee was paid now.
      final updatedMembership = widget.membership?.copyWith(
        startDate: _startDate,
        endDate: _endDate,
        // The membership's fee should always reflect the bill's full cycle
        // amount, not just whatever partial amount was paid just now.
        feeAmount: targetBill?.amount ?? amount,
        status: 'Active',
        trainerId: widget.membership!.trainerId,
        personalTrainingFee: widget.membership!.personalTrainingFee,
        packageId: widget.membership!.packageId,
        updatedAt: now,
      );

      final savedReceipt = await _paymentRepo.recordPayment(
        payment: payment,
        receipt: receipt.copyWith(qrPayload: qrPayload),
        updatedMembership: updatedMembership,
        newBill: newBill,
        settleBillId: targetBill?.id,
      );

      // Trigger app-wide reactive state updates
      if (targetBill != null) AppStateService.instance.notifyBillsChanged();
      AppStateService.instance.notifyPaymentsChanged();
      AppStateService.instance.notifyMembersChanged();

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: savedReceipt)),
      );
    } on PaymentRejected catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final message = switch (e.reason) {
        PaymentRejectedReason.exceedsBalance =>
          tr('add_payment_amount_exceeds_balance', {'amount': _fmt(e.remaining ?? 0)}),
        PaymentRejectedReason.billClosed => tr('add_payment_bill_closed'),
        PaymentRejectedReason.billNotFound => tr('add_payment_bill_closed'),
      };
      _showError(message);
      // The bill changed underneath us — reload it so the screen is accurate.
      if (widget.membership != null) {
        _resolvedBill = null;
        _resolveOutstandingBill();
      }
    } catch (e, stackTrace) {
      debugPrint('[AddPaymentScreen] payment failed: $e\n$stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(tr('add_payment_failed'));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.statusOverdue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final hasPersonalTrainer = _ptFee > 0 || _trainer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('add_payment_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Card Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.neonLime,
                        child: Text(
                          widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : 'M',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBackground),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.member.name, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(widget.member.phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bill / cycle summary — what this payment is for and how much is
                // owed BEFORE it, so a part payment is always made knowingly.
                if (_resolvedBill != null || widget.membership != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _resolvedBill != null
                                    ? tr('add_payment_settling_bill', {'number': _resolvedBill!.billNumber})
                                    : tr('add_payment_cycle_fee_title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w800, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.darkBorder, height: 20),
                        if (_resolvedBill != null) ...[
                          _BillAmountRow(label: tr('add_payment_bill_total'), amount: _resolvedBill!.amount),
                          if (_resolvedBill!.paidAmount > 0) ...[
                            const SizedBox(height: 4),
                            _BillAmountRow(label: tr('add_payment_already_paid'), amount: _resolvedBill!.paidAmount),
                          ],
                          const SizedBox(height: 4),
                          _BillAmountRow(
                            label: tr('add_payment_balance_remaining'),
                            amount: _resolvedBill!.remainingBalance,
                            highlight: true,
                          ),
                        ] else
                          _BillAmountRow(label: tr('add_payment_cycle_fee'), amount: _membershipFee, highlight: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Personal Training Fee Breakdown Banner
                if (hasPersonalTrainer) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fitness_center_rounded, color: AppTheme.neonLime, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              tr('add_payment_pt_included'),
                              style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('add_payment_assigned_trainer'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text(
                              _trainerName ?? _trainer?.name ?? tr('add_payment_personal_trainer_fallback'),
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('add_payment_base_plan_fee'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text('₹${_baseFee.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('add_payment_pt_fee'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                            Text('₹${_ptFee.toStringAsFixed(0)}', style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const Divider(color: AppTheme.darkBorder, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('add_payment_total_plan_pt_due'), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '₹${(_baseFee + _ptFee).toStringAsFixed(0)}',
                              style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Receipt Number Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tr('add_payment_receipt_no'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                    Text(
                      _generatedReceiptNo,
                      style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: tr('add_payment_amount_label'),
                  hint: '1500',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final basicError = FormValidators.validateAmount(v, fieldName: tr('add_payment_amount_field'));
                    if (basicError != null) return basicError;
                    final bill = _resolvedBill;
                    if (bill != null) {
                      final entered = double.tryParse(v!.trim()) ?? 0;
                      if (entered > bill.remainingBalance + 0.01) {
                        return tr('add_payment_amount_exceeds_balance', {'amount': bill.remainingBalance.toStringAsFixed(0)});
                      }
                    }
                    return null;
                  },
                ),
                if (widget.membership != null && _owedBefore > 0) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: Icon(Icons.done_all_rounded, size: 16, color: AppTheme.neonLime),
                        label: Text(tr('add_payment_chip_full', {'amount': _fmt(_owedBefore)})),
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 12),
                        onPressed: () => _setAmount(_owedBefore),
                      ),
                      ActionChip(
                        avatar: Icon(Icons.call_split_rounded, size: 16, color: AppTheme.neonLime),
                        label: Text(tr('add_payment_chip_half', {'amount': _fmt((_owedBefore / 2).roundToDouble())})),
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600, fontSize: 12),
                        onPressed: () => _setAmount((_owedBefore / 2).roundToDouble()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isPartial
                          ? AppTheme.statusDueSoon.withValues(alpha: 0.12)
                          : AppTheme.neonLime.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isPartial
                            ? AppTheme.statusDueSoon.withValues(alpha: 0.4)
                            : AppTheme.neonLime.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BillAmountRow(
                          label: tr('add_payment_balance_after'),
                          amount: _balanceAfter,
                          highlight: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          !_isPartial
                              ? tr('add_payment_will_be_fully_paid')
                              : (_resolvedBill != null
                                  ? tr('add_payment_partial_note', {'amount': _fmt(_balanceAfter)})
                                  : tr('add_payment_partial_new_bill_note', {
                                      'total': _fmt(_membershipFee),
                                      'amount': _fmt(_balanceAfter),
                                    })),
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                Text(tr('add_payment_method'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Other'].map((m) {
                    final selected = _paymentMethod == m;
                    return FilterChip(
                      selected: selected,
                      label: Text(tr('payment_method_${m.toLowerCase().replaceAll(' ', '_')}')),
                      selectedColor: AppTheme.neonLime,
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: TextStyle(color: selected ? AppTheme.darkBackground : AppTheme.textWhite, fontWeight: FontWeight.bold),
                      onSelected: (val) => setState(() => _paymentMethod = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('add_payment_new_start_date'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null && mounted) setState(() => _startDate = picked);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppTheme.darkBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
                              child: Text(dateFormat.format(_startDate), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('add_payment_new_end_date'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null && mounted) setState(() => _endDate = picked);
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppTheme.darkBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
                              child: Text(dateFormat.format(_endDate), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: tr('add_payment_notes_label'),
                  hint: tr('add_payment_notes_hint'),
                  controller: _notesController,
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: tr('add_payment_save_button'),
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _processPayment,
                ),
                SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BillAmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool highlight;

  const _BillAmountRow({required this.label, required this.amount, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${_AddPaymentScreenState._fmt(amount)}',
          style: TextStyle(
            color: highlight ? AppTheme.neonLime : AppTheme.textWhite,
            fontWeight: FontWeight.w800,
            fontSize: highlight ? 14 : 12.5,
          ),
        ),
      ],
    );
  }
}
