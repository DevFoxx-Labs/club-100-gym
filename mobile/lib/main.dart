import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/security/security_service.dart';
import 'core/services/app_state_service.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_scheduler.dart';
import 'data/repositories/settings_repository.dart';
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

  // Initialize notifications and run automated scans (non-fatal)
  try {
    await NotificationService().init();
    NotificationService().syncAllUpcomingEventNotifications();
    ReminderScheduler().runDailyScan();
  } catch (e, stackTrace) {
    debugPrint('NotificationService init failed: $e\n$stackTrace');
  }

  // Check if first setup is complete
  final security = SecurityService();
  final isComplete = await security.isSetupComplete();

  // Apply the admin's saved favorite highlight color, if any, before first paint
  try {
    final savedAccentColor = await SettingsRepository().getAccentColor();
    if (savedAccentColor != null) {
      AppTheme.setAccentColor(savedAccentColor);
    }
  } catch (e) {
    debugPrint('Failed to load saved accent color: $e');
  }

  runApp(Club100GymApp(isSetupComplete: isComplete));
}

class Club100GymApp extends StatefulWidget {
  final bool isSetupComplete;

  const Club100GymApp({super.key, required this.isSetupComplete});

  @override
  State<Club100GymApp> createState() => _Club100GymAppState();
}

class _Club100GymAppState extends State<Club100GymApp> {
  @override
  void initState() {
    super.initState();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    // Rebuilding the root widget cascades a fresh build down the whole tree,
    // so every screen picks up the newly selected AppTheme.neonLime immediately.
    if (AppStateService.instance.lastEventType == AppStateEventType.themeChanged && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elite Fitness Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: widget.isSetupComplete ? const LoginScreen() : const WelcomeScreen(),
    );
  }
}

typedef EliteFitnessGymApp = Club100GymApp;

