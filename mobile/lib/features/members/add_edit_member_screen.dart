import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../core/utils/contact_sync_service.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class AddEditMemberScreen extends StatefulWidget {
  final MemberModel? member;

  const AddEditMemberScreen({super.key, this.member});

  @override
  State<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends State<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memberRepo = MemberRepository();
  final _planRepo = PlanRepository();
  final _trainerRepo = TrainerRepository();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  late TextEditingController _feeController;
  late TextEditingController _ptFeeController;

  String? _photoPath;
  String _gender = 'Male';
  List<PlanModel> _plans = [];
  PlanModel? _selectedPlan;
  List<TrainerModel> _trainers = [];
  TrainerModel? _selectedTrainer;
  DateTime _startDate = DateTime.now();
  bool _syncToContacts = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _notesController = TextEditingController(text: widget.member?.notes ?? '');
    _feeController = TextEditingController(text: '1500');
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
    _emailController.dispose();
    _notesController.dispose();
    _feeController.dispose();
    _ptFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final plans = await _planRepo.getPlans();
    final trainers = await _trainerRepo.getAllTrainers();

    setState(() {
      _plans = plans;
      _trainers = trainers;
      if (plans.isNotEmpty) {
        _selectedPlan = plans.first;
        _feeController.text = _selectedPlan!.defaultFee.toStringAsFixed(0);
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
          _feeController.text = membership.feeAmount.toStringAsFixed(0);
          _selectedTrainer = matchedTrainer;
          _ptFeeController.text = membership.personalTrainingFee > 0
              ? membership.personalTrainingFee.toStringAsFixed(0)
              : '0';
        });
      }
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlan == null && widget.member == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a membership plan')));
      return;
    }

    setState(() => _isLoading = true);

    const uuid = Uuid();
    final now = DateTime.now();
    final memberId = widget.member?.id ?? uuid.v4();

    final member = MemberModel(
      id: memberId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
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
      final membership = MembershipModel(
        id: uuid.v4(),
        memberId: memberId,
        planId: _selectedPlan!.id,
        planName: _selectedPlan!.name,
        packageId: _selectedPlan!.packageId,
        startDate: _startDate,
        endDate: endDate,
        feeAmount: double.tryParse(_feeController.text.trim()) ?? _selectedPlan!.defaultFee,
        trainerId: _selectedTrainer?.id,
        personalTrainingFee: double.tryParse(_ptFeeController.text.trim()) ?? 0.0,
        status: 'Active',
        createdAt: now,
        updatedAt: now,
      );

      await _memberRepo.addMember(member, membership);
    } else {
      await _memberRepo.updateMember(member);
    }

    if (_syncToContacts) {
      try {
        await ContactSyncService.syncMemberToContacts(member);
      } catch (_) {}
    }

    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.member != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'EDIT MEMBER' : 'ADD NEW MEMBER'),
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
                        photoPath: _photoPath,
                        radius: 44,
                        onPhotoChanged: (path) => setState(() => _photoPath = path),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap camera icon to set photo',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Full Name *',
                  hint: 'e.g. Rahul Sharma',
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Mobile Phone Number *',
                  hint: 'e.g. 9876543210',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Email Address (Optional)',
                  hint: 'e.g. rahul@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                const Text(
                  'GENDER',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final selected = _gender == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        selected: selected,
                        label: Text(g),
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
                  const Text(
                    'MEMBERSHIP PLAN *',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
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
                              _feeController.text = val.defaultFee.toStringAsFixed(0);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'START DATE',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'FEE AMOUNT (₹)',
                          controller: _feeController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Personal Trainer Assignment (Optional)
                  const Text(
                    'ASSIGN PERSONAL TRAINER (OPTIONAL)',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
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
                          const DropdownMenuItem<TrainerModel?>(
                            value: null,
                            child: Text('No Trainer Assigned (General Membership)', style: TextStyle(color: AppTheme.textMuted)),
                          ),
                          ..._trainers.map((t) => DropdownMenuItem<TrainerModel?>(
                                value: t,
                                child: Text('${t.name} • ${t.speciality}'),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTrainer = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_selectedTrainer != null) ...[
                    CustomTextField(
                      label: 'Personal Training Fee (₹)',
                      controller: _ptFeeController,
                      keyboardType: TextInputType.number,
                      hint: '0',
                    ),
                    const SizedBox(height: 20),
                  ],
                ],

                CustomTextField(
                  label: 'Notes & Medical History (Optional)',
                  hint: 'Any fitness notes or goals...',
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
                    title: const Text('Save member to phone contacts', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('Syncs contact directly with device phonebook', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: isEdit ? 'Update Member Profile' : 'Save & Register Member',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _saveMember,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
