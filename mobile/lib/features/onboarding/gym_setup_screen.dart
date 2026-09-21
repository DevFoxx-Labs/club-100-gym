import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import 'admin_setup_screen.dart';

class GymSetupScreen extends StatefulWidget {
  const GymSetupScreen({super.key});

  @override
  State<GymSetupScreen> createState() => _GymSetupScreenState();
}

class _GymSetupScreenState extends State<GymSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Club 100 The Gym');
  final _ownerController = TextEditingController(text: 'Karunendu');
  final _phoneController = TextEditingController(text: '070843 06574');
  final _emailController = TextEditingController(text: 'info@club100gym.com');
  final _addressController = TextEditingController(text: '1st Floor TP Nagar, Transport Nagar, Prayagraj, UP 211011');
  final _cityController = TextEditingController(text: 'Prayagraj');
  String _currency = 'INR (₹)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 1 OF 4: GYM SETUP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gym Information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter details of your fitness club to personalize your receipts and member profiles.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  label: 'Gym Name *',
                  hint: 'e.g. Club 100 The Gym',
                  controller: _nameController,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Gym name is required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Owner / Admin Name',
                  hint: 'Owner name',
                  controller: _ownerController,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Helpline Phone Number *',
                  hint: '070843 06574',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Address',
                  hint: 'Gym street address',
                  controller: _addressController,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'City',
                        hint: 'Prayagraj',
                        controller: _cityController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CURRENCY',
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
                              child: DropdownButton<String>(
                                value: _currency,
                                isExpanded: true,
                                dropdownColor: AppTheme.darkSurface,
                                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                                items: ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)']
                                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _currency = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: 'Continue to Admin Setup →',
                  width: double.infinity,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminSetupScreen(
                            gymName: _nameController.text.trim(),
                            ownerName: _ownerController.text.trim(),
                            phone: _phoneController.text.trim(),
                            email: _emailController.text.trim(),
                            address: _addressController.text.trim(),
                            city: _cityController.text.trim(),
                            currency: _currency,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

