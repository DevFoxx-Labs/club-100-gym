import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../core/security/biometric_service.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/navigation/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _securityService = SecurityService();
  final _biometricService = BiometricService();
  String _mpin = '';
  String? _errorMsg;
  bool _isBiometricEnabled = false;
  String _gymName = 'Club 100 The Gym';

  @override
  void initState() {
    super.initState();
    _loadGymAndBiometrics();
  }

  Future<void> _loadGymAndBiometrics() async {
    final repo = SettingsRepository();
    final gym = await repo.getGymInfo();
    final admin = await repo.getAdminInfo();

    setState(() {
      _gymName = gym.name;
      _isBiometricEnabled = admin.isBiometricEnabled;
    });

    if (_isBiometricEnabled) {
      _authenticateBiometric();
    }
  }

  Future<void> _authenticateBiometric() async {
    final authenticated = await _biometricService.authenticate(
      localizedReason: 'Scan fingerprint to unlock $_gymName',
    );
    if (authenticated && mounted) {
      _navigateToDashboard();
    }
  }

  void _onKeyPress(String digit) {
    setState(() {
      _errorMsg = null;
      if (_mpin.length < 6) _mpin += digit;
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMsg = null;
      if (_mpin.isNotEmpty) _mpin = _mpin.substring(0, _mpin.length - 1);
    });
  }

  Future<void> _verifyMpin() async {
    final valid = await _securityService.verifyMPIN(_mpin);
    if (valid) {
      _navigateToDashboard();
    } else {
      setState(() {
        _errorMsg = 'Incorrect MPIN. Please try again.';
        _mpin = '';
      });
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gym Logo & Title
              Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonLime.withValues(alpha: 0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 38,
                      color: AppTheme.darkBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _gymName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textWhite,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome Back! Enter your MPIN to continue.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 24),

                  // MPIN Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < _mpin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppTheme.neonLime : AppTheme.darkBackground,
                          border: Border.all(
                            color: isFilled ? AppTheme.neonLime : AppTheme.darkBorder,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(color: AppTheme.statusOverdue, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              // Custom Numeric Keypad Grid
              Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    [_isBiometricEnabled ? 'BIO' : '', '0', 'DEL']
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((key) {
                          if (key == '') return const SizedBox(width: 70, height: 54);
                          if (key == 'BIO') {
                            return IconButton(
                              onPressed: _authenticateBiometric,
                              icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.neonLime),
                              iconSize: 32,
                            );
                          }
                          if (key == 'DEL') {
                            return IconButton(
                              onPressed: _onBackspace,
                              icon: const Icon(Icons.backspace_outlined, color: AppTheme.textWhite),
                              iconSize: 24,
                            );
                          }
                          return InkWell(
                            onTap: () => _onKeyPress(key),
                            borderRadius: BorderRadius.circular(35),
                            child: Container(
                              width: 70,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppTheme.darkBorder),
                              ),
                              child: Text(
                                key,
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  NeonButton(
                    text: 'Login →',
                    width: double.infinity,
                    onPressed: _mpin.length >= 4 ? _verifyMpin : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

