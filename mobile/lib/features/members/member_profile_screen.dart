import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/sms_launcher.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../payments/add_payment_screen.dart';
import '../receipts/receipt_preview_screen.dart';
import 'add_edit_member_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _memberRepo = MemberRepository();
  final _paymentRepo = PaymentRepository();
  final _settingsRepo = SettingsRepository();

  MemberModel? _member;
  MembershipModel? _membership;
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String _gymName = 'Club 100 The Gym';

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    final gym = await _settingsRepo.getGymInfo();
    final member = await _memberRepo.getMemberById(widget.memberId);
    final membership = await _memberRepo.getLatestMembership(widget.memberId);
    final payments = await _paymentRepo.getPaymentsByMember(widget.memberId);

    setState(() {
      _gymName = gym.name;
      _member = member;
      _membership = membership;
      _payments = payments;
      _isLoading = false;
    });
  }

  String _calculateStatus() {
    if (_membership == null) return 'No Active Plan';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(_membership!.endDate.year, _membership!.endDate.month, _membership!.endDate.day);
    final diffDays = endDate.difference(today).inDays;

    if (diffDays < 0) return 'Overdue by ${diffDays.abs()} days';
    if (diffDays == 0) return 'Fee Due Today';
    if (diffDays <= 7) return 'Due in $diffDays days';
    return 'Active';
  }

  void _sendSmsReminder() {
    if (_member == null || _membership == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(_membership!.endDate.year, _membership!.endDate.month, _membership!.endDate.day);
    final diffDays = endDate.difference(today).inDays;

    final msg = SmsLauncher.getFeeReminderTemplate(
      memberName: _member!.name,
      gymName: _gymName,
      dueDays: diffDays,
      amount: _membership!.feeAmount,
    );

    SmsLauncher.sendSms(phoneNumber: _member!.phone, message: msg);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.neonLime)));
    }

    if (_member == null) {
      return const Scaffold(body: Center(child: Text('Member not found', style: TextStyle(color: AppTheme.textWhite))));
    }

    final statusText = _calculateStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMBER PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.textWhite),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEditMemberScreen(member: _member)),
              );
              _loadMemberData();
            },
          ),
          PopupMenuButton<String>(
            color: AppTheme.darkSurface,
            onSelected: (val) async {
              if (val == 'archive') {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    title: _member!.isArchived ? 'Unarchive Member?' : 'Archive Member?',
                    message: _member!.isArchived
                        ? 'This member will be restored to active member lists.'
                        : 'Archived members are hidden from active lists but historical payment records remain preserved.',
                    confirmText: _member!.isArchived ? 'Unarchive' : 'Archive',
                    onConfirm: () async {
                      final nav = Navigator.of(context);
                      await _memberRepo.archiveMember(_member!.id, !_member!.isArchived);
                      nav.pop();
                    },
                  ),
                );
              } else if (val == 'delete') {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    title: 'Delete Member Record?',
                    message: 'This will permanently delete this member profile and all associated membership records.',
                    confirmText: 'Delete',
                    isDestructive: true,
                    onConfirm: () async {
                      final nav = Navigator.of(context);
                      await _memberRepo.deleteMember(_member!.id);
                      nav.pop();
                    },
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archive',
                child: Text(_member!.isArchived ? 'Unarchive Member' : 'Archive Member', style: const TextStyle(color: AppTheme.textWhite)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Member', style: TextStyle(color: AppTheme.statusOverdue)),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.neonLime,
                      child: Text(
                        _member!.name.isNotEmpty ? _member!.name[0].toUpperCase() : 'M',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.darkBackground),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _member!.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _member!.phone,
                            style: const TextStyle(fontSize: 13, color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          StatusBadge(status: statusText),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row (Add Payment & Send SMS)
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      text: 'Add Payment',
                      icon: Icons.add_card_rounded,
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddPaymentScreen(
                              member: _member!,
                              membership: _membership,
                            ),
                          ),
                        );
                        _loadMemberData();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      text: 'Send SMS',
                      icon: Icons.sms_rounded,
                      isSecondary: true,
                      onPressed: _sendSmsReminder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Membership Plan Details Section
              const Text(
                'MEMBERSHIP DETAILS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 10),

              if (_membership != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Plan Name', value: _membership!.planName),
                      const Divider(color: AppTheme.darkBorder, height: 20),
                      _DetailRow(label: 'Membership Fee', value: '₹${_membership!.feeAmount.toStringAsFixed(0)}'),
                      const Divider(color: AppTheme.darkBorder, height: 20),
                      _DetailRow(label: 'Start Date', value: dateFormat.format(_membership!.startDate)),
                      const Divider(color: AppTheme.darkBorder, height: 20),
                      _DetailRow(label: 'End Date', value: dateFormat.format(_membership!.endDate)),
                    ],
                  ),
                )
              else
                const Text('No active membership', style: TextStyle(color: AppTheme.textMuted)),

              const SizedBox(height: 24),

              // Payment History Section
              const Text(
                'PAYMENT HISTORY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 10),

              if (_payments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: const Center(
                    child: Text('No payments recorded yet', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final pay = _payments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${pay.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.neonLime),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pay.paymentMethod} • ${dateFormat.format(pay.paymentDate)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                'Receipt: ${pay.receiptNumber}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime),
                              onPressed: () async {
                                final nav = Navigator.of(context);
                                final receipt = await _paymentRepo.getReceiptByPaymentId(pay.id);
                                if (receipt != null) {
                                  nav.push(
                                    MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: receipt)),
                                  );
                                }
                              },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

