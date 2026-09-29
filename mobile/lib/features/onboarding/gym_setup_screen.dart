import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../core/sync/supabase_sync_service.dart';
import '../../core/utils/form_validators.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/navigation/main_navigation_screen.dart';
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
  bool _isCheckingCloud = false;

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
                  text: _isCheckingCloud ? 'Checking Cloud Records...' : 'Continue to Admin Setup →',
                  width: double.infinity,
                  isLoading: _isCheckingCloud,
                  onPressed: _handleContinue,
                ),
                SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = PhoneUtils.combine(_phoneDialCode.value, _phoneController.text.trim());
    final email = _emailController.text.trim();

    setState(() => _isCheckingCloud = true);

    try {
      final existingGym = await SupabaseSyncService.instance.findGymByEmailOrPhone(
        phone: phone,
        email: email.isNotEmpty ? email : null,
      );

      if (mounted) setState(() => _isCheckingCloud = false);

      if (existingGym != null && mounted) {
        final gymName = existingGym['name'] ?? 'Your Gym';
        final gymId = existingGym['id']?.toString() ?? '';

        final shouldRestore = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: AppTheme.neonLime, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: AppTheme.neonLime, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Previous Gym Found!',
                    style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We found existing gym data for "$gymName" linked to this mobile/email on Supabase Cloud.',
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Would you like to restore all previous members, plans, payments, and receipts onto this device?',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Start Fresh Setup', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonLime,
                  foregroundColor: AppTheme.darkBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore All Data', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (shouldRestore == true && mounted) {
          await _restoreData(gymId, gymName);
          return;
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingCloud = false);
    }

    // Proceed to Step 2 if new or user opted to start fresh
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminSetupScreen(
          gymName: _nameController.text.trim(),
          ownerName: _ownerController.text.trim(),
          phone: PhoneUtils.combine(_phoneDialCode.value, _phoneController.text.trim()),
          email: _emailController.text.trim(),
          website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          currency: _currency,
        ),
      ),
    );
  }

  Future<void> _restoreData(String gymId, String gymName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.neonLime),
                const SizedBox(height: 20),
                Text('Restoring $gymName...', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Syncing members, plans, payments & history from Supabase Cloud...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final res = await SupabaseSyncService.instance.restoreAllGymData(gymId);
    if (!mounted) return;
    Navigator.pop(context); // Dismiss progress dialog

    if (res.success) {
      final security = SecurityService();
      await security.setSetupComplete(true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back! Restored ${res.totalRecordsRestored} records for $gymName.'),
          backgroundColor: AppTheme.neonLime,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${res.error}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
