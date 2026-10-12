import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/supabase_config.dart';
import '../../core/localization/app_translations.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/form_validators.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gym_logo_view.dart';
import '../../shared/widgets/neon_button.dart';
import '../onboarding/gym_setup_screen.dart';
import '../onboarding/mpin_setup_screen.dart';

enum AccountAuthMode { signUp, signIn }

enum _LinkChoice { uploadLocal, useCloud, cancel }

class AccountAuthScreen extends StatefulWidget {
  final AccountAuthMode initialMode;
  final bool linkExistingLocalData;

  const AccountAuthScreen({
    super.key,
    this.initialMode = AccountAuthMode.signUp,
    this.linkExistingLocalData = false,
  });

  @override
  State<AccountAuthScreen> createState() => _AccountAuthScreenState();
}

class _AccountAuthScreenState extends State<AccountAuthScreen> {
  late AccountAuthMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mode == AccountAuthMode.signUp) {
      await _handleSignUp();
    } else {
      await _handleSignIn();
    }
  }

  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);

    final res = await AuthService.instance.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error!),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // The Supabase project requires email verification: there is no session
    // yet, so continuing would set up a gym that silently never backs up.
    if (res.needsEmailConfirmation) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            tr('auth_confirm_email_title'),
            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
          ),
          content: Text(
            tr('auth_confirm_email_message'),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('common_ok'), style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() {
        _mode = AccountAuthMode.signIn;
        _confirmPasswordController.clear();
      });
      return;
    }

    if (widget.linkExistingLocalData) {
      await AuthService.instance.registerNewGym();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('cloud_link_success')),
          backgroundColor: AppTheme.neonLime,
        ),
      );
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GymSetupScreen(
            prefillEmail: _emailController.text.trim(),
          ),
        ),
      );
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final error = await AuthService.instance.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _handlePostSignIn();
  }

  Future<void> _handlePostSignIn() async {
    var progressOpen = true;
    _showProgressDialog(tr('authRestoreLoading'), tr('auth_connecting_cloud'));
    void closeProgress() {
      if (progressOpen && mounted) {
        Navigator.pop(context);
        progressOpen = false;
      }
    }

    try {
      final gymId = await AuthService.instance.findMyGymId();

      if (gymId == null) {
        closeProgress();
        if (!mounted) return;

        if (widget.linkExistingLocalData) {
          await AuthService.instance.registerNewGym();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('cloud_link_success')),
              backgroundColor: AppTheme.neonLime,
            ),
          );
          Navigator.pop(context, true);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GymSetupScreen(
                prefillEmail: _emailController.text.trim(),
              ),
            ),
          );
        }
        return;
      }

      if (widget.linkExistingLocalData) {
        closeProgress();
        await _linkToFoundGym(gymId);
        return;
      }

      final restoreRes = await SyncEngine.instance.restoreFromCloud(gymId);
      closeProgress();
      if (!mounted) return;

      if (!restoreRes.success) {
        _showError('${tr('authRestoreFailed')}: ${restoreRes.error}');
        return;
      }

      final gymInfo = await SettingsRepository().getGymInfo();
      final adminInfo = await SettingsRepository().getAdminInfo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('auth_restored_records', {'count': '${restoreRes.restored}', 'gym': gymInfo.name})),
          backgroundColor: AppTheme.neonLime,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MpinSetupScreen.restore(
            gymName: gymInfo.name,
            adminName: adminInfo.name.isNotEmpty ? adminInfo.name : 'Admin',
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      debugPrint('[AccountAuthScreen] post sign-in failed: $e');
      closeProgress();
      if (mounted) _showError(tr('auth_cloud_unreachable'));
    }
  }

  /// Link mode, and the signed-in account already owns a cloud gym: let the
  /// admin decide what happens to this phone's data instead of wiping it.
  Future<void> _linkToFoundGym(String gymId) async {
    // Same gym this phone was already linked to (e.g. session expired):
    // nothing to choose, just resume syncing.
    if (await SupabaseConfig.getActiveGymId() == gymId) {
      SyncEngine.instance.requestSync(immediate: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('cloud_link_success')), backgroundColor: AppTheme.neonLime),
      );
      Navigator.pop(context, true);
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<_LinkChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonLime, width: 1.5),
        ),
        title: Text(
          tr('cloud_existing_gym_title'),
          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('cloud_existing_gym_desc'),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              NeonButton(
                text: tr('cloud_choice_upload'),
                icon: Icons.cloud_upload_rounded,
                width: double.infinity,
                onPressed: () => Navigator.pop(ctx, _LinkChoice.uploadLocal),
              ),
              const SizedBox(height: 10),
              NeonButton(
                text: tr('cloud_choice_use_cloud'),
                icon: Icons.cloud_download_rounded,
                width: double.infinity,
                isSecondary: true,
                onPressed: () => Navigator.pop(ctx, _LinkChoice.useCloud),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx, _LinkChoice.cancel),
                child: Text(tr('common_cancel'), style: const TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    switch (choice) {
      case _LinkChoice.uploadLocal:
        await AuthService.instance.linkToExistingGym(gymId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('cloud_link_success')), backgroundColor: AppTheme.neonLime),
        );
        Navigator.pop(context, true);
      case _LinkChoice.useCloud:
        _showProgressDialog(tr('authRestoreLoading'), tr('cloud_replacing_local'));
        final res = await SyncEngine.instance.restoreFromCloud(gymId);
        if (!mounted) return;
        Navigator.pop(context); // dismiss progress
        if (!res.success) {
          _showError('${tr('authRestoreFailed')}: ${res.error}');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('authRestoreSuccess')), backgroundColor: AppTheme.neonLime),
        );
        Navigator.pop(context, true);
      case _LinkChoice.cancel:
      case null:
        // Don't leave a signed-in account that isn't bound to any gym.
        await AuthService.instance.discardSession();
    }
  }

  void _showProgressDialog(String title, String subtitle) {
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
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showForgotPasswordSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ForgotPasswordSheet(
        initialEmail: _emailController.text.trim(),
        onSuccess: (newPassword) {
          _passwordController.text = newPassword;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == AccountAuthMode.signUp;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.linkExistingLocalData
            ? tr('authLinkGymTitle')
            : (isSignUp ? tr('authTitleSignUp') : tr('authTitleSignIn'))),
        leading: widget.linkExistingLocalData
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  )
                : null),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + safeBottom),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.linkExistingLocalData) ...[
                  const Center(child: GymLogoView(size: 72)),
                  const SizedBox(height: 16),
                ],

                // Segmented Mode Toggle (only if not restricted to link mode)
                if (!widget.linkExistingLocalData) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _mode = AccountAuthMode.signUp),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSignUp ? AppTheme.neonLime : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tr('authButtonSignUp'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSignUp ? Colors.black : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _mode = AccountAuthMode.signIn),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSignUp ? AppTheme.neonLime : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tr('authButtonSignIn'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !isSignUp ? Colors.black : AppTheme.textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Header Texts
                Text(
                  widget.linkExistingLocalData
                      ? tr('authLinkGymDesc')
                      : (isSignUp ? tr('authSubtitleSignUp') : tr('authSubtitleSignIn')),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                CustomTextField(
                  label: tr('authEmailLabel'),
                  hint: tr('authEmailHint'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) => FormValidators.validateEmail(v, required: true),
                ),
                const SizedBox(height: 16),

                // Password
                CustomTextField(
                  label: tr('authPasswordLabel'),
                  hint: tr('authPasswordHint'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return tr('auth_password_min');
                    }
                    return null;
                  },
                ),

                // Confirm Password (Sign Up only)
                if (isSignUp) ...[
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: tr('authConfirmPasswordLabel'),
                    hint: tr('authConfirmPasswordHint'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_clock_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v != _passwordController.text) {
                        return tr('auth_passwords_dont_match');
                      }
                      return null;
                    },
                  ),
                ],

                // Forgot Password link (Sign In only)
                if (!isSignUp) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordSheet,
                      child: Text(
                        tr('authForgotPassword'),
                        style: TextStyle(
                          color: AppTheme.neonLime,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                ],

                // Submit Button
                NeonButton(
                  text: widget.linkExistingLocalData
                      ? tr('authLinkGymButton')
                      : (isSignUp ? tr('authButtonSignUp') : tr('authButtonSignIn')),
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),

                // Offline Continue (Only on first onboarding, not in Link Gym mode)
                if (!widget.linkExistingLocalData) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GymSetupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        tr('authOfflineContinue'),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final ValueChanged<String> onSuccess;

  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.onSuccess,
  });

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final emailError = FormValidators.validateEmail(_emailCtrl.text.trim(), required: true);
    if (emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailError)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final error = await AuthService.instance.sendPasswordResetCode(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('authOtpSentSuccess')),
          backgroundColor: AppTheme.neonLime,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await AuthService.instance.resetPasswordWithCode(
      _emailCtrl.text.trim(),
      _otpCtrl.text.trim(),
      _newPasswordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      widget.onSuccess(_newPasswordCtrl.text.trim());
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(tr('authPasswordResetSuccess')),
          backgroundColor: AppTheme.neonLime,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset + MediaQuery.paddingOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('authResetPasswordTitle'),
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('authResetPasswordDesc'),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // Email
            CustomTextField(
              label: tr('authEmailLabel'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (v) => FormValidators.validateEmail(v, required: true),
            ),
            const SizedBox(height: 16),

            if (!_otpSent) ...[
              NeonButton(
                text: tr('authSendOtp'),
                isLoading: _isLoading,
                onPressed: _handleSendOtp,
              ),
            ] else ...[
              CustomTextField(
                label: tr('authOtpLabel'),
                hint: tr('auth_otp_hint'),
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.pin_outlined,
                validator: (v) {
                  if (v == null || v.trim().length < 6) {
                    return tr('auth_otp_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: tr('authNewPasswordLabel'),
                controller: _newPasswordCtrl,
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
                validator: (v) {
                  if (v == null || v.trim().length < 6) {
                    return tr('auth_password_min');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              NeonButton(
                text: tr('authResetButton'),
                isLoading: _isLoading,
                onPressed: _handleResetPassword,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
