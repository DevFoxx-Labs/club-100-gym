import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/security/security_service.dart';
import 'core/notifications/notification_service.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkSurface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notifications
  await NotificationService().init();

  // Check if first setup is complete
  final security = SecurityService();
  final isComplete = await security.isSetupComplete();

  runApp(Club100GymApp(isSetupComplete: isComplete));
}

class Club100GymApp extends StatelessWidget {
  final bool isSetupComplete;

  const Club100GymApp({super.key, required this.isSetupComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Club 100 The Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isSetupComplete ? const LoginScreen() : const WelcomeScreen(),
    );
  }
}

