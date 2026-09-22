import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client_announcement_model.dart';
import 'client_notification_service.dart';

class ClientAnnouncementService {
  static final ClientAnnouncementService instance = ClientAnnouncementService._internal();
  factory ClientAnnouncementService() => instance;
  ClientAnnouncementService._internal();

  List<ClientAnnouncementModel> _announcements = [];
  final Set<String> _readIds = {};
  final Set<String> _notifiedIds = {};

  List<ClientAnnouncementModel> get announcements => List.unmodifiable(_announcements);

  Future<void> initialize() async {
    await _loadReadState();
    await fetchAnnouncements(triggerNotificationsForNew: false);
  }

  Future<void> _loadReadState() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('client_read_announcement_ids') ?? [];
    _readIds.clear();
    _readIds.addAll(readList);

    final notifiedList = prefs.getStringList('client_notified_announcement_ids') ?? [];
    _notifiedIds.clear();
    _notifiedIds.addAll(notifiedList);
  }

  Future<void> _saveReadState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('client_read_announcement_ids', _readIds.toList());
  }

  Future<void> _saveNotifiedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('client_notified_announcement_ids', _notifiedIds.toList());
  }

  Future<List<ClientAnnouncementModel>> fetchAnnouncements({bool triggerNotificationsForNew = true}) async {
    List<ClientAnnouncementModel> loaded = [];

    // 1. Check shared export file from Admin App (e.g. /sdcard/Download or app documents)
    try {
      final sharedFile = File('/sdcard/Download/elite_fitness_broadcasts.json');
      if (await sharedFile.exists()) {
        final content = await sharedFile.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        loaded = decoded
            .map((item) => ClientAnnouncementModel.fromMap(
                  item as Map<String, dynamic>,
                  isRead: _readIds.contains(item['id']?.toString()),
                ))
            .toList();
      }
    } catch (_) {}

    if (loaded.isEmpty) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final localFile = File('${appDocDir.path}/elite_fitness_broadcasts.json');
        if (await localFile.exists()) {
          final content = await localFile.readAsString();
          final List<dynamic> decoded = jsonDecode(content);
          loaded = decoded
              .map((item) => ClientAnnouncementModel.fromMap(
                    item as Map<String, dynamic>,
                    isRead: _readIds.contains(item['id']?.toString()),
                  ))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Fallback to realistic seeds matching The Elite Fitness Gym
    if (loaded.isEmpty) {
      loaded = _getDefaultSeeds();
    }

    // Sort: Pinned first, then newest first
    loaded.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    // 3. Trigger local notifications for newly discovered announcements
    if (triggerNotificationsForNew && loaded.isNotEmpty) {
      for (final item in loaded) {
        if (!_notifiedIds.contains(item.id)) {
          _notifiedIds.add(item.id);
          try {
            await ClientNotificationService.instance.showAnnouncementNotification(item);
          } catch (_) {}
        }
      }
      await _saveNotifiedState();
    } else {
      // Record initial IDs so we don't spam notifications on first open
      for (final item in loaded) {
        _notifiedIds.add(item.id);
      }
      await _saveNotifiedState();
    }

    _announcements = loaded;
    return _announcements;
  }

  List<ClientAnnouncementModel> _getDefaultSeeds() {
    final now = DateTime.now();
    return [
      ClientAnnouncementModel(
        id: 'seed-zumba-1',
        title: 'Zumba Class Tomorrow',
        message: "Don't miss our special Zumba Dance Fitness class tomorrow at 6:00 AM in the Aerobics Studio. Let's move, sweat and stay healthy together! 💃",
        category: 'class',
        isPinned: true,
        isImportant: true,
        createdAt: now.subtract(const Duration(hours: 2, minutes: 23)),
        isRead: _readIds.contains('seed-zumba-1'),
      ),
      ClientAnnouncementModel(
        id: 'seed-equip-2',
        title: 'New Equipment Arrived',
        message: "We've added new strength training equipment to the weights section. Come check it out!",
        category: 'equipment',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 2, hours: 4)),
        isRead: _readIds.contains('seed-equip-2'),
      ),
      ClientAnnouncementModel(
        id: 'seed-holiday-3',
        title: 'Holiday Hours',
        message: 'The gym will be open from 6:00 AM – 2:00 PM this Sunday due to the public holiday. Plan your workouts accordingly.',
        category: 'hours',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 4, hours: 9)),
        isRead: _readIds.contains('seed-holiday-3'),
      ),
      ClientAnnouncementModel(
        id: 'seed-apprec-4',
        title: 'Member Appreciation Week',
        message: 'Thank you for being part of The Elite Fitness Gym! Enjoy special offers and events all week long. 💚',
        category: 'event',
        isPinned: false,
        createdAt: now.subtract(const Duration(days: 7, hours: 7)),
        isRead: _readIds.contains('seed-apprec-4'),
      ),
      ClientAnnouncementModel(
        id: 'seed-maint-5',
        title: 'Maintenance Update',
        message: 'The sauna will be under maintenance on 12 Sep 2026. We apologize for the inconvenience.',
        category: 'maintenance',
        isPinned: false,
        isImportant: true,
        createdAt: now.subtract(const Duration(days: 12, hours: 14)),
        isRead: _readIds.contains('seed-maint-5'),
      ),
    ];
  }

  Future<void> markAsRead(String id) async {
    _readIds.add(id);
    await _saveReadState();

    final index = _announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      _announcements[index] = _announcements[index].copyWith(isRead: true);
    }
  }

  Future<void> markAllAsRead() async {
    for (final a in _announcements) {
      _readIds.add(a.id);
    }
    await _saveReadState();

    _announcements = _announcements.map((a) => a.copyWith(isRead: true)).toList();
  }

  int getUnreadCount() {
    return _announcements.where((a) => !a.isRead).length;
  }
}
