import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/gym_logo_picker.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
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
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  String? _logoPath;
  String _currency = 'INR (₹)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ownerController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();

    _loadGymInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadGymInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    if (mounted) {
      setState(() {
        _nameController.text = gym.name;
        _ownerController.text = gym.ownerName ?? '';
        _phoneController.text = gym.phone;
        _emailController.text = gym.email ?? '';
        _websiteController.text = gym.website ?? '';
        _addressController.text = gym.address;
        _cityController.text = gym.city ?? '';
        _currency = gym.currency;
        _logoPath = gym.logoPath;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGymInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final info = GymInfoModel(
      id: 'default',
      name: _nameController.text.trim(),
      ownerName: _ownerController.text.trim().isNotEmpty ? _ownerController.text.trim() : null,
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      address: _addressController.text.trim(),
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      logoPath: _logoPath,
      currency: _currency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _settingsRepo.saveGymInfo(info);

    // Notify all app components to refresh gym branding and info immediately
    AppStateService.instance.notifyGymInfoChanged();

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym details updated successfully')),
      );
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
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Gym Logo
                      EditableGymLogo(
                        logoPath: _logoPath,
                        size: 90,
                        onLogoChanged: (p) => setState(() => _logoPath = p),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap camera icon to set Gym Logo', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(height: 24),

                      CustomTextField(
                        label: 'Gym Name *',
                        controller: _nameController,
                        validator: (v) => FormValidators.validateName(v, fieldName: 'Gym Name'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Owner Name',
                        controller: _ownerController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Phone Number *',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => FormValidators.validatePhone(v, fieldName: 'Phone Number'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => FormValidators.validateEmail(v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Gym Website',
                        hint: 'e.g. elitefitnessgym.com or https://...',
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        validator: (v) => FormValidators.validateWebsite(v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Address *',
                        controller: _addressController,
                        maxLines: 2,
                        validator: (v) => FormValidators.validateRequired(v, 'Address'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'City',
                        controller: _cityController,
                      ),
                      const SizedBox(height: 32),
                      NeonButton(
                        text: 'Save Gym Information',
                        width: double.infinity,
                        isLoading: _isLoading,
                        onPressed: _saveGymInfo,
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
