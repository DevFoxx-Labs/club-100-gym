import 'package:flutter/material.dart';
import '../../core/services/client_notification_service.dart';
import '../../core/theme/client_theme.dart';
import '../feed/announcements_feed_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isRequesting = false;

  Future<void> _enableNotifications() async {
    setState(() => _isRequesting = true);

    try {
      await ClientNotificationService.instance.requestPermission();
      await ClientNotificationService.instance.setNotificationsEnabled(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: ClientTheme.neonLime, size: 20),
                SizedBox(width: 10),
                Text(
                  'Notifications enabled ✓',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: ClientTheme.darkSurface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: ClientTheme.neonLime),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementsFeedScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _skipToFeed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementsFeedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: ClientTheme.darkBackground,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + safeBottom),
          child: Column(
            children: [
              // Top Bar with Gym Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ClientTheme.neonLime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ClientTheme.neonLime.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_active_rounded, color: ClientTheme.neonLime, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'MEMBER PORTAL',
                          style: TextStyle(color: ClientTheme.neonLime, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _skipToFeed,
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(color: ClientTheme.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Center Logo & Branding Graphic
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: ClientTheme.neonLime.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: ClientTheme.neonLime.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: ClientTheme.neonLime.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  size: 48,
                  color: ClientTheme.neonLime,
                ),
              ),
              const SizedBox(height: 32),

              // Greeting & Slogan
              const Text(
                'Welcome to',
                style: TextStyle(
                  color: ClientTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: ClientTheme.textWhite,
                    letterSpacing: 0.5,
                  ),
                  children: [
                    TextSpan(text: 'THE ELITE '),
                    TextSpan(text: 'FITNESS ', style: TextStyle(color: ClientTheme.neonLime)),
                    TextSpan(text: 'GYM'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Enable notifications to receive gym announcements, class updates, holiday hours, and urgent alerts instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ClientTheme.textMuted,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Feature Highlights Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ClientTheme.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ClientTheme.darkBorder),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(Icons.fitness_center_rounded, 'Class schedules & trainer updates'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.access_time_filled_rounded, 'Holiday timings & maintenance notices'),
                    const SizedBox(height: 10),
                    _buildFeatureItem(Icons.verified_user_outlined, 'No account or login required'),
                  ],
                ),
              ),

              const Spacer(),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClientTheme.neonLime,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.notifications_active_rounded, size: 20),
                  label: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.2),
                  ),
                  onPressed: _isRequesting ? null : _enableNotifications,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You can adjust notification preferences anytime in settings.',
                style: TextStyle(color: ClientTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ClientTheme.neonLime.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: ClientTheme.neonLime, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: ClientTheme.textWhite, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
