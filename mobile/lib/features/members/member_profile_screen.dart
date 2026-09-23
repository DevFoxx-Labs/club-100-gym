import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/sms_launcher.dart';
import '../../core/utils/sms_templates.dart';
import '../../core/utils/contact_sync_service.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/models/membership_change_log_model.dart';
import '../../data/models/trainer_change_log_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';
import '../bills/bill_detail_screen.dart';
import '../payments/add_payment_screen.dart';
import '../receipts/receipt_preview_screen.dart';
import 'add_edit_member_screen.dart';
import 'change_plan_screen.dart';
import 'change_trainer_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _memberRepo = MemberRepository();
  final _paymentRepo = PaymentRepository();
  final _billRepo = BillRepository();
  final _planRepo = PlanRepository();
  final _settingsRepo = SettingsRepository();
  final _trainerRepo = TrainerRepository();

  MemberModel? _member;
  MembershipModel? _membership;
  PlanModel? _plan;
  TrainerModel? _trainer;
  List<PaymentModel> _payments = [];
  List<BillModel> _bills = [];
  List<MembershipChangeLogModel> _planChangeLogs = [];
  List<TrainerChangeLogModel> _trainerChangeLogs = [];

  bool _isLoading = true;
  String _gymName = 'Elite Fitness Gym';

  @override
  void initState() {
    super.initState();
    _loadMemberData();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadMemberData(showSpinner: false);
    }
  }

  Future<void> _loadMemberData({bool showSpinner = true}) async {
    if (showSpinner || _member == null) {
      setState(() => _isLoading = true);
    }

    final gym = await _settingsRepo.getGymInfo();
    final member = await _memberRepo.getMemberById(widget.memberId);
    final membership = await _memberRepo.getLatestMembership(widget.memberId);
    final payments = await _paymentRepo.getPaymentsByMember(widget.memberId);
    final bills = await _billRepo.getBillsByMember(widget.memberId);

    TrainerModel? trainer;
    if (membership?.trainerId != null && membership!.trainerId!.isNotEmpty) {
      trainer = await _trainerRepo.getTrainerById(membership.trainerId!);
    }

    final planLogs = await _memberRepo.getMembershipChangeLogs(widget.memberId);
    final trainerLogs = await _trainerRepo.getTrainerChangeLogsForMember(widget.memberId);

    PlanModel? plan;
    if (membership != null) {
      plan = await _planRepo.getPlanById(membership.planId);
    }

    if (mounted) {
      setState(() {
        _gymName = gym.name;
        _member = member;
        _membership = membership;
        _plan = plan;
        _trainer = trainer;
        _payments = payments;
        _bills = bills;
        _planChangeLogs = planLogs;
        _trainerChangeLogs = trainerLogs;
        _isLoading = false;
      });
    }
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

  String _statusLabel() {
    if (_membership == null) return tr('member_profile_no_active_plan');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(_membership!.endDate.year, _membership!.endDate.month, _membership!.endDate.day);
    final diffDays = endDate.difference(today).inDays;

    if (diffDays < 0) return tr('member_profile_overdue_by_days', {'days': '${diffDays.abs()}'});
    if (diffDays == 0) return tr('member_profile_fee_due_today');
    if (diffDays <= 7) return tr('member_profile_due_in_days', {'days': '$diffDays'});
    return tr('common_active');
  }

  Future<void> _onPhotoChanged(String? newPath) async {
    if (_member == null) return;
    final updated = _member!.copyWith(photoPath: newPath);
    await _memberRepo.updateMember(updated);
    setState(() {
      _member = updated;
    });
  }

  Future<void> _syncContact() async {
    if (_member == null) return;
    final success = await ContactSyncService.syncMemberToContacts(_member!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? tr('member_profile_saved_to_contacts', {'name': _member!.name}) : tr('member_profile_save_contact_failed'),
          ),
          backgroundColor: success ? AppTheme.neonLime : AppTheme.statusOverdue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleArchiveMember() async {
    if (_member == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: _member!.isArchived ? tr('member_profile_unarchive_title') : tr('member_profile_archive_title'),
        message: _member!.isArchived
            ? tr('member_profile_unarchive_message')
            : tr('member_profile_archive_message'),
        confirmText: _member!.isArchived ? tr('member_profile_unarchive_confirm') : tr('member_profile_archive_confirm'),
        onConfirm: () {},
      ),
    );
    if (confirmed == true && mounted) {
      await _memberRepo.archiveMember(_member!.id, !_member!.isArchived);
      _loadMemberData();
    }
  }

  Future<void> _handleDeleteMember() async {
    if (_member == null) return;
    final canDelete = await _memberRepo.canHardDelete(_member!.id);
    if (!mounted) return;

    if (!canDelete) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text(tr('member_profile_cannot_delete_title'), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
          content: Text(
            tr('member_profile_cannot_delete_message'),
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('common_cancel'), style: const TextStyle(color: AppTheme.textMuted))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonLime, foregroundColor: AppTheme.darkBackground),
              onPressed: () async {
                Navigator.pop(ctx);
                await _memberRepo.archiveMember(_member!.id, true);
                if (mounted) {
                  _loadMemberData();
                }
              },
              child: Text(tr('member_profile_archive_confirm_2')),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: tr('member_profile_delete_title'),
        message: tr('member_profile_delete_message'),
        confirmText: tr('common_delete'),
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      final nav = Navigator.of(context);
      await _memberRepo.hardDeleteMember(_member!.id);
      if (mounted) {
        nav.pop(true);
      }
    }
  }

  void _showMessageBottomSheet() {
    if (_member == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int dueDays = 0;
    if (_membership != null) {
      final endDate = DateTime(_membership!.endDate.year, _membership!.endDate.month, _membership!.endDate.day);
      dueDays = endDate.difference(today).inDays;
    }

    final double fee = _membership?.feeAmount ?? 0;
    final latestPayment = _payments.isNotEmpty ? _payments.first : null;

    final templates = <Map<String, String>>[
      {
        'title': tr('member_profile_template_fee_due'),
        'message': dueDays < 0
            ? SmsTemplates.feeOverdue(memberName: _member!.name, gymName: _gymName, daysOverdue: dueDays.abs(), amount: fee)
            : dueDays == 0
                ? SmsTemplates.feeDueToday(memberName: _member!.name, gymName: _gymName, amount: fee)
                : SmsTemplates.feeDueSoon(memberName: _member!.name, gymName: _gymName, daysLeft: dueDays, amount: fee),
      },
      {
        'title': tr('member_profile_template_membership_expiry'),
        'message': SmsTemplates.membershipExpiry(
          memberName: _member!.name,
          gymName: _gymName,
          expiryDate: _membership != null ? DateFormat('dd MMM yyyy').format(_membership!.endDate) : tr('member_profile_soon'),
        ),
      },
      if (latestPayment != null)
        {
          'title': tr('member_profile_template_receipt'),
          'message': SmsTemplates.paymentReceipt(
            memberName: _member!.name,
            gymName: _gymName,
            receiptNumber: latestPayment.receiptNumber,
            amount: latestPayment.amount,
            date: DateFormat('dd MMM yyyy').format(latestPayment.paymentDate),
          ),
        },
      {
        'title': tr('member_profile_template_welcome'),
        'message': SmsTemplates.welcomeMessage(memberName: _member!.name, gymName: _gymName),
      },
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + (bottomInset > 0 ? bottomInset : 10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('member_profile_send_message_title'),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.neonLime, letterSpacing: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (var t in templates) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['title']!,
                          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t['message']!,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                              label: Text(tr('members_menu_whatsapp'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(context);
                                SmsLauncher.sendWhatsApp(phoneNumber: _member!.phone, message: t['message']!);
                              },
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.neonLime,
                                side: BorderSide(color: AppTheme.neonLime),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.sms_outlined, size: 16),
                              label: Text(tr('member_profile_native_sms'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.pop(context);
                                SmsLauncher.sendSms(phoneNumber: _member!.phone, message: t['message']!);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.neonLime)));
    }

    if (_member == null) {
      return Scaffold(body: Center(child: Text(tr('member_profile_not_found'), style: const TextStyle(color: AppTheme.textWhite))));
    }

    final statusText = _calculateStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('member_profile_title')),
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
            onSelected: (val) {
              if (val == 'sync_contacts') {
                _syncContact();
              } else if (val == 'archive') {
                _handleArchiveMember();
              } else if (val == 'delete') {
                _handleDeleteMember();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'sync_contacts',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone_rounded, color: AppTheme.neonLime, size: 18),
                    const SizedBox(width: 10),
                    Text(tr('member_profile_save_to_contacts'), style: const TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(_member!.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, color: AppTheme.neonLime, size: 18),
                    const SizedBox(width: 10),
                    Text(_member!.isArchived ? tr('member_profile_unarchive_menu') : tr('member_profile_archive_menu'), style: const TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue, size: 18),
                    const SizedBox(width: 10),
                    Text(tr('member_profile_delete_menu'), style: const TextStyle(color: AppTheme.statusOverdue)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 32 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Card with Editable Photo Avatar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  children: [
                    EditableMemberAvatar(
                      photoPath: _member!.photoPath,
                      radius: 34,
                      onPhotoChanged: _onPhotoChanged,
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
                            style: TextStyle(fontSize: 13, color: AppTheme.neonLime, fontWeight: FontWeight.bold),
                          ),
                          if (_member!.email != null && _member!.email!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _member!.email!,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                          const SizedBox(height: 6),
                          StatusBadge(status: statusText, label: _statusLabel()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row (Add Payment & Message)
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      text: tr('member_profile_add_payment'),
                      icon: Icons.add_card_rounded,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      fontSize: 12.5,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      text: tr('member_profile_message_sms'),
                      icon: Icons.chat_bubble_outline_rounded,
                      isSecondary: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      fontSize: 12.5,
                      onPressed: _showMessageBottomSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Membership Plan Details Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('member_profile_membership_details'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                  ),
                  if (_membership != null)
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            foregroundColor: AppTheme.neonLime,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: Text(tr('member_profile_change_plan'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePlanScreen(
                                  member: _member!,
                                  currentMembership: _membership!,
                                ),
                              ),
                            );
                            if (changed == true) _loadMemberData();
                          },
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            foregroundColor: Colors.cyanAccent,
                          ),
                          icon: const Icon(Icons.sports_gymnastics_rounded, size: 16),
                          label: Text(tr('member_profile_trainer'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangeTrainerScreen(
                                  member: _member!,
                                  currentMembership: _membership!,
                                ),
                              ),
                            );
                            if (changed == true) _loadMemberData();
                          },
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

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
                      _DetailRow(label: tr('member_profile_plan_name'), value: _membership!.planName),
                      if (_membership!.personalTrainingFee > 0) ...[
                        const Divider(color: AppTheme.darkBorder, height: 18),
                        _DetailRow(
                          label: tr('member_profile_base_plan_fee'),
                          value: '₹${((_membership!.feeAmount >= _membership!.personalTrainingFee) ? (_membership!.feeAmount - _membership!.personalTrainingFee) : _membership!.feeAmount).toStringAsFixed(0)}',
                          trailingBadge: (_plan != null &&
                                  ((_membership!.feeAmount >= _membership!.personalTrainingFee)
                                          ? (_membership!.feeAmount - _membership!.personalTrainingFee)
                                          : _membership!.feeAmount) !=
                                      _plan!.defaultFee)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonLime.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    tr('member_profile_custom_badge'),
                                    style: TextStyle(
                                      color: AppTheme.neonLime,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const Divider(color: AppTheme.darkBorder, height: 18),
                        _DetailRow(label: tr('member_profile_personal_training_fee'), value: '₹${_membership!.personalTrainingFee.toStringAsFixed(0)}'),
                        const Divider(color: AppTheme.darkBorder, height: 18),
                        _DetailRow(label: tr('member_profile_total_membership_fee'), value: '₹${_membership!.feeAmount.toStringAsFixed(0)}', isHighlight: true),
                      ] else ...[
                        const Divider(color: AppTheme.darkBorder, height: 18),
                        _DetailRow(
                          label: tr('member_profile_membership_fee'),
                          value: '₹${_membership!.feeAmount.toStringAsFixed(0)}',
                          trailingBadge: (_plan != null && _membership!.feeAmount != _plan!.defaultFee)
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonLime.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    tr('member_profile_custom_badge'),
                                    style: TextStyle(
                                      color: AppTheme.neonLime,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                      if (_trainer != null) ...[
                        const Divider(color: AppTheme.darkBorder, height: 18),
                        _DetailRow(label: tr('member_profile_assigned_trainer'), value: '${_trainer!.name} (${_trainer!.speciality})'),
                      ],
                      const Divider(color: AppTheme.darkBorder, height: 18),
                      _DetailRow(label: tr('change_plan_start_date'), value: dateFormat.format(_membership!.startDate)),
                      const Divider(color: AppTheme.darkBorder, height: 18),
                      _DetailRow(label: tr('member_profile_end_date'), value: dateFormat.format(_membership!.endDate)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Center(
                    child: Text(tr('member_profile_no_active_membership'), style: const TextStyle(color: AppTheme.textMuted)),
                  ),
                ),

              const SizedBox(height: 20),

              // Plan Change History (if any)
              if (_planChangeLogs.isNotEmpty) ...[
                Text(
                  tr('member_profile_plan_change_history'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _planChangeLogs.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 16),
                    itemBuilder: (context, index) {
                      final log = _planChangeLogs[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${log.previousPlanName} ➔ ${log.newPlanName}',
                                style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                dateFormat.format(log.effectiveDate),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('member_profile_fee_reason_row', {'fee': log.newFee.toStringAsFixed(0), 'reason': log.reason ?? ''}),
                            style: const TextStyle(color: AppTheme.textWhite, fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Trainer Change History (if any)
              if (_trainerChangeLogs.isNotEmpty) ...[
                Text(
                  tr('member_profile_trainer_assignment_history'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _trainerChangeLogs.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.darkBorder, height: 16),
                    itemBuilder: (context, index) {
                      final log = _trainerChangeLogs[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${log.previousTrainerName ?? tr('member_profile_none')} ➔ ${log.newTrainerName ?? tr('member_profile_none')}',
                                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                dateFormat.format(log.changedAtDate),
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tr('member_profile_pt_fee_reason_row', {'fee': log.newPersonalTrainingFee.toStringAsFixed(0), 'reason': log.reason ?? ''}),
                            style: const TextStyle(color: AppTheme.textWhite, fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Bills & Dues Section
              Text(
                tr('member_profile_bills_dues'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 8),

              if (_bills.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Center(
                    child: Text(tr('member_profile_no_bills'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bills.length,
                  itemBuilder: (context, index) {
                    final bill = _bills[index];
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '₹${bill.amount.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.neonLime),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(status: bill.status, label: tr('bill_status_${bill.status.toLowerCase()}')),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr('member_profile_due_plan_row', {'date': dateFormat.format(bill.dueDate), 'plan': bill.planName}),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                Text(
                                  tr('member_profile_bill_number_row', {'number': bill.billNumber}),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.chevron_right_rounded, color: AppTheme.neonLime),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BillDetailScreen(bill: bill)),
                              );
                              if (mounted) _loadMemberData(showSpinner: false);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),

              // Payment History Section
              Text(
                tr('member_profile_payment_history'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
              ),
              const SizedBox(height: 8),

              if (_payments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Center(
                    child: Text(tr('member_profile_no_payments'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.neonLime),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${pay.paymentMethod} • ${dateFormat.format(pay.paymentDate)}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                tr('member_profile_receipt_row', {'number': pay.receiptNumber}),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime),
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
  final bool isHighlight;
  final Widget? trailingBadge;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppTheme.textWhite : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingBadge != null) ...[
              trailingBadge!,
              const SizedBox(width: 6),
            ],
            Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isHighlight ? AppTheme.neonLime : AppTheme.textWhite,
                fontSize: isHighlight ? 14 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
