import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/receipt/qr_service.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/receipt_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../receipts/receipt_preview_screen.dart';

class AddPaymentScreen extends StatefulWidget {
  final MemberModel member;
  final MembershipModel? membership;

  const AddPaymentScreen({
    super.key,
    required this.member,
    this.membership,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentRepo = PaymentRepository();
  final _memberRepo = MemberRepository();

  late TextEditingController _amountController;
  late TextEditingController _notesController;

  String _paymentMethod = 'Cash';
  final DateTime _paymentDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;
  String _generatedReceiptNo = '';

  @override
  void initState() {
    super.initState();
    final defaultAmount = widget.membership?.feeAmount ?? 1500.0;
    _amountController = TextEditingController(text: defaultAmount.toStringAsFixed(0));
    _notesController = TextEditingController();

    if (widget.membership != null) {
      _startDate = widget.membership!.endDate.isBefore(DateTime.now())
          ? DateTime.now()
          : widget.membership!.endDate;
      _endDate = _startDate.add(const Duration(days: 30));
    }

    _loadReceiptNumber();
  }

  Future<void> _loadReceiptNumber() async {
    final recNo = await _paymentRepo.generateNextReceiptNumber();
    setState(() => _generatedReceiptNo = recNo);
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

      final receipt = ReceiptModel(
        id: receiptId,
        paymentId: paymentId,
        receiptNumber: _generatedReceiptNo,
        memberName: widget.member.name,
        memberPhone: widget.member.phone,
        planName: widget.membership?.planName ?? 'Monthly Membership',
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _paymentDate,
        startDate: _startDate,
        endDate: _endDate,
        qrPayload: '',
        createdAt: now,
      );

      final qrPayload = QrService.generateQrPayload(receipt);

      final finalReceipt = ReceiptModel(
        id: receiptId,
        paymentId: paymentId,
        receiptNumber: _generatedReceiptNo,
        memberName: widget.member.name,
        memberPhone: widget.member.phone,
        planName: widget.membership?.planName ?? 'Monthly Membership',
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: _paymentDate,
        startDate: _startDate,
        endDate: _endDate,
        qrPayload: qrPayload,
        createdAt: now,
      );

      final payment = PaymentModel(
        id: paymentId,
        memberId: widget.member.id,
        membershipId: widget.membership?.id,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
        receiptId: receiptId,
        receiptNumber: _generatedReceiptNo,
        createdAt: now,
        updatedAt: now,
      );

      // Extend or create new membership
      if (widget.membership != null) {
        final updatedMembership = MembershipModel(
          id: widget.membership!.id,
          memberId: widget.member.id,
          planId: widget.membership!.planId,
          planName: widget.membership!.planName,
          startDate: _startDate,
          endDate: _endDate,
          feeAmount: amount,
          status: 'Active',
          createdAt: widget.membership!.createdAt,
          updatedAt: now,
        );
        await _memberRepo.updateMembership(updatedMembership);
      }

      await _paymentRepo.addPayment(payment, finalReceipt);

      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: finalReceipt)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADD PAYMENT & RECEIPT'),
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
                        child: Text(widget.member.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkBackground)),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.member.name, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(widget.member.phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Receipt Number Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RECEIPT NO:', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                    Text(
                      _generatedReceiptNo,
                      style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Payment Amount (₹) *',
                  hint: '1500',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Amount is required' : null,
                ),
                const SizedBox(height: 16),

                const Text('PAYMENT METHOD', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Other'].map((m) {
                    final selected = _paymentMethod == m;
                    return FilterChip(
                      selected: selected,
                      label: Text(m),
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
                          const Text('NEW START DATE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (picked != null) setState(() => _startDate = picked);
                            },
                            child: Container(
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
                          const Text('NEW END DATE', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: Container(
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
                  label: 'Payment Notes (Optional)',
                  hint: 'e.g. Paid via Google Pay',
                  controller: _notesController,
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: 'Save Payment & Print Receipt →',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _processPayment,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

