import 'package:flutter/foundation.dart';

/// AppStateEventType defines fine-grained event types for reactive app-wide updates.
enum AppStateEventType {
  gymInfoChanged,
  membersChanged,
  paymentsChanged,
  trainersChanged,
  packagesChanged,
  eventsChanged,
  notificationsChanged,
  all,
}

/// Global event coordinator and reactive state notifier for Club 100 Gym / Elite Fitness Gym.
/// Ensures all updates (new members, edited gym info, payments, trainers)
/// reflect instantly app-wide across Dashboard, Navigation Drawer, and List screens.
class AppStateService extends ChangeNotifier {
  AppStateService._internal();

  static final AppStateService _instance = AppStateService._internal();
  static AppStateService get instance => _instance;

  AppStateEventType? _lastEventType;
  AppStateEventType? get lastEventType => _lastEventType;

  DateTime _lastUpdatedAt = DateTime.now();
  DateTime get lastUpdatedAt => _lastUpdatedAt;

  void notifyGymInfoChanged() {
    _lastEventType = AppStateEventType.gymInfoChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyMembersChanged() {
    _lastEventType = AppStateEventType.membersChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyPaymentsChanged() {
    _lastEventType = AppStateEventType.paymentsChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyTrainersChanged() {
    _lastEventType = AppStateEventType.trainersChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyPackagesChanged() {
    _lastEventType = AppStateEventType.packagesChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyEventsChanged() {
    _lastEventType = AppStateEventType.eventsChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyNotificationsChanged() {
    _lastEventType = AppStateEventType.notificationsChanged;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }

  void notifyAll() {
    _lastEventType = AppStateEventType.all;
    _lastUpdatedAt = DateTime.now();
    notifyListeners();
  }
}

