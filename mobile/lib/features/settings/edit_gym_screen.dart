import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class EditGymScreen extends StatefulWidget {
  const EditGymScreen({super.key});

  @override
  State<EditGymScreen> createState() => _EditGymScreenState();
}

class _EditGymScreenState extends State<EditGymScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsRepo = SettingsRepository();

  late TextEditingController _nameController;
  late TextEditingController _ownerController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  String _currency = 'INR (₹)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ownerController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();

    _loadGymInfo();
  }

  Future<void> _loadGymInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    setState(() {
      _nameController.text = gym.name;
      _ownerController.text = gym.ownerName ?? '';
      _phoneController.text = gym.phone;
      _emailController.text = gym.email ?? '';
      _addressController.text = gym.address;
      _cityController.text = gym.city ?? '';
      _currency = gym.currency;
      _isLoading = false;
    });
  }

  Future<void> _saveGymInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final info = GymInfoModel(
      id: 'default',
      name: _nameController.text.trim(),
      ownerName: _ownerController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      currency: _currency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _settingsRepo.saveGymInfo(info);
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gym details updated successfully')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDIT GYM INFO'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(label: 'Gym Name *', controller: _nameController, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      CustomTextField(label: 'Owner Name', controller: _ownerController),
                      const SizedBox(height: 16),
                      CustomTextField(label: 'Phone Number *', controller: _phoneController, keyboardType: TextInputType.phone, validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                      const SizedBox(height: 16),
                      CustomTextField(label: 'Email Address', controller: _emailController, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      CustomTextField(label: 'Address', controller: _addressController, maxLines: 2),
                      const SizedBox(height: 16),
                      CustomTextField(label: 'City', controller: _cityController),
                      const SizedBox(height: 32),
                      NeonButton(
                        text: 'Save Gym Information',
                        width: double.infinity,
                        onPressed: _saveGymInfo,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

