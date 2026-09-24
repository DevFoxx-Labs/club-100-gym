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
import '../../data/repositories/member_repository.dart';
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
  final _memberRepo = MemberRepository();
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

  @override
  void initState() {
    super.initState();
    _ptFee = widget.membership?.personalTrainingFee ?? 0.0;
    final totalFee = widget.membership?.feeAmount ?? 1500.0;
    _baseFee = (totalFee > _ptFee) ? (totalFee - _ptFee) : 0.0;

    _amountController = TextEditingController(
      text: widget.bill != null ? widget.bill!.amount.toStringAsFixed(0) : totalFee.toStringAsFixed(0),
    );
    _amountController.addListener(_onAmountChanged);
    _notesController = TextEditingController();

    if (widget.membership != null) {
      // Preserve the membership's actual plan length (30/90/180/365 days) so
      // the receipt's validity span matches the plan, not a hardcoded month.
      final cycleDuration = widget.membership!.endDate.difference(widget.membership!.startDate);

      if (widget.bill != null) {
        // Settling a specific bill: the receipt must cover exactly the cycle
        // that bill was raised for (its dueDate is that cycle's start date),
        // e.g. the first bill raised on onboarding is due on the membership's
        // own start date, not on its end date.
        _startDate = widget.bill!.dueDate;
      } else {
        // Ad-hoc renewal with no linked bill: extend from the current cycle's
        // end date, or from today if the membership has already lapsed.
        _startDate = widget.membership!.endDate.isBefore(DateTime.now())
            ? DateTime.now()
            : widget.membership!.endDate;
      }
      _endDate = _startDate.add(cycleDuration);

      if (widget.membership!.trainerId != null && widget.membership!.trainerId!.isNotEmpty) {
        _loadTrainer(widget.membership!.trainerId!);
      }
      _resolveBasePlanFee();
    }

    _loadReceiptNumber();
  }

  void _onAmountChanged() {
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (_ptFee > 0) {
      final updatedBase = (enteredAmount >= _ptFee) ? (enteredAmount - _ptFee) : 0.0;
      if (updatedBase != _baseFee && mounted) {
        setState(() {
          _baseFee = updatedBase;
        });
      }
    }
  }

  Future<void> _resolveBasePlanFee() async {
    if (widget.membership == null) return;
    if (_baseFee <= 0) {
      final plan = await _planRepo.getPlanById(widget.membership!.planId);
      if (plan != null && plan.defaultFee > 0) {
        if (mounted) {
          setState(() {
            _baseFee = plan.defaultFee;
            final correctedTotal = _baseFee + _ptFee;
            _amountController.text = correctedTotal.toStringAsFixed(0);
          });
        }
      }
    }
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

      // Resolve the bill being settled (explicit, or the oldest outstanding
      // bill for this membership) up front so its number can be stamped on
      // the receipt itself.
      final targetBill = widget.bill ??
          (widget.membership != null ? await _billRepo.getOldestDueBillForMembership(widget.membership!.id) : null);

      final receipt = ReceiptModel(
        id: receiptId,
        paymentId: paymentId,
        receiptNumber: _generatedReceiptNo,
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

      final finalReceipt = receipt.copyWith(qrPayload: qrPayload);

      final payment = PaymentModel(
        id: paymentId,
        memberId: widget.member.id,
        membershipId: widget.membership?.id,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        receiptId: receiptId,
        receiptNumber: _generatedReceiptNo,
        createdAt: now,
        updatedAt: now,
        memberName: widget.member.name,
      );

      // Extend membership and safely preserve trainer and PT fee
      if (widget.membership != null) {
        final updatedMembership = widget.membership!.copyWith(
          startDate: _startDate,
          endDate: _endDate,
          feeAmount: amount,
          status: 'Active',
          trainerId: widget.membership!.trainerId,
          personalTrainingFee: effectivePtFee,
          packageId: widget.membership!.packageId,
          updatedAt: now,
        );
        await _memberRepo.updateMembership(updatedMembership);
      }

      await _paymentRepo.addPayment(payment, finalReceipt);

      // Settle the linked bill resolved above
      if (targetBill != null) {
        await _billRepo.markBillPaid(billId: targetBill.id, paymentId: paymentId, receiptId: receiptId);
        AppStateService.instance.notifyBillsChanged();
      }

      // Trigger app-wide reactive state updates
      AppStateService.instance.notifyPaymentsChanged();
      AppStateService.instance.notifyMembersChanged();

      if (mounted) setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: finalReceipt)),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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

                // Bill Being Settled Banner
                if (widget.bill != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('add_payment_settling_bill', {'number': widget.bill!.billNumber}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ),
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
                  validator: (v) => FormValidators.validateAmount(v, fieldName: tr('add_payment_amount_field')),
                ),
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
                              if (picked != null) setState(() => _startDate = picked);
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
                              if (picked != null) setState(() => _endDate = picked);
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
