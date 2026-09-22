import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/client_announcement_model.dart';

class ClientNotificationService {
  static final ClientNotificationService instance = ClientNotificationService._internal();
  factory ClientNotificationService() => instance;
  ClientNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  void Function(String announcementId)? onNotificationTapped;

  static const String channelId = 'elite_fitness_announcements';
  static const String channelName = 'Gym Announcements';
  static const String channelDescription = 'Updates, class timings, and alerts from The Elite Fitness Gym';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          onNotificationTapped?.call(response.payload!);
        }
      },
    );

    // Create high-importance Android notification channel
    final androidNotificationPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );
      await androidNotificationPlugin.createNotificationChannel(channel);
    }

    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      final isGranted = granted ?? false;
      if (isGranted) {
        await setNotificationsEnabled(true);
      }
      return isGranted;
    }
    await setNotificationsEnabled(true);
    return true;
  }

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (enabled) {
      await getDevicePushToken(); // Ensure token generated
    }
  }

  Future<String> getDevicePushToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('device_push_token');
    if (token == null || token.isEmpty) {
      final uniqueId = const Uuid().v4().substring(0, 12);
      token = 'ef_push_token_android_$uniqueId';
      await prefs.setString('device_push_token', token);
    }
    return token;
  }

  Future<void> showAnnouncementNotification(ClientAnnouncementModel item) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        item.message,
        contentTitle: '🔔 The Elite Fitness: ${item.displayTitle}',
        summaryText: 'Gym Announcement',
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      item.id.hashCode.abs() % 100000,
      '🔔 ${item.displayTitle}',
      item.message,
      notificationDetails,
      payload: item.id,
    );
  }

  Future<void> showTestNotification() async {
    await initialize();

    final testItem = ClientAnnouncementModel(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Zumba Class Tomorrow',
      message: "Don't miss our special Zumba Dance Fitness class tomorrow at 6:00 AM in the Aerobics Studio. Let's move, sweat and stay healthy together! 💃",
      category: 'class',
      createdAt: DateTime.now(),
    );

    await showAnnouncementNotification(testItem);
  }
}
