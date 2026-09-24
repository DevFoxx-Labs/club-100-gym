import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../data/models/trainer_model.dart';
import '../../data/models/trainer_payout_model.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/neon_button.dart';
import '../members/member_profile_screen.dart';
import 'trainer_form_screen.dart';
import '../../core/theme/app_theme.dart';

class TrainerDetailScreen extends StatefulWidget {
  final String trainerId;

  const TrainerDetailScreen({super.key, required this.trainerId});

  @override
  State<TrainerDetailScreen> createState() => _TrainerDetailScreenState();
}

class _TrainerDetailScreenState extends State<TrainerDetailScreen> {
  final TrainerRepository _repository = TrainerRepository();
  TrainerModel? _trainer;
  List<TrainerPayoutModel> _payouts = [];
  List<Map<String, dynamic>> _assignedMembers = [];
  double _totalPaid = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final trainer = await _repository.getTrainerById(widget.trainerId);
    if (trainer != null) {
      final payouts = await _repository.getPayoutsForTrainer(widget.trainerId);
      final total = await _repository.getTotalPaidOut(widget.trainerId);
      final members = await _repository.getMembersAssignedToTrainer(widget.trainerId);
      if (mounted) {
        setState(() {
          _trainer = trainer;
          _payouts = payouts;
          _totalPaid = total;
          _assignedMembers = members;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Trainer?',
        message: 'This trainer will be marked as inactive and removed from active lists, but their payout history and member assignment records will be safely preserved.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      await _repository.deleteTrainer(widget.trainerId);
      if (mounted) Navigator.pop(context, true);
    }
  }

  void _showRecordPayoutDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: _trainer?.monthlySalary != null ? _trainer!.monthlySalary!.toStringAsFixed(0) : '',
    );
    final notesController = TextEditingController();
    String payoutType = 'salary';
    DateTime payoutDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF333333)),
            ),
            title: const Text('Record Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Payout Amount (₹) *',
                        prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.neonLime),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Amount is required';
                        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: payoutType,
                      dropdownColor: const Color(0xFF252525),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Payout Type'),
                      items: const [
                        DropdownMenuItem(value: 'salary', child: Text('Monthly Salary')),
                        DropdownMenuItem(value: 'personal_training', child: Text('Personal Training Commission')),
                        DropdownMenuItem(value: 'bonus', child: Text('Performance Bonus / Advance')),
                      ],
                      onChanged: (v) => setDialogState(() => payoutType = v ?? 'salary'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today, color: AppTheme.neonLime),
                      title: const Text('Payout Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      subtitle: Text(
                        DateFormat('dd MMMM yyyy').format(payoutDate),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: payoutDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: AppTheme.neonLime,
                                onPrimary: const Color(0xFF121212),
                                surface: const Color(0xFF1E1E1E),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setDialogState(() => payoutDate = picked);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                        hintText: 'e.g. Month of Sep, Cash payout',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonLime,
                  foregroundColor: const Color(0xFF121212),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final payout = TrainerPayoutModel(
                    id: const Uuid().v4(),
                    trainerId: widget.trainerId,
                    amount: double.parse(amountController.text.trim()),
                    payoutDate: payoutDate.toIso8601String(),
                    payoutType: payoutType,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    createdAt: DateTime.now().toIso8601String(),
                    updatedAt: DateTime.now().toIso8601String(),
                  );
                  final nav = Navigator.of(dialogCtx);
                  final messenger = ScaffoldMessenger.of(context);
                  await _repository.recordPayout(payout);
                  if (mounted) {
                    nav.pop();
                    _loadData();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Payout recorded successfully!'),
                        backgroundColor: Color(0xFF00E676),
                      ),
                    );
                  }
                },
                child: const Text('Save Payout', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonLime)),
      );
    }

    if (_trainer == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(title: const Text('TRAINER PROFILE')),
        body: const Center(child: Text('Trainer not found', style: TextStyle(color: Colors.white))),
      );
    }

    final trainer = _trainer!;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'TRAINER PROFILE',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          PopupMenuButton<String>(
            color: const Color(0xFF1E1E1E),
            onSelected: (val) async {
              if (val == 'edit') {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrainerFormScreen(trainer: trainer)),
                );
                if (res == true) _loadData();
              } else if (val == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Color(0xFFFF5252), size: 20),
                    SizedBox(width: 12),
                    Text('Delete Trainer', style: TextStyle(color: Color(0xFFFF5252))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.neonLime,
        backgroundColor: const Color(0xFF1E1E1E),
        onRefresh: _loadData,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.paddingOf(context).bottom),
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    EditableMemberAvatar(
                      name: trainer.name,
                      photoPath: trainer.photoPath,
                      radius: 40,
                      defaultInitials: 'T',
                      subfolder: 'trainer_photos',
                      onPhotoChanged: (newPath) async {
                        await _repository.updateTrainerPhoto(trainer.id, newPath);
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      trainer.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trainer.phone,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    if (trainer.specialization != null && trainer.specialization!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.neonLime.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          trainer.specialization!,
                          style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Monthly Salary',
                            value: trainer.monthlySalary != null
                                ? '₹${trainer.monthlySalary!.toStringAsFixed(0)}'
                                : 'Not Set',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            title: 'Total Disbursed',
                            value: '₹${_totalPaid.toStringAsFixed(0)}',
                            icon: Icons.payments_outlined,
                            accentColor: const Color(0xFF00E676),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Record Payout Button
            NeonButton(
              text: 'Record Payout / Salary',
              icon: Icons.add_card,
              onPressed: _showRecordPayoutDialog,
            ),
            const SizedBox(height: 24),

            // Assigned Members Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ASSIGNED MEMBERS',
                  style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_assignedMembers.length}',
                    style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_assignedMembers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No members assigned to ${trainer.name} yet.',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ..._assignedMembers.map((m) => _buildAssignedMemberTile(m)),
            const SizedBox(height: 24),

            // Payout History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PAYOUT HISTORY',
                  style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                ),
                Text(
                  '${_payouts.length} records',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_payouts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No payouts recorded yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
              )
            else
              ..._payouts.map((p) => _buildPayoutTile(p)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor ?? AppTheme.neonLime),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedMemberTile(Map<String, dynamic> item) {
    final memberName = item['memberName'] as String? ?? 'Member';
    final planName = item['planName'] as String? ?? 'Plan';
    final ptFee = (item['personalTrainingFee'] as num?)?.toDouble() ?? 0.0;
    final memberId = item['memberId'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF121212),
          child: Text(
            memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M',
            style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(memberName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(
          '$planName${ptFee > 0 ? ' · PT Fee: ₹${ptFee.toStringAsFixed(0)}' : ''}',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: memberId)),
          );
        },
      ),
    );
  }

  Widget _buildPayoutTile(TrainerPayoutModel payout) {
    final date = DateTime.parse(payout.payoutDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.currency_rupee, color: Color(0xFF00E676), size: 20),
        ),
        title: Text(
          '₹${payout.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        subtitle: Text(
          '${payout.payoutTypeLabel} · ${DateFormat('dd MMM yyyy').format(date)}${payout.notes != null ? '\n${payout.notes}' : ''}',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        isThreeLine: payout.notes != null,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => ConfirmationDialog(
                title: 'Delete Payout Record?',
                message: 'Are you sure you want to remove this payout entry from the records?',
                confirmLabel: 'Delete',
                isDestructive: true,
              ),
            );
            if (confirm == true) {
              await _repository.deletePayout(payout.id);
              _loadData();
            }
          },
        ),
      ),
    );
  }
}

