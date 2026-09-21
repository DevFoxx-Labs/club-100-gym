import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import 'mpin_setup_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  final String gymName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String currency;

  const AdminSetupScreen({
    super.key,
    required this.gymName,
    required this.ownerName,
    required this.phone,
    required this.email,
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

  @override
  void initState() {
    super.initState();
    _adminNameController = TextEditingController(text: widget.ownerName);
    _adminPhoneController = TextEditingController(text: widget.phone);
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
                  validator: (v) => v == null || v.trim().isEmpty ? 'Admin name is required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Mobile Number',
                  hint: 'Mobile number',
                  controller: _adminPhoneController,
                  keyboardType: TextInputType.phone,
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
                            address: widget.address,
                            city: widget.city,
                            currency: widget.currency,
                            adminName: _adminNameController.text.trim(),
                            adminPhone: _adminPhoneController.text.trim(),
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

