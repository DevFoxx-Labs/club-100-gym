import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../core/utils/contact_sync_service.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/package_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/phone_input_field.dart';

class AddEditMemberScreen extends StatefulWidget {
  final MemberModel? member;

  const AddEditMemberScreen({super.key, this.member});

  @override
  State<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends State<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberRepo = MemberRepository();
  final _billRepo = BillRepository();
  final _planRepo = PlanRepository();
  final _packageRepo = PackageRepository();
  final _trainerRepo = TrainerRepository();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  late TextEditingController _planFeeController;
  late TextEditingController _ptFeeController;

  String? _photoPath;
  String _gender = 'Male';
  List<PackageModel> _packages = [];
  PackageModel? _selectedPackage;
  List<PlanModel> _plans = [];
  PlanModel? _selectedPlan;
  List<TrainerModel> _trainers = [];
  TrainerModel? _selectedTrainer;
  DateTime _startDate = DateTime.now();
  bool _syncToContacts = true;
  bool _isLoading = false;
  late ValueNotifier<String> _phoneDialCode;

  @override
  void initState() {
    super.initState();
    final (initialDialCode, initialPhone) = PhoneUtils.split(widget.member?.phone);
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: initialPhone);
    _phoneDialCode = ValueNotifier(initialDialCode);
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
    _planFeeController = TextEditingController(text: '1500');
    _ptFeeController = TextEditingController(text: '0');
    _photoPath = widget.member?.photoPath;
    _gender = widget.member?.gender ?? 'Male';
    _syncToContacts = widget.member == null;

    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneDialCode.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _planFeeController.dispose();
    _ptFeeController.dispose();
    super.dispose();
  }

  double get _currentPlanFee => double.tryParse(_planFeeController.text.trim()) ?? (_selectedPlan?.defaultFee ?? 0.0);
  double get _currentPtFee => _selectedTrainer != null ? (double.tryParse(_ptFeeController.text.trim()) ?? 0.0) : 0.0;
  double get _totalFee => _currentPlanFee + _currentPtFee;

  Future<void> _loadData() async {
    final packages = await _packageRepo.getAllPackages();
    final trainers = await _trainerRepo.getAllTrainers();

    List<PlanModel> plans = [];
    PackageModel? selectedPackage;
    if (packages.isNotEmpty) {
      selectedPackage = packages.first;
      plans = await _planRepo.getPlansByPackageId(selectedPackage.id);
    }

    setState(() {
      _packages = packages;
      _selectedPackage = selectedPackage;
      _plans = plans;
      _trainers = trainers;
      if (plans.isNotEmpty) {
        _selectedPlan = plans.first;
        _planFeeController.text = _selectedPlan!.defaultFee.toStringAsFixed(0);
      }
    });

    if (widget.member != null) {
      final membership = await _memberRepo.getLatestMembership(widget.member!.id);
      if (membership != null && mounted) {
        TrainerModel? matchedTrainer;
        if (membership.trainerId != null) {
          try {
            matchedTrainer = trainers.firstWhere((t) => t.id == membership.trainerId);
          } catch (_) {}
        }

        setState(() {
          _startDate = membership.startDate;
          final basePlanFee = (membership.feeAmount >= membership.personalTrainingFee)
              ? (membership.feeAmount - membership.personalTrainingFee)
              : membership.feeAmount;
          _planFeeController.text = basePlanFee.toStringAsFixed(0);
          _selectedTrainer = matchedTrainer;
          _ptFeeController.text = membership.personalTrainingFee > 0
              ? membership.personalTrainingFee.toStringAsFixed(0)
              : '0';
        });
      }
    }
  }

  Future<void> _onPackageSelected(PackageModel? pkg) async {
    if (pkg == null) return;
    final plans = await _planRepo.getPlansByPackageId(pkg.id);
    if (!mounted) return;
    setState(() {
      _selectedPackage = pkg;
      _plans = plans;
      _selectedPlan = plans.isNotEmpty ? plans.first : null;
      if (_selectedPlan != null) {
        _planFeeController.text = _selectedPlan!.defaultFee.toStringAsFixed(0);
      }
    });
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null && widget.member == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('member_form_select_plan_error'))));
      return;
    }

    setState(() => _isLoading = true);

    const uuid = Uuid();
    final now = DateTime.now();
    final memberId = widget.member?.id ?? uuid.v4();

    final member = MemberModel(
      id: memberId,
      name: _nameController.text.trim(),
      phone: PhoneUtils.combine(_phoneDialCode.value, _phoneController.text.trim()),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      photoPath: _photoPath,
      gender: _gender,
      notes: _notesController.text.trim(),
      isArchived: widget.member?.isArchived ?? false,
      createdAt: widget.member?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.member == null) {
      final endDate = _startDate.add(Duration(days: _selectedPlan!.durationDays));
      final planFee = double.tryParse(_planFeeController.text.trim()) ?? _selectedPlan!.defaultFee;
      final ptFee = _selectedTrainer != null ? (double.tryParse(_ptFeeController.text.trim()) ?? 0.0) : 0.0;
      final totalFee = planFee + ptFee;

      final membership = MembershipModel(
        id: uuid.v4(),
        memberId: memberId,
        planId: _selectedPlan!.id,
        planName: _selectedPlan!.name,
        packageId: _selectedPlan!.packageId,
        startDate: _startDate,
        endDate: endDate,
        feeAmount: totalFee,
        trainerId: _selectedTrainer?.id,
        personalTrainingFee: ptFee,
        status: 'Active',
        createdAt: now,
        updatedAt: now,
      );

      await _memberRepo.addMember(member, membership);

      // Auto-generate the first bill for this membership, due on the onboarding start date.
      final firstBill = BillModel(
        id: uuid.v4(),
        billNumber: await _billRepo.generateNextBillNumber(),
        memberId: member.id,
        memberName: member.name,
        memberPhone: member.phone,
        membershipId: membership.id,
        planName: membership.planName,
        amount: membership.feeAmount,
        billDate: now,
        dueDate: membership.startDate,
        status: 'Pending',
        isAutoGenerated: true,
        cycleKey: BillRepository.cycleKeyFor(membership.id, membership.startDate),
        createdAt: now,
        updatedAt: now,
      );
      await _billRepo.createBill(firstBill);
      AppStateService.instance.notifyBillsChanged();
    } else {
      await _memberRepo.updateMember(member);
    }

    if (_syncToContacts) {
      try {
        await ContactSyncService.syncMemberToContacts(member);
      } catch (_) {}
    }

    // Trigger instant app-wide reactive state updates
    AppStateService.instance.notifyMembersChanged();

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? tr('member_form_edit_title') : tr('member_form_add_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Member Photo
                Center(
                  child: Column(
                    children: [
                      EditableMemberAvatar(
                        name: _nameController.text,
                        photoPath: _photoPath,
                        radius: 44,
                        onPhotoChanged: (path) => setState(() => _photoPath = path),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('member_form_tap_photo'),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: tr('member_form_full_name'),
                  hint: tr('member_form_full_name_hint'),
                  controller: _nameController,
                  validator: (v) => FormValidators.validateName(v, fieldName: tr('member_form_full_name_field')),
                ),
                const SizedBox(height: 16),

                ValueListenableBuilder<String>(
                  valueListenable: _phoneDialCode,
                  builder: (context, dialCode, _) => PhoneInputField(
                    label: tr('member_form_phone'),
                    controller: _phoneController,
                    dialCodeNotifier: _phoneDialCode,
                    validator: (v) => FormValidators.validatePhoneForCountry(
                      v,
                      dialCode: dialCode,
                      fieldName: tr('member_form_phone_field'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: tr('member_form_email'),
                  hint: 'e.g. rahul@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => FormValidators.validateEmail(v),
                ),
                const SizedBox(height: 16),

                Text(
                  tr('member_form_gender'),
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final selected = _gender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        selected: selected,
                        label: Text(tr('member_form_gender_$g')),
                        selectedColor: AppTheme.neonLime,
                        backgroundColor: AppTheme.darkSurface,
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.darkBackground : AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setState(() => _gender = g),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                if (!isEdit) ...[
                  Text(
                    tr('member_form_package'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PackageModel>(
                        value: _selectedPackage,
                        isExpanded: true,
                        hint: Text(tr('member_form_no_packages'), style: const TextStyle(color: AppTheme.textMuted)),
                        dropdownColor: AppTheme.darkSurface,
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                        items: _packages
                            .map((pkg) => DropdownMenuItem(
                                  value: pkg,
                                  child: Text(pkg.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: _onPackageSelected,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    tr('member_form_plan'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PlanModel>(
                        value: _selectedPlan,
                        isExpanded: true,
                        hint: Text(tr('member_form_no_plans'), style: const TextStyle(color: AppTheme.textMuted)),
                        dropdownColor: AppTheme.darkSurface,
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                        items: _plans
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.name} (${p.durationDays} Days - ₹${p.defaultFee.toStringAsFixed(0)})'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedPlan = val;
                              _planFeeController.text = val.defaultFee.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('member_form_start_date'),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.darkBorder),
                                ),
                                child: Text(
                                  dateFormat.format(_startDate),
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              label: tr('change_plan_price_label'),
                              controller: _planFeeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              hint: _selectedPlan?.defaultFee.toStringAsFixed(0) ?? '1500',
                              validator: (v) => FormValidators.validateAmount(v, fieldName: tr('change_plan_price_field_name')),
                              onChanged: (_) => setState(() {}),
                            ),
                            if (_selectedPlan != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _currentPlanFee != _selectedPlan!.defaultFee
                                    ? tr('change_plan_custom_rate', {'fee': _selectedPlan!.defaultFee.toStringAsFixed(0)})
                                    : tr('change_plan_standard_rate', {'fee': _selectedPlan!.defaultFee.toStringAsFixed(0)}),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _currentPlanFee != _selectedPlan!.defaultFee
                                      ? AppTheme.neonLime
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Personal Trainer Assignment (Optional)
                  Text(
                    tr('member_form_assign_trainer'),
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TrainerModel?>(
                        value: _selectedTrainer,
                        isExpanded: true,
                        dropdownColor: AppTheme.darkSurface,
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                        items: [
                          DropdownMenuItem<TrainerModel?>(
                            value: null,
                            child: Text(tr('member_form_no_trainer'), style: const TextStyle(color: AppTheme.textMuted)),
                          ),
                          ..._trainers.map((t) => DropdownMenuItem<TrainerModel?>(
                                value: t,
                                child: Text('${t.name} • ${t.speciality}'),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTrainer = val;
                            if (val == null) {
                              _ptFeeController.text = '0';
                            }
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedTrainer != null) ...[
                    CustomTextField(
                      label: tr('change_trainer_pt_fee_label'),
                      controller: _ptFeeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: '0',
                      validator: (v) => FormValidators.validateAmount(v, fieldName: tr('change_trainer_pt_fee_field_name'), allowZero: true),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Total Membership Fee Summary Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('change_plan_total_membership_fee'),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            if (_selectedPlan != null && (_currentPlanFee != _selectedPlan!.defaultFee))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonLime.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  tr('change_plan_custom_rate_badge'),
                                  style: TextStyle(color: AppTheme.neonLime, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('member_form_plan_row', {'name': _selectedPlan?.name ?? tr('member_form_membership_fallback')}),
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                            ),
                            Text(
                              '₹${_currentPlanFee.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        if (_selectedTrainer != null && _currentPtFee > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tr('member_form_personal_training_row', {'name': _selectedTrainer!.name}),
                                style: const TextStyle(color: AppTheme.textWhite, fontSize: 13),
                              ),
                              Text(
                                '₹${_currentPtFee.toStringAsFixed(0)}',
                                style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const Divider(color: AppTheme.darkBorder, height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('change_plan_total_to_collect'),
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                            Text(
                              '₹${_totalFee.toStringAsFixed(0)}',
                              style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                CustomTextField(
                  label: tr('member_form_notes_label'),
                  hint: tr('member_form_notes_hint'),
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Save contact to phone
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: CheckboxListTile(
                    value: _syncToContacts,
                    onChanged: (v) => setState(() => _syncToContacts = v ?? false),
                    activeColor: AppTheme.neonLime,
                    checkColor: AppTheme.darkBackground,
                    title: Text(tr('member_form_save_contact_title'), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(tr('member_form_save_contact_subtitle'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: isEdit ? tr('member_form_update_button') : tr('member_form_save_button'),
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _saveMember,
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
