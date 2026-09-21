import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/event_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/settings_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click navigation
      },
    );

    // Request permissions for Android 13+ (POST_NOTIFICATIONS)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gym_reminders_channel',
      'Fee & Membership Reminders',
      channelDescription: 'Local notifications for member fee dues and membership expiries',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFB5F63D),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gym_reminders_channel',
      'Fee & Membership Reminders',
      channelDescription: 'Local notifications for member fee dues and membership expiries',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD4FF00),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedules a reminder notification for an upcoming event/class.
  Future<void> scheduleEventNotification(EventModel event) async {
    final start = DateTime.tryParse(event.startTime);
    if (start == null) return;

    final now = DateTime.now();
    if (start.isBefore(now)) return; // Event already started or ended

    final settings = await SettingsRepository().getNotificationSettings();
    if (settings['eventReminders'] == false) return;

    // Calculate alert time: default 30 minutes before, or earlier if within 30 min window
    final bool alert30m = settings['event30m'] ?? true;
    DateTime notifyTime = alert30m ? start.subtract(const Duration(minutes: 30)) : start;
    if (notifyTime.isBefore(now)) {
      // If event starts in less than 30 mins, alert in 10 seconds so user gets notified
      notifyTime = now.add(const Duration(seconds: 10));
    }

    final int notifId = event.id.hashCode.abs() % 100000 + 10000;
    final timeStr = DateFormat('hh:mm a').format(start);
    final locationStr = (event.location != null && event.location!.trim().isNotEmpty)
        ? ' • ${event.location!.trim()}'
        : '';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'gym_events_channel',
      'Gym Events & Classes',
      channelDescription: 'Reminders and notifications for scheduled gym events and classes',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD4FF00),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      notifId,
      'Gym Event: ${event.title}',
      'Starts at $timeStr$locationStr. Don\'t miss out!',
      tz.TZDateTime.from(notifyTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'event:${event.id}',
    );
  }

  /// Cancels any scheduled notification for the given event ID.
  Future<void> cancelEventNotification(String eventId) async {
    final int notifId = eventId.hashCode.abs() % 100000 + 10000;
    await cancelNotification(notifId);
  }

  /// Synchronizes scheduled notifications for all upcoming gym events.
  Future<void> syncAllUpcomingEventNotifications() async {
    try {
      final events = await EventRepository().getUpcomingEvents(daysAhead: 14);
      for (final event in events) {
        await scheduleEventNotification(event);
      }
    } catch (e) {
      debugPrint('syncAllUpcomingEventNotifications error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
