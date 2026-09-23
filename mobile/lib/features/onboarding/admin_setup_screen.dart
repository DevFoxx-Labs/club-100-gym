import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/phone_input_field.dart';
import 'mpin_setup_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  final String gymName;
  final String ownerName;
  final String phone;
  final String email;
  final String? website;
  final String address;
  final String city;
  final String currency;

  const AdminSetupScreen({
    super.key,
    required this.gymName,
    required this.ownerName,
    required this.phone,
    required this.email,
    this.website,
    required this.address,
    required this.city,
    required this.currency,
  });

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adminNameController;
  late TextEditingController _adminPhoneController;
  late ValueNotifier<String> _adminPhoneDialCode;

  @override
  void initState() {
    super.initState();
    _adminNameController = TextEditingController(text: widget.ownerName);
    final (dialCode, localPhone) = PhoneUtils.split(widget.phone);
    _adminPhoneController = TextEditingController(text: localPhone);
    _adminPhoneDialCode = ValueNotifier(dialCode);
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminPhoneController.dispose();
    _adminPhoneDialCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 2 OF 4: ADMIN PROFILE'),
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
                  'Administrator Setup',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your local administrator profile. Version 1 supports local single-admin control.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 24),

                CustomTextField(
                  label: 'Admin Name *',
                  hint: 'Full name',
                  controller: _adminNameController,
                  validator: (v) => FormValidators.validateName(v, fieldName: 'Admin name'),
                ),
                const SizedBox(height: 16),

                ValueListenableBuilder<String>(
                  valueListenable: _adminPhoneDialCode,
                  builder: (context, dialCode, _) => PhoneInputField(
                    label: 'Mobile Number *',
                    controller: _adminPhoneController,
                    dialCodeNotifier: _adminPhoneDialCode,
                    validator: (v) => FormValidators.validatePhoneForCountry(
                      v,
                      dialCode: dialCode,
                      fieldName: 'Admin mobile number',
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: 'Create MPIN →',
                  width: double.infinity,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MpinSetupScreen(
                            gymName: widget.gymName,
                            ownerName: widget.ownerName,
                            gymPhone: widget.phone,
                            email: widget.email,
                            website: widget.website,
                            address: widget.address,
                            city: widget.city,
                            currency: widget.currency,
                            adminName: _adminNameController.text.trim(),
                            adminPhone: PhoneUtils.combine(_adminPhoneDialCode.value, _adminPhoneController.text.trim()),
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
