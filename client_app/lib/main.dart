import 'package:flutter/material.dart';
import 'core/services/client_notification_service.dart';
import 'core/theme/client_theme.dart';
import 'features/feed/announcements_feed_screen.dart';
import 'features/onboarding/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await ClientNotificationService.instance.initialize();
  final isEnabled = await ClientNotificationService.instance.isNotificationsEnabled();

  runApp(EliteFitnessClientApp(startWithFeed: isEnabled));
}

class EliteFitnessClientApp extends StatelessWidget {
  final bool startWithFeed;

  const EliteFitnessClientApp({super.key, required this.startWithFeed});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elite Fitness Notifications',
      debugShowCheckedModeBanner: false,
      theme: ClientTheme.darkTheme,
      home: startWithFeed ? const AnnouncementsFeedScreen() : const WelcomeScreen(),
    );
  }
}
