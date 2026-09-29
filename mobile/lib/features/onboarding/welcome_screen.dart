import 'package:flutter/material.dart';
import '../../core/security/security_service.dart';
import '../../core/sync/supabase_sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../shared/navigation/main_navigation_screen.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gym_logo_view.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/phone_input_field.dart';
import 'gym_setup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.paddingOf(context).bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40 - MediaQuery.paddingOf(context).bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 10),

                    // Brand Hero Header
                    Column(
                      children: [
                        const GymLogoView(
                          size: 100,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ELITE FITNESS GYM',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textWhite,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gym Member & Fee Management App',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neonLime,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Manage members, track membership dues, record payments, and generate digital PDF receipts offline on your device.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Feature Highlights
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: const Column(
                        children: [
                          _FeatureRow(icon: Icons.offline_pin_rounded, title: '100% Offline-First', subtitle: 'No internet required. Data stays on your device.'),
                          SizedBox(height: 14),
                          _FeatureRow(icon: Icons.receipt_long_rounded, title: 'Instant Receipts & QR', subtitle: 'PDF receipts with tamper-resistant QR codes.'),
                          SizedBox(height: 14),
                          _FeatureRow(icon: Icons.security_rounded, title: 'Secure MPIN & Biometrics', subtitle: 'Encrypted MPIN and fingerprint authentication.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue Action
                    NeonButton(
                      text: 'Get Started →',
                      width: double.infinity,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GymSetupScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.neonLime,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.cloud_download_rounded, size: 18),
                      label: const Text(
                        'Already have an account? Restore from Cloud',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => _openRestoreSheet(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRestoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _RestoreGymSheet(),
    );
  }
}

class _RestoreGymSheet extends StatefulWidget {
  const _RestoreGymSheet();

  @override
  State<_RestoreGymSheet> createState() => _RestoreGymSheetState();
}

class _RestoreGymSheetState extends State<_RestoreGymSheet> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final ValueNotifier<String> _dialCode = ValueNotifier(PhoneUtils.defaultDialCode);
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _dialCode.dispose();
    super.dispose();
  }

  Future<void> _searchAndRestore() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (phone.isEmpty && email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number or email address.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final fullPhone = phone.isNotEmpty ? PhoneUtils.combine(_dialCode.value, phone) : '';

    final existing = await SupabaseSyncService.instance.findGymByEmailOrPhone(
      phone: fullPhone,
      email: email.isNotEmpty ? email : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No gym account found matching this mobile/email on Supabase Cloud.'),
          backgroundColor: AppTheme.statusOverdue,
        ),
      );
      return;
    }

    final gymName = existing['name'] ?? 'Your Gym';
    final gymId = existing['id']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonLime, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_done_rounded, color: AppTheme.neonLime, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(gymName, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold))),
          ],
        ),
        content: const Text(
          'We found your gym cloud backup! Would you like to restore all members, plans, payments, and receipts to this device?',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonLime, foregroundColor: AppTheme.darkBackground),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restore Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    final res = await SupabaseSyncService.instance.restoreAllGymData(gymId);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.success) {
      final security = SecurityService();
      await security.setSetupComplete(true);
      if (!mounted) return;

      Navigator.pop(context); // Close bottom sheet
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
          backgroundColor: AppTheme.statusOverdue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RESTORE GYM BACKUP', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 16)),
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textMuted), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the mobile number or email you previously used to set up your gym to restore all your data.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<String>(
            valueListenable: _dialCode,
            builder: (context, code, _) => PhoneInputField(
              label: 'Owner Mobile Number',
              controller: _phoneController,
              dialCodeNotifier: _dialCode,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'OR Registered Email',
            hint: 'e.g. contact@elitefitnessgym.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 22),
          NeonButton(
            text: 'Search & Restore Gym',
            icon: Icons.cloud_download_rounded,
            width: double.infinity,
            isLoading: _isLoading,
            onPressed: _searchAndRestore,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Icon(icon, color: AppTheme.neonLime, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

