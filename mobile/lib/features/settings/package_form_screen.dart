import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/package_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class PackageFormScreen extends StatefulWidget {
  final PackageModel? package;

  const PackageFormScreen({super.key, this.package});

  bool get isEdit => package != null;

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final PackageRepository _repository = PackageRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.package != null) {
      _nameController.text = widget.package!.name;
      _descController.text = widget.package!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now().toIso8601String();
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (widget.isEdit) {
      final updated = widget.package!.copyWith(
        name: name,
        description: desc.isEmpty ? null : desc,
        updatedAt: now,
      );
      await _repository.updatePackage(updated);
    } else {
      final newPkg = PackageModel(
        id: const Uuid().v4(),
        name: name,
        description: desc.isEmpty ? null : desc,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.insertPackage(newPkg);
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
          widget.isEdit ? 'EDIT PACKAGE' : 'ADD PACKAGE',
          style: const TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'PACKAGE CATEGORY NAME *',
                hint: 'e.g. Standard Gym Access, Strength & CrossFit, Zumba + Cardio',
                controller: _nameController,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Package name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'DESCRIPTION (OPTIONAL)',
                hint: 'e.g. Full floor access, free weights, locker room, cardio machines',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              NeonButton(
                text: widget.isEdit ? 'Save Changes' : 'Create Package',
                icon: Icons.check,
                isLoading: _isLoading,
                onPressed: _savePackage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

