import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../core/security/biometric_service.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/navigation/main_navigation_screen.dart';

class BiometricSetupScreen extends StatefulWidget {
  final String gymName;
  final String ownerName;
  final String gymPhone;
  final String email;
  final String? website;
  final String address;
  final String city;
  final String currency;
  final String adminName;
  final String adminPhone;

  const BiometricSetupScreen({
    super.key,
    required this.gymName,
    required this.ownerName,
    required this.gymPhone,
    required this.email,
    this.website,
    required this.address,
    required this.city,
    required this.currency,
    required this.adminName,
    required this.adminPhone,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final _biometricService = BiometricService();
  bool _isAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final avail = await _biometricService.isBiometricAvailable();
    setState(() => _isAvailable = avail);
  }

  Future<void> _finishSetup({bool enableBiometric = false}) async {
    setState(() => _isLoading = true);

    try {
      if (enableBiometric) {
        final authenticated = await _biometricService.authenticate(
          localizedReason: 'Scan fingerprint/face to enable biometric login for Elite Fitness Gym',
        );
        if (!authenticated) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric authentication failed or cancelled.')),
            );
          }
          return;
        }
      }

      final repo = SettingsRepository();

      final gym = GymInfoModel(
        id: 'default',
        name: widget.gymName,
        ownerName: widget.ownerName,
        phone: widget.gymPhone,
        email: widget.email,
        website: widget.website,
        address: widget.address,
        city: widget.city,
        currency: widget.currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final admin = AdminModel(
        id: 'default',
        name: widget.adminName,
        phone: widget.adminPhone,
        isBiometricEnabled: enableBiometric,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveGymInfo(gym);
      await repo.saveAdminInfo(admin);

      AppStateService.instance.notifyGymInfoChanged();

      final security = SecurityService();
      await security.setSetupComplete(true);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 4 OF 4: BIOMETRICS'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + safeBottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48 - safeBottom).clamp(0, double.infinity),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.neonLime, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 48,
                            color: AppTheme.neonLime,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Biometric Login',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAvailable
                              ? 'Unlock Elite Fitness Gym quickly using Android fingerprint or device biometrics.'
                              : 'Biometrics are not supported on this device. You will use your MPIN to log in.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                        ),
                      ],
                    ),

                    Column(
                      children: [
                        if (_isAvailable) ...[
                          NeonButton(
                            text: 'Enable Fingerprint Login',
                            icon: Icons.fingerprint_rounded,
                            width: double.infinity,
                            isLoading: _isLoading,
                            onPressed: () => _finishSetup(enableBiometric: true),
                          ),
                          const SizedBox(height: 12),
                        ],
                        NeonButton(
                          text: _isAvailable ? 'Skip & Finish' : 'Finish Setup →',
                          isSecondary: true,
                          width: double.infinity,
                          isLoading: _isLoading,
                          onPressed: () => _finishSetup(enableBiometric: false),
                        ),
                      ],
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
}

