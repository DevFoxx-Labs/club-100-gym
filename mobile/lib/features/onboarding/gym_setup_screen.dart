import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/phone_input_field.dart';
import 'admin_setup_screen.dart';

class GymSetupScreen extends StatefulWidget {
  const GymSetupScreen({super.key});

  @override
  State<GymSetupScreen> createState() => _GymSetupScreenState();
}

class _GymSetupScreenState extends State<GymSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final ValueNotifier<String> _phoneDialCode = ValueNotifier(PhoneUtils.defaultDialCode);
  String _currency = 'INR (₹)';

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _phoneController.dispose();
    _phoneDialCode.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

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
                  hint: 'e.g. Elite Fitness Gym',
                  controller: _nameController,
                  validator: (v) => FormValidators.validateName(v, fieldName: 'Gym name'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Owner / Admin Name',
                  hint: 'e.g. John Doe',
                  controller: _ownerController,
                ),
                const SizedBox(height: 16),

                ValueListenableBuilder<String>(
                  valueListenable: _phoneDialCode,
                  builder: (context, dialCode, _) => PhoneInputField(
                    label: 'Helpline Phone Number *',
                    controller: _phoneController,
                    dialCodeNotifier: _phoneDialCode,
                    validator: (v) => FormValidators.validatePhoneForCountry(
                      v,
                      dialCode: dialCode,
                      fieldName: 'Phone number',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Email Address',
                  hint: 'e.g. contact@elitefitnessgym.com',
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
                  hint: 'e.g. Main Street, Suite 100',
                  controller: _addressController,
                  maxLines: 2,
                  validator: (v) => FormValidators.validateAddress(v, fieldName: 'Address'),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'City',
                        hint: 'e.g. Mumbai',
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
                            phone: PhoneUtils.combine(_phoneDialCode.value, _phoneController.text.trim()),
                            email: _emailController.text.trim(),
                            website: _websiteController.text.trim().isNotEmpty
                                ? _websiteController.text.trim()
                                : null,
                            address: _addressController.text.trim(),
                            city: _cityController.text.trim(),
                            currency: _currency,
                          ),
                        ),
                      );
                    }
                  },
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
