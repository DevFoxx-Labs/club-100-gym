import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/supabase_config.dart';
import '../../core/localization/app_translations.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';
import '../settings/change_mpin_screen.dart';
import '../settings/sign_out_flow.dart';

/// Forgot MPIN: the admin proves who they are, then sets a new MPIN.
///
/// 1. Cloud account password (if this gym is linked to an account) — the
///    strongest proof; works even if the fingerprint was never set up.
/// 2. Fingerprint / face (if biometric login was enabled for this app).
/// 3. Last resort: sign out & reset this phone. With a cloud account the data
///    comes back on sign-in; without one, local data is lost (clearly warned).
class ForgotMpinScreen extends StatefulWidget {
  const ForgotMpinScreen({super.key});

  @override
  State<ForgotMpinScreen> createState() => _ForgotMpinScreenState();
}

class _ForgotMpinScreenState extends State<ForgotMpinScreen> {
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();

  bool _isLoading = true;
  bool _isVerifying = false;
  bool _obscure = true;
  bool _hasAccount = false;
  bool _biometricEnabled = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final admin = await SettingsRepository().getAdminInfo();
    final gymId = await SupabaseConfig.getActiveGymId();
    final biometricAvailable = await _biometricService.isBiometricAvailable();
    if (!mounted) return;
    setState(() {
      _hasAccount = AuthService.instance.isSignedIn && gymId != null;
      _email = AuthService.instance.email;
      _biometricEnabled = admin.isBiometricEnabled && biometricAvailable;
      _isLoading = false;
    });
  }

  void _goToNewMpin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ChangeMpinScreen(resetMode: true)),
    );
  }

  Future<void> _verifyWithPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _isVerifying = true);
    final error = await AuthService.instance.verifyPassword(password);
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.statusOverdue),
      );
      return;
    }
    _goToNewMpin();
  }

  Future<void> _verifyWithBiometric() async {
    final ok = await _biometricService.authenticate(localizedReason: tr('forgot_mpin_biometric_reason'));
    if (ok && mounted) _goToNewMpin();
  }

  Future<void> _resetPhone() async {
    await runSignOutFlow(
      context,
      title: tr('forgot_mpin_reset_title'),
      message: _hasAccount ? tr('forgot_mpin_reset_msg_cloud') : tr('forgot_mpin_reset_msg_local'),
      confirmLabel: tr('forgot_mpin_reset_confirm'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(tr('forgot_mpin_title'))),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + safeBottom + keyboard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr('forgot_mpin_intro'),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    if (_hasAccount) ...[
                      _OptionCard(
                        icon: Icons.lock_reset_rounded,
                        title: tr('forgot_mpin_option_password'),
                        subtitle: tr('forgot_mpin_option_password_sub', {'email': _email ?? ''}),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextField(
                              label: tr('authPasswordLabel'),
                              controller: _passwordController,
                              obscureText: _obscure,
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            const SizedBox(height: 12),
                            NeonButton(
                              text: tr('forgot_mpin_verify'),
                              width: double.infinity,
                              isLoading: _isVerifying,
                              onPressed: _verifyWithPassword,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr('forgot_mpin_password_hint'),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_biometricEnabled) ...[
                      _OptionCard(
                        icon: Icons.fingerprint_rounded,
                        title: tr('forgot_mpin_option_biometric'),
                        subtitle: tr('forgot_mpin_option_biometric_sub'),
                        child: NeonButton(
                          text: tr('forgot_mpin_scan'),
                          icon: Icons.fingerprint_rounded,
                          width: double.infinity,
                          isSecondary: _hasAccount,
                          onPressed: _verifyWithBiometric,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    _OptionCard(
                      icon: Icons.restart_alt_rounded,
                      iconColor: AppTheme.statusOverdue,
                      title: tr('forgot_mpin_option_reset'),
                      subtitle: _hasAccount ? tr('forgot_mpin_option_reset_sub_cloud') : tr('forgot_mpin_option_reset_sub_local'),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.statusOverdue,
                          side: const BorderSide(color: AppTheme.statusOverdue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _resetPhone,
                        child: Text(tr('forgot_mpin_reset_confirm'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _OptionCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.neonLime;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
