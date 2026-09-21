import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/package_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class PlanFormScreen extends StatefulWidget {
  final PlanModel? plan;
  final String? initialPackageId;

  const PlanFormScreen({super.key, this.plan, this.initialPackageId});

  bool get isEdit => plan != null;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _feeController = TextEditingController(text: '1500');
  final _descController = TextEditingController();

  final PlanRepository _planRepo = PlanRepository();
  final PackageRepository _packageRepo = PackageRepository();

  String? _selectedPackageId;
  List<PackageModel> _packages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      final p = widget.plan!;
      _nameController.text = p.name;
      _durationController.text = p.durationDays.toString();
      _feeController.text = p.defaultFee.toStringAsFixed(0);
      _descController.text = p.description ?? '';
      _selectedPackageId = p.packageId;
    } else {
      _selectedPackageId = widget.initialPackageId;
    }
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await _packageRepo.getAllPackages();
    if (mounted) setState(() => _packages = packages);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 30;
    final fee = double.tryParse(_feeController.text.trim()) ?? 1500.0;
    final desc = _descController.text.trim();

    if (widget.isEdit) {
      final updated = widget.plan!.copyWith(
        packageId: _selectedPackageId,
        name: name,
        durationDays: duration,
        defaultFee: fee,
        description: desc.isEmpty ? null : desc,
        updatedAt: now,
      );
      await _planRepo.updatePlan(updated);
    } else {
      final newPlan = PlanModel(
        id: const Uuid().v4(),
        packageId: _selectedPackageId,
        name: name,
        durationDays: duration,
        defaultFee: fee,
        description: desc.isEmpty ? null : desc,
        createdAt: now,
        updatedAt: now,
      );
      await _planRepo.addPlan(newPlan);
    }

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
          widget.isEdit ? 'EDIT PLAN' : 'ADD PLAN',
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
              CustomTextField(
                label: 'PLAN NAME *',
                hint: 'e.g. Monthly Plan, 3 Months Pro, Annual VIP',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Plan name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'MEMBERSHIP PACKAGE CATEGORY',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _selectedPackageId,
                dropdownColor: const Color(0xFF252525),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Select Package (Optional)',
                  prefixIcon: Icon(Icons.inventory_2_outlined, color: Color(0xFFD4FF00)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Package (General)')),
                  ..._packages.map((pkg) => DropdownMenuItem(value: pkg.id, child: Text(pkg.name))),
                ],
                onChanged: (val) => setState(() => _selectedPackageId = val),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'DURATION (DAYS) *',
                      hint: '30',
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || int.tryParse(v.trim()) == null) return 'Enter days';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'DEFAULT FEE (₹) *',
                      hint: '1500',
                      controller: _feeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || double.tryParse(v.trim()) == null) return 'Enter fee';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'DESCRIPTION (OPTIONAL)',
                hint: 'Features included, personal trainer assessment, cardio access, etc.',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              NeonButton(
                text: widget.isEdit ? 'Save Changes' : 'Create Plan',
                icon: Icons.check,
                isLoading: _isLoading,
                onPressed: _savePlan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

