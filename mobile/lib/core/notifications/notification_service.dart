import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/event_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../services/app_state_service.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Configures tz.local to match the device's system timezone and offset.
  static void configureLocalTimeZone() {
    tz.initializeTimeZones();
    try {
      final now = DateTime.now();
      final offsetMs = now.timeZoneOffset.inMilliseconds;
      final timeZoneName = now.timeZoneName;

      // 1. Direct match by name
      if (tz.timeZoneDatabase.locations.containsKey(timeZoneName)) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        return;
      }

      // 2. Known common regions matching current offset
      const preferred = [
        'Asia/Kolkata', 'Asia/Calcutta', 'UTC', 'America/New_York',
        'America/Los_Angeles', 'America/Chicago', 'Europe/London',
        'Europe/Paris', 'Asia/Dubai', 'Asia/Singapore', 'Asia/Tokyo'
      ];
      for (final p in preferred) {
        if (tz.timeZoneDatabase.locations.containsKey(p)) {
          final loc = tz.getLocation(p);
          if (loc.currentTimeZone.offset == offsetMs) {
            tz.setLocalLocation(loc);
            return;
          }
        }
      }

      // 3. Fallback: Any location matching device offset
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offsetMs) {
          tz.setLocalLocation(loc);
          return;
        }
      }
    } catch (e) {
      debugPrint('configureLocalTimeZone fallback: $e');
    }
  }

  Future<void> init() async {
    configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
    final androidDetails = AndroidNotificationDetails(
      'gym_reminders_channel',
      'Fee & Membership Reminders',
      channelDescription: 'Local notifications for member fee dues and membership expiries',
      importance: Importance.high,
      priority: Priority.high,
      color: AppTheme.neonLime,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Persist to notification repository so it appears on Notifications Screen
    try {
      await NotificationRepository().insertNotification(
        NotificationItemModel(
          id: const Uuid().v4(),
          type: 'ALERT',
          title: title,
          message: body,
          scheduledAt: DateTime.now(),
          triggeredAt: DateTime.now(),
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );
      AppStateService.instance.notifyNotificationsChanged();
    } catch (_) {}
  }

  /// Safely schedules a zoned notification with fallback to inexact alarms if exact is disallowed.
  Future<void> _safeZonedSchedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationDetails notificationDetails,
    String? payload,
  }) async {
    final now = DateTime.now();
    if (scheduledDate.isBefore(now)) return;

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Exact alarm scheduling failed, trying inexact: $e');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('Inexact alarm scheduling failed: $e2');
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'gym_reminders_channel',
      'Fee & Membership Reminders',
      channelDescription: 'Local notifications for member fee dues and membership expiries',
      importance: Importance.high,
      priority: Priority.high,
      color: AppTheme.neonLime,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Schedules multi-tier reminder notifications for an upcoming event/class.
  /// Tier 1: 30 minutes before start
  /// Tier 2: 15 minutes before start (or immediately if starting in <15m)
  /// Tier 3: Exactly at event start time
  Future<void> scheduleEventNotification(EventModel event) async {
    final start = DateTime.tryParse(event.startTime);
    if (start == null) return;

    final now = DateTime.now();
    // If event has already started more than 15 minutes ago, skip
    if (now.difference(start) > const Duration(minutes: 15)) return;

    final settings = await SettingsRepository().getNotificationSettings();
    if (settings['eventReminders'] == false) return;

    final bool alert30m = settings['event30m'] ?? true;
    final bool alert15m = settings['event15m'] ?? true;
    final bool alertAtStart = settings['eventAtStart'] ?? true;

    final int baseId = event.id.hashCode.abs() % 100000 + 10000;
    final timeStr = DateFormat('hh:mm a').format(start);
    final locationStr = (event.location != null && event.location!.trim().isNotEmpty)
        ? ' • ${event.location!.trim()}'
        : '';

    final eventAndroidDetails = AndroidNotificationDetails(
      'gym_events_channel',
      'Gym Events & Classes',
      channelDescription: 'Reminders and notifications for scheduled gym events and classes',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      color: AppTheme.neonLime,
    );

    final eventNotificationDetails = NotificationDetails(
      android: eventAndroidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // 1. T-30 minutes reminder (ID: baseId)
    if (alert30m) {
      final notify30m = start.subtract(const Duration(minutes: 30));
      if (notify30m.isAfter(now)) {
        await _safeZonedSchedule(
          id: baseId,
          title: 'Upcoming Gym Event: ${event.title}',
          body: 'Starts in 30 minutes at $timeStr$locationStr. Get ready!',
          scheduledDate: notify30m,
          notificationDetails: eventNotificationDetails,
          payload: 'event:${event.id}',
        );
      }
    }

    // 2. T-15 minutes reminder (ID: baseId + 1)
    if (alert15m) {
      final notify15m = start.subtract(const Duration(minutes: 15));
      if (notify15m.isAfter(now)) {
        await _safeZonedSchedule(
          id: baseId + 1,
          title: 'Gym Event Starting Soon: ${event.title}',
          body: 'Starts in 15 minutes at $timeStr$locationStr!',
          scheduledDate: notify15m,
          notificationDetails: eventNotificationDetails,
          payload: 'event:${event.id}',
        );
      } else if (start.isAfter(now)) {
        // Event starts in <= 15 minutes! Send an immediate alert so user doesn't miss it!
        final remainingMins = start.difference(now).inMinutes;
        final countdownText = remainingMins <= 1 ? 'in 1 minute' : 'in $remainingMins minutes';
        await _safeZonedSchedule(
          id: baseId + 1,
          title: 'Gym Event Starting Soon: ${event.title}',
          body: 'Starts $countdownText at $timeStr$locationStr!',
          scheduledDate: now.add(const Duration(seconds: 4)),
          notificationDetails: eventNotificationDetails,
          payload: 'event:${event.id}',
        );
      }
    }

    // 3. At Event Start Time reminder (ID: baseId + 2)
    if (alertAtStart) {
      if (start.isAfter(now)) {
        await _safeZonedSchedule(
          id: baseId + 2,
          title: 'Gym Event Starting Now: ${event.title}',
          body: '${event.title} is starting now$locationStr. Join in!',
          scheduledDate: start,
          notificationDetails: eventNotificationDetails,
          payload: 'event:${event.id}',
        );
      } else if (now.difference(start) < const Duration(minutes: 10)) {
        // Event started in last few minutes: notify user that it's live
        await _safeZonedSchedule(
          id: baseId + 2,
          title: 'Gym Event In Progress: ${event.title}',
          body: '${event.title} is now in progress$locationStr.',
          scheduledDate: now.add(const Duration(seconds: 3)),
          notificationDetails: eventNotificationDetails,
          payload: 'event:${event.id}',
        );
      }
    }

    // Persist event notification entry so it is visible in the in-app notification screen.
    // Only write (and notify listeners) if the content actually changed: this is re-run on
    // every event-list reload, and an unconditional write here would re-fire
    // notifyNotificationsChanged() every time, which re-triggers this very reload — an
    // infinite refresh loop that shows up as a flickering screen.
    try {
      final notificationRepo = NotificationRepository();
      final id = 'event_${event.id}';
      final message = 'Starts at $timeStr$locationStr. Don\'t miss out!';
      final existing = await notificationRepo.getById(id);
      final triggeredAt = now.isAfter(start) ? start : null;
      final unchanged = existing != null &&
          existing.message == message &&
          existing.scheduledAt == start &&
          existing.triggeredAt == triggeredAt;
      if (!unchanged) {
        await notificationRepo.insertNotification(
          NotificationItemModel(
            id: id,
            memberId: event.trainerId,
            type: 'EVENT',
            title: 'Gym Event: ${event.title}',
            message: message,
            scheduledAt: start,
            triggeredAt: triggeredAt,
            isRead: existing?.isRead ?? false,
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
      }
    } catch (_) {}
  }

  /// Cancels all scheduled notifications for the given event ID.
  Future<void> cancelEventNotification(String eventId) async {
    final int baseId = eventId.hashCode.abs() % 100000 + 10000;
    await cancelNotification(baseId);
    await cancelNotification(baseId + 1);
    await cancelNotification(baseId + 2);
    try {
      await NotificationRepository().deleteNotification('event_$eventId');
      AppStateService.instance.notifyNotificationsChanged();
    } catch (_) {}
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
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('cancelNotification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAllNotifications error: $e');
    }
  }
}
