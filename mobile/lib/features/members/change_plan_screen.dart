import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_change_log_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/package_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../../core/theme/app_theme.dart';

class ChangePlanScreen extends StatefulWidget {
  final MemberModel member;
  final MembershipModel currentMembership;

  const ChangePlanScreen({
    super.key,
    required this.member,
    required this.currentMembership,
  });

  @override
  State<ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends State<ChangePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planFeeController = TextEditingController();
  final _ptFeeController = TextEditingController(text: '0');
  final _reasonController = TextEditingController();

  final MemberRepository _memberRepo = MemberRepository();
  final PlanRepository _planRepo = PlanRepository();
  final PackageRepository _packageRepo = PackageRepository();
  final TrainerRepository _trainerRepo = TrainerRepository();

  List<PackageModel> _packages = [];
  List<PlanModel> _plans = [];
  List<TrainerModel> _trainers = [];
  PlanModel? _selectedPlan;
  TrainerModel? _selectedTrainer;

  DateTime _startDate = DateTime.now();
  late DateTime _endDate;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now().add(const Duration(days: 30));
    _ptFeeController.text = widget.currentMembership.personalTrainingFee > 0
        ? widget.currentMembership.personalTrainingFee.toStringAsFixed(0)
        : '0';
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    final packages = await _packageRepo.getAllPackages();
    final plans = await _planRepo.getPlans();
    final trainers = await _trainerRepo.getAllTrainers();

    TrainerModel? currentTrainer;
    if (widget.currentMembership.trainerId != null) {
      currentTrainer = trainers.where((t) => t.id == widget.currentMembership.trainerId).firstOrNull;
    }

    if (mounted) {
      setState(() {
        _packages = packages;
        _plans = plans;
        _trainers = trainers;
        _selectedTrainer = currentTrainer;
        _isInit = false;
      });
    }
  }

  @override
  void dispose() {
    _planFeeController.dispose();
    _ptFeeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double get _currentPlanFee => double.tryParse(_planFeeController.text.trim()) ?? (_selectedPlan?.defaultFee ?? 0.0);
  double get _currentPtFee => _selectedTrainer != null ? (double.tryParse(_ptFeeController.text.trim()) ?? 0.0) : 0.0;
  double get _totalFee => _currentPlanFee + _currentPtFee;

  void _onPlanSelected(PlanModel? plan) {
    if (plan == null) return;
    setState(() {
      _selectedPlan = plan;
      _endDate = _startDate.add(Duration(days: plan.durationDays));
      _planFeeController.text = plan.defaultFee.toStringAsFixed(0);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
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
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_selectedPlan != null) {
            _endDate = _startDate.add(Duration(days: _selectedPlan!.durationDays));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitChangePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('change_plan_select_plan_error')), backgroundColor: const Color(0xFFFF5252)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now().toIso8601String();
    final newMembershipId = const Uuid().v4();
    final planFee = double.tryParse(_planFeeController.text.trim()) ?? _selectedPlan!.defaultFee;
    final ptFee = _selectedTrainer != null ? (double.tryParse(_ptFeeController.text.trim()) ?? 0.0) : 0.0;
    final totalFee = planFee + ptFee;
    final reason = _reasonController.text.trim();

    // Find package name for snapshot if any
    String planNameSnapshot = _selectedPlan!.name;
    if (_selectedPlan!.packageId != null) {
      final pkg = _packages.where((p) => p.id == _selectedPlan!.packageId).firstOrNull;
      if (pkg != null) {
        planNameSnapshot = '${pkg.name} - ${_selectedPlan!.name}';
      }
    }

    final newMembership = MembershipModel(
      id: newMembershipId,
      memberId: widget.member.id,
      planId: _selectedPlan!.id,
      planName: planNameSnapshot,
      trainerId: _selectedTrainer?.id,
      personalTrainingFee: ptFee,
      packageId: _selectedPlan!.packageId,
      startDate: _startDate,
      endDate: _endDate,
      feeAmount: totalFee,
      status: 'Active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final log = MembershipChangeLogModel(
      id: const Uuid().v4(),
      memberId: widget.member.id,
      previousMembershipId: widget.currentMembership.id,
      newMembershipId: newMembershipId,
      previousPlanNameSnapshot: widget.currentMembership.planName,
      newPlanNameSnapshot: planNameSnapshot,
      previousFeeAmount: widget.currentMembership.feeAmount,
      newFeeAmount: totalFee,
      reason: reason.isEmpty ? null : reason,
      changedAt: now,
    );

    await _memberRepo.changePlan(
      memberId: widget.member.id,
      currentMembershipId: widget.currentMembership.id,
      newMembership: newMembership,
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          tr('change_plan_title'),
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isInit
          ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Member & Current Plan Summary Card
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
                                    style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold),
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
                                      Text(tr('change_plan_current_active_plan'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.currentMembership.planName,
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
                                    Text(tr('change_plan_expires_on'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateFormat.format(widget.currentMembership.endDate),
                                      style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 14),
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
                        border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.neonLime, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tr('change_plan_instructions'),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Select New Plan
                    Text(
                      tr('change_plan_select_new_plan'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<PlanModel>(
                      initialValue: _selectedPlan,
                      dropdownColor: const Color(0xFF252525),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: tr('change_plan_choose_hint'),
                        prefixIcon: Icon(Icons.card_membership, color: AppTheme.neonLime),
                      ),
                      items: _plans.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text('${p.name} (${p.durationDays} Days - ₹${p.defaultFee.toStringAsFixed(0)})'),
                        );
                      }).toList(),
                      onChanged: _onPlanSelected,
                    ),
                    const SizedBox(height: 16),

                    // Date range pickers
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            child: ListTile(
                              title: Text(tr('change_plan_start_date'), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              subtitle: Text(
                                dateFormat.format(_startDate),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onTap: () => _pickDate(isStart: true),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Card(
                            child: ListTile(
                              title: Text(tr('change_plan_new_end_date'), style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              subtitle: Text(
                                dateFormat.format(_endDate),
                                style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onTap: () => _pickDate(isStart: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Assigned Trainer & PT Fee
                    Text(
                      tr('change_plan_personal_trainer_optional'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TrainerModel?>(
                      initialValue: _selectedTrainer,
                      dropdownColor: const Color(0xFF252525),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: tr('change_plan_assign_trainer_hint'),
                        prefixIcon: Icon(Icons.sports_gymnastics, color: AppTheme.neonLime),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(tr('change_plan_none_self_trained'))),
                        ..._trainers.map((t) => DropdownMenuItem(value: t, child: Text(t.name))),
                      ],
                      onChanged: (t) {
                        setState(() {
                          _selectedTrainer = t;
                          if (t == null) {
                            _ptFeeController.text = '0';
                          }
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Plan Price
                    CustomTextField(
                      label: tr('change_plan_price_label'),
                      hint: _selectedPlan != null ? _selectedPlan!.defaultFee.toStringAsFixed(0) : '1500',
                      controller: _planFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => FormValidators.validateAmount(v, fieldName: tr('change_plan_price_field_name')),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_selectedPlan != null) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          _currentPlanFee != _selectedPlan!.defaultFee
                              ? tr('change_plan_custom_rate', {'fee': _selectedPlan!.defaultFee.toStringAsFixed(0)})
                              : tr('change_plan_standard_rate', {'fee': _selectedPlan!.defaultFee.toStringAsFixed(0)}),
                          style: TextStyle(
                            fontSize: 11,
                            color: _currentPlanFee != _selectedPlan!.defaultFee
                                ? AppTheme.neonLime
                                : Colors.white54,
                            fontWeight: _currentPlanFee != _selectedPlan!.defaultFee
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Dynamic Total Fee Breakdown Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _currentPlanFee != (_selectedPlan?.defaultFee ?? 0.0)
                              ? AppTheme.neonLime.withValues(alpha: 0.5)
                              : const Color(0xFF333333),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr('change_plan_total_membership_fee'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (_selectedPlan != null && _currentPlanFee != _selectedPlan!.defaultFee)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonLime.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tr('change_plan_custom_rate_badge'),
                                    style: TextStyle(
                                      color: AppTheme.neonLime,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr('change_plan_plan_fee'), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                              Text('₹${_currentPlanFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (_selectedTrainer != null && _currentPtFee > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tr('change_plan_personal_training_row', {'name': _selectedTrainer!.name}), style: const TextStyle(color: Colors.white60, fontSize: 13)),
                                Text('₹${_currentPtFee.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                          const Divider(color: Color(0xFF333333), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(tr('change_plan_total_to_collect'), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text(
                                '₹${_totalFee.toStringAsFixed(0)}',
                                style: TextStyle(color: AppTheme.neonLime, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reason
                    CustomTextField(
                      label: tr('change_plan_reason_label'),
                      hint: tr('change_plan_reason_hint'),
                      controller: _reasonController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    NeonButton(
                      text: tr('change_plan_confirm_button'),
                      icon: Icons.swap_horiz,
                      isLoading: _isLoading,
                      onPressed: _submitChangePlan,
                    ),
                    SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
            ),
    );
  }
}

