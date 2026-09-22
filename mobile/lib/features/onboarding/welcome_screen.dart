import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/neon_button.dart';
import 'gym_setup_screen.dart';
import '../../shared/widgets/gym_logo_view.dart';

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

