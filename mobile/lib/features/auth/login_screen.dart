import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../core/security/biometric_service.dart';
import '../../data/repositories/settings_repository.dart';
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
  String _gymName = 'Elite Fitness Gym';
  String? _gymLogoPath;
  String? _gymPhone;
  String? _gymEmail;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    _loadGymAndBiometrics();
  }

  Future<void> _loadGymAndBiometrics() async {
    final repo = SettingsRepository();
    final gym = await repo.getGymInfo();
    final admin = await repo.getAdminInfo();

    if (mounted) {
      setState(() {
        _gymName = gym.name.isNotEmpty ? gym.name : 'The Elite Fitness Gym';
        _gymLogoPath = gym.logoPath;
        _gymPhone = gym.phone;
        _gymEmail = gym.email;
        _ownerName = gym.ownerName;
        _isBiometricEnabled = admin.isBiometricEnabled;
      });
    }

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
    if (_mpin.length >= 6) return;
    setState(() {
      _errorMsg = null;
      _mpin += digit;
    });

    if (_mpin.length == 6) {
      _verifyMpin();
    }
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
      if (mounted) {
        setState(() {
          _errorMsg = 'Incorrect MPIN. Please try again.';
          _mpin = '';
        });
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  void _showNeedHelpModal() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final safeBottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + safeBottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: AppTheme.neonLime, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Need Help Logging In?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textWhite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'If you forgot your MPIN, you can log in using registered device fingerprint biometrics or contact your gym administrator.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted.withValues(alpha: 0.9), height: 1.4),
              ),
              const SizedBox(height: 20),
              if (_ownerName != null && _ownerName!.isNotEmpty)
                _buildHelpItem(Icons.person_outline_rounded, 'Administrator', _ownerName!),
              if (_gymPhone != null && _gymPhone!.isNotEmpty)
                _buildHelpItem(Icons.phone_outlined, 'Contact Phone', _gymPhone!),
              if (_gymEmail != null && _gymEmail!.isNotEmpty)
                _buildHelpItem(Icons.email_outlined, 'Contact Email', _gymEmail!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonLime,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonLime, size: 18),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyButton(String key) {
    if (key == 'BIO') {
      return Material(
        color: const Color(0xFF161922).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _authenticateBiometric,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF262C3A), width: 1.2),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: AppTheme.neonLime,
              size: 28,
            ),
          ),
        ),
      );
    }

    if (key == 'DEL') {
      return Material(
        color: const Color(0xFF161922).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onBackspace,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF262C3A), width: 1.2),
            ),
            child: const Icon(
              Icons.backspace_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),
      );
    }

    return Material(
      color: const Color(0xFF161922).withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onKeyPress(key),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF262C3A), width: 1.2),
          ),
          child: Text(
            key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    // Split gym name for dual color styling
    final trimmedName = _gymName.toUpperCase().trim();
    final words = trimmedName.split(' ');
    String firstPart = trimmedName;
    String lastPart = '';
    if (words.length > 1) {
      lastPart = words.removeLast();
      firstPart = words.join(' ');
    }

    return Scaffold(
      backgroundColor: const Color(0xFF090D0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Photographic Gym Wallpaper
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF0F1412),
            ),
          ),

          // 2. Multi-stop Dark Gradient Scrim
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.72),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.85),
                  const Color(0xFF090D0A).withValues(alpha: 0.98),
                ],
                stops: const [0.0, 0.28, 0.65, 1.0],
              ),
            ),
          ),

          // 3. Ambient Emerald Vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.85, -0.3),
                radius: 1.3,
                colors: [
                  AppTheme.neonLime.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // 4. Foreground Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + safeBottom),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 24 - safeBottom).clamp(0, double.infinity),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header Area
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Bar Action: Need Help?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                //const SizedBox(width: 48),
                                // Centered Gym Logo
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.neonLime, width: 2),
                                      color: AppTheme.darkSurface,
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: AppTheme.neonLime, size: 36),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _showNeedHelpModal,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  child: const Text(
                                    'Need Help?',
                                    style: TextStyle(
                                      color: AppTheme.neonLime,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Slogan & Welcome Typography Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'WELCOME BACK TO',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textMuted,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$firstPart ',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w900,
                                                color: AppTheme.textWhite,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            if (lastPart.isNotEmpty)
                                              TextSpan(
                                                text: lastPart,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.neonLime,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Enter your MPIN to continue.',
                                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Slogan on Right with Neon Bar
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'STRONGER',
                                      style: TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const Text(
                                      'HEALTHIER',
                                      style: TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const Text(
                                      'HAPPIER YOU',
                                      style: TextStyle(
                                        color: AppTheme.textWhite,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 28,
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonLime,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // MPIN Indicator Rings
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final isFilled = index < _mpin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.symmetric(horizontal: 7),
                                  width: 15,
                                  height: 15,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled ? AppTheme.neonLime : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled ? AppTheme.neonLime : Colors.white.withValues(alpha: 0.35),
                                      width: 1.5,
                                    ),
                                    boxShadow: isFilled
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.neonLime.withValues(alpha: 0.6),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                );
                              }),
                            ),

                            if (_errorMsg != null) ...[
                              const SizedBox(height: 10),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusOverdue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.statusOverdue.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    _errorMsg!,
                                    style: const TextStyle(
                                      color: AppTheme.statusOverdue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Keypad, Primary Button & Secondary Footer
                        Column(
                          children: [
                            // 3x4 Custom Card Keypad
                            for (var row in [
                              ['1', '2', '3'],
                              ['4', '5', '6'],
                              ['7', '8', '9'],
                              ['BIO', '0', 'DEL'],
                            ])
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: row.map((key) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: _buildKeyButton(key),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Primary Action: Neon Lime Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonLime,
                                  foregroundColor: Colors.black,
                                  elevation: 6,
                                  shadowColor: AppTheme.neonLime.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _mpin.length >= 4 ? _verifyMpin : null,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // "OR" Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textMuted.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // "Use Fingerprint" & "Forgot MPIN?"
                            if (_isBiometricEnabled)
                              TextButton.icon(
                                onPressed: _authenticateBiometric,
                                icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.neonLime, size: 20),
                                label: const Text(
                                  'Use Fingerprint',
                                  style: TextStyle(
                                    color: AppTheme.neonLime,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            TextButton(
                              onPressed: _showNeedHelpModal,
                              child: Text(
                                'Forgot MPIN?',
                                style: TextStyle(
                                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Footer Motivational Slogan
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 1.5,
                                  color: AppTheme.neonLime,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'FITNESS TODAY  A STRONGER TOMORROW',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 20,
                                  height: 1.5,
                                  color: AppTheme.neonLime,
                                ),
                              ],
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
        ],
      ),
    );
  }
}


