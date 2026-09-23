import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/trainer_change_log_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class ChangeTrainerScreen extends StatefulWidget {
  final MemberModel member;
  final MembershipModel currentMembership;

  const ChangeTrainerScreen({
    super.key,
    required this.member,
    required this.currentMembership,
  });

  @override
  State<ChangeTrainerScreen> createState() => _ChangeTrainerScreenState();
}

class _ChangeTrainerScreenState extends State<ChangeTrainerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ptFeeController = TextEditingController(text: '0');
  final _reasonController = TextEditingController();

  final MemberRepository _memberRepo = MemberRepository();
  final TrainerRepository _trainerRepo = TrainerRepository();
  final PlanRepository _planRepo = PlanRepository();

  List<TrainerModel> _trainers = [];
  TrainerModel? _selectedTrainer;
  TrainerModel? _currentTrainer;
  double _basePlanFee = 0.0;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _ptFeeController.text = widget.currentMembership.personalTrainingFee > 0
        ? widget.currentMembership.personalTrainingFee.toStringAsFixed(0)
        : '0';
    _ptFeeController.addListener(_onPtFeeChanged);
    _loadTrainers();
  }

  void _onPtFeeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTrainers() async {
    final trainers = await _trainerRepo.getAllTrainers();
    TrainerModel? current;
    if (widget.currentMembership.trainerId != null) {
      current = trainers.where((t) => t.id == widget.currentMembership.trainerId).firstOrNull;
    }

    // Resolve base plan fee accurately (total fee - previous pt fee)
    double base = (widget.currentMembership.feeAmount > widget.currentMembership.personalTrainingFee)
        ? (widget.currentMembership.feeAmount - widget.currentMembership.personalTrainingFee)
        : 0.0;

    if (base <= 0) {
      final plan = await _planRepo.getPlanById(widget.currentMembership.planId);
      if (plan != null && plan.defaultFee > 0) {
        base = plan.defaultFee;
      } else if (widget.currentMembership.feeAmount > 0) {
        base = widget.currentMembership.feeAmount;
      }
    }

    if (mounted) {
      setState(() {
        _trainers = trainers;
        _currentTrainer = current;
        _selectedTrainer = current;
        _basePlanFee = base;
        _isInit = false;
      });
    }
  }

  @override
  void dispose() {
    _ptFeeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitChangeTrainer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now().toIso8601String();
    final newPtFee = _selectedTrainer == null
        ? 0.0
        : (double.tryParse(_ptFeeController.text.trim()) ?? 0.0);
    final newTotalFee = _basePlanFee + newPtFee;
    final reason = _reasonController.text.trim();

    final log = TrainerChangeLogModel(
      id: const Uuid().v4(),
      memberId: widget.member.id,
      membershipId: widget.currentMembership.id,
      previousTrainerId: _currentTrainer?.id,
      previousTrainerNameSnapshot: _currentTrainer?.name,
      newTrainerId: _selectedTrainer?.id,
      newTrainerNameSnapshot: _selectedTrainer?.name,
      previousPersonalTrainingFee: widget.currentMembership.personalTrainingFee,
      newPersonalTrainingFee: newPtFee,
      reason: reason.isEmpty ? null : reason,
      changedAt: now,
    );

    await _memberRepo.changeTrainer(
      membershipId: widget.currentMembership.id,
      memberId: widget.member.id,
      newTrainerId: _selectedTrainer?.id,
      newPersonalTrainingFee: newPtFee,
      newFeeAmount: newTotalFee,
      log: log,
    );

    AppStateService.instance.notifyMembersChanged();

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          tr('change_trainer_title'),
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isInit
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member & Current Trainer Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF121212),
                                  child: Text(
                                    widget.member.name.isNotEmpty ? widget.member.name[0].toUpperCase() : 'M',
                                    style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.member.name,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.member.phone,
                                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: Color(0xFF252525)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tr('change_trainer_current_assigned'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        _currentTrainer != null ? _currentTrainer!.name : tr('change_trainer_none_self_trained'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(tr('change_trainer_current_pt_fee'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${widget.currentMembership.personalTrainingFee.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Instructions banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFD4FF00), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('change_trainer_instructions'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select New Trainer
                    Text(
                      tr('change_trainer_select_new'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TrainerModel?>(
                      initialValue: _selectedTrainer,
                      dropdownColor: const Color(0xFF252525),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: tr('change_trainer_choose_hint'),
                        prefixIcon: const Icon(Icons.sports_gymnastics, color: Color(0xFFD4FF00)),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(tr('change_trainer_none_remove'))),
                        ..._trainers.map((t) => DropdownMenuItem(value: t, child: Text('${t.name} (${t.specialization ?? tr('change_trainer_general')})'))),
                      ],
                      onChanged: (t) {
                        setState(() {
                          _selectedTrainer = t;
                          if (t == null) _ptFeeController.text = '0';
                        });
                      },
                    ),
                    if (_selectedTrainer != null) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: tr('change_trainer_pt_fee_label'),
                        hint: '0',
                        controller: _ptFeeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => FormValidators.validateAmount(v, fieldName: tr('change_trainer_pt_fee_field_name'), allowZero: true),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4FF00).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('change_trainer_base_plan_fee'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text('₹${_basePlanFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('change_trainer_pt_fee_row'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                Text(
                                  '₹${(double.tryParse(_ptFeeController.text.trim()) ?? 0.0).toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            const Divider(color: Color(0xFF2E2E2E), height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('change_trainer_updated_total_fee'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  '₹${(_basePlanFee + (double.tryParse(_ptFeeController.text.trim()) ?? 0.0)).toStringAsFixed(0)}',
                                  style: const TextStyle(color: Color(0xFFD4FF00), fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: tr('change_trainer_reason_label'),
                      hint: tr('change_trainer_reason_hint'),
                      controller: _reasonController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    NeonButton(
                      text: tr('change_trainer_confirm_button'),
                      icon: Icons.check,
                      isLoading: _isLoading,
                      onPressed: _submitChangeTrainer,
                    ),
                    SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
    );
  }
}

