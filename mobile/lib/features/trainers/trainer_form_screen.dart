import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/phone_input_field.dart';

class TrainerFormScreen extends StatefulWidget {
  final TrainerModel? trainer;

  const TrainerFormScreen({super.key, this.trainer});

  bool get isEdit => trainer != null;

  @override
  State<TrainerFormScreen> createState() => _TrainerFormScreenState();
}

class _TrainerFormScreenState extends State<TrainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _salaryController = TextEditingController();
  final TrainerRepository _repository = TrainerRepository();
  String? _photoPath;
  bool _isLoading = false;
  bool _isActive = true;
  String _role = 'Trainer';
  final ValueNotifier<String> _phoneDialCode = ValueNotifier(PhoneUtils.defaultDialCode);

  @override
  void initState() {
    super.initState();
    if (widget.trainer != null) {
      final t = widget.trainer!;
      _nameController.text = t.name;
      final (dialCode, localPhone) = PhoneUtils.split(t.phone);
      _phoneController.text = localPhone;
      _phoneDialCode.value = dialCode;
      _specializationController.text = t.specialization ?? '';
      _salaryController.text = t.monthlySalary != null ? t.monthlySalary!.toStringAsFixed(0) : '';
      _photoPath = t.photoPath;
      _isActive = t.isActive;
      _role = t.role;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _phoneDialCode.dispose();
    _specializationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _saveTrainer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now().toIso8601String();
    final salary = double.tryParse(_salaryController.text.trim());
    final spec = _specializationController.text.trim();
    final phone = PhoneUtils.combine(_phoneDialCode.value, _phoneController.text.trim());

    if (widget.isEdit) {
      final updated = widget.trainer!.copyWith(
        name: _nameController.text.trim(),
        phone: phone,
        role: _role,
        specialization: spec.isEmpty ? null : spec,
        monthlySalary: salary,
        photoPath: _photoPath,
        isActive: _isActive,
        updatedAt: now,
      );
      await _repository.updateTrainer(updated);
    } else {
      final newTrainer = TrainerModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        phone: phone,
        role: _role,
        specialization: spec.isEmpty ? null : spec,
        monthlySalary: salary,
        photoPath: _photoPath,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.insertTrainer(newTrainer);
    }

    AppStateService.instance.notifyTrainersChanged();

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
          widget.isEdit ? 'EDIT TRAINER' : 'ADD TRAINER',
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: EditableMemberAvatar(
                  name: _nameController.text.isNotEmpty ? _nameController.text : 'Trainer',
                  photoPath: _photoPath,
                  radius: 46,
                  defaultInitials: 'T',
                  subfolder: 'trainer_photos',
                  onPhotoChanged: (path) => setState(() => _photoPath = path),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: 'TRAINER FULL NAME *',
                hint: 'e.g. Vikram Singh',
                controller: _nameController,
                validator: (val) => FormValidators.validateName(val, fieldName: 'Trainer name'),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<String>(
                valueListenable: _phoneDialCode,
                builder: (context, dialCode, _) => PhoneInputField(
                  label: 'MOBILE PHONE NUMBER *',
                  controller: _phoneController,
                  dialCodeNotifier: _phoneDialCode,
                  validator: (val) => FormValidators.validatePhoneForCountry(
                    val,
                    dialCode: dialCode,
                    fieldName: 'Phone number',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'STAFF ROLE',
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _role == 'Trainer',
                    label: const Text('Trainer'),
                    avatar: const Icon(Icons.fitness_center_rounded, size: 16),
                    selectedColor: const Color(0xFFD4FF00),
                    backgroundColor: const Color(0xFF1E1E1E),
                    labelStyle: TextStyle(
                      color: _role == 'Trainer' ? const Color(0xFF121212) : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _role = 'Trainer');
                    },
                  ),
                  ChoiceChip(
                    selected: _role == 'Staff',
                    label: const Text('Staff'),
                    avatar: const Icon(Icons.badge_outlined, size: 16),
                    selectedColor: const Color(0xFFD4FF00),
                    backgroundColor: const Color(0xFF1E1E1E),
                    labelStyle: TextStyle(
                      color: _role == 'Staff' ? const Color(0xFF121212) : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _role = 'Staff');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'SPECIALIZATION / EXPERTISE',
                hint: 'e.g. Personal Training, Crossfit, Zumba, Nutrition',
                controller: _specializationController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'MONTHLY BASE SALARY (₹)',
                hint: 'e.g. 25000',
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? null
                    : FormValidators.validateAmount(val, fieldName: 'Monthly salary', allowZero: true),
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: 16),
                Card(
                  child: SwitchListTile(
                    title: const Text('Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _isActive ? 'Trainer is actively taking members' : 'Trainer is marked inactive',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    value: _isActive,
                    activeThumbColor: const Color(0xFFD4FF00),
                    activeTrackColor: const Color(0xFFD4FF00).withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              NeonButton(
                text: widget.isEdit ? 'Save Changes' : 'Register Trainer',
                icon: Icons.check,
                isLoading: _isLoading,
                onPressed: _saveTrainer,
              ),
              SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

