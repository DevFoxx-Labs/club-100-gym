import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/event_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../events/event_form_screen.dart';
import '../members/member_profile_screen.dart';
import '../settings/notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _memberRepo = MemberRepository();
  final _eventRepo = EventRepository();
  final _notificationRepo = NotificationRepository();

  List<Map<String, dynamic>> _allNotifications = [];
  String _selectedCategory = 'All'; // 'All', 'Events', 'Fee Dues', 'Overdue'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    AppStateService.instance.addListener(_onAppStateChanged);
    // Background sync scheduled alerts
    NotificationService().syncAllUpcomingEventNotifications();
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadNotifications(showSpinner: false);
    }
  }

  Future<void> _loadNotifications({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }

    final List<Map<String, dynamic>> items = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Load Fee & Membership Reminders
    try {
      final members = await _memberRepo.getMembers();
      for (var m in members) {
        final ms = await _memberRepo.getLatestMembership(m.id);
        if (ms != null) {
          final endDate = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
          final diffDays = endDate.difference(today).inDays;

          if (diffDays < 0) {
            items.add({
              'id': 'fee_overdue_${m.id}',
              'category': 'Overdue',
              'type': 'OVERDUE',
              'member': m,
              'title': 'Fee Overdue: ${m.name}',
              'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} is overdue by ${diffDays.abs()} days.',
              'date': endDate,
              'priority': 1,
              'isRead': false,
            });
          } else if (diffDays == 0) {
            items.add({
              'id': 'fee_due_${m.id}',
              'category': 'Fee Dues',
              'type': 'DUE_TODAY',
              'member': m,
              'title': 'Fee Due Today: ${m.name}',
              'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} expires and is due today.',
              'date': endDate,
              'priority': 2,
              'isRead': false,
            });
          } else if (diffDays <= 7) {
            items.add({
              'id': 'fee_soon_${m.id}',
              'category': 'Fee Dues',
              'type': 'DUE_SOON',
              'member': m,
              'title': 'Fee Due Soon: ${m.name}',
              'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} is due in $diffDays days.',
              'date': endDate,
              'priority': 4,
              'isRead': false,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading member fee reminders: $e');
    }

    // 2. Load Gym Events & Classes Reminders
    try {
      final events = await _eventRepo.getAllEvents();
      final timeFormat = DateFormat('hh:mm a');
      final dateFormat = DateFormat('EEE, dd MMM');

      for (var event in events) {
        final start = DateTime.tryParse(event.startTime);
        final end = DateTime.tryParse(event.endTime);
        if (start == null || end == null) continue;

        final isToday = start.year == now.year && start.month == now.month && start.day == now.day;
        final isLive = start.isBefore(now) && end.isAfter(now);
        final isEndedToday = isToday && end.isBefore(now);
        final isUpcoming = start.isAfter(now) && start.difference(now).inDays <= 30;
        final isRecent = !isToday && start.isBefore(now) && now.difference(start).inDays <= 3;

        // Keep all today's events (even if earlier today), upcoming within 30 days, or recent within 3 days
        if (!isToday && !isUpcoming && !isRecent) continue;

        final locationStr = (event.location != null && event.location!.trim().isNotEmpty)
            ? ' • ${event.location!.trim()}'
            : '';

        String title;
        String timeDisplay;
        String badge;
        int priority;

        if (isLive) {
          title = 'Live Now: ${event.title}';
          timeDisplay = 'Started at ${timeFormat.format(start)} (Ends ${timeFormat.format(end)})$locationStr';
          badge = 'LIVE';
          priority = 0; // Highest priority
        } else if (isToday) {
          if (isEndedToday) {
            title = 'Gym Event: ${event.title}';
            timeDisplay = 'Today at ${timeFormat.format(start)} - ${timeFormat.format(end)}$locationStr';
            badge = 'TODAY';
            priority = 2;
          } else {
            title = 'Event Today: ${event.title}';
            timeDisplay = 'Today at ${timeFormat.format(start)} - ${timeFormat.format(end)}$locationStr';
            badge = 'TODAY';
            priority = 1;
          }
        } else if (isUpcoming) {
          title = 'Upcoming Event: ${event.title}';
          timeDisplay = '${dateFormat.format(start)} at ${timeFormat.format(start)}$locationStr';
          badge = 'UPCOMING';
          priority = 3;
        } else {
          title = 'Recent Event: ${event.title}';
          timeDisplay = '${dateFormat.format(start)} at ${timeFormat.format(start)}$locationStr';
          badge = 'RECENT';
          priority = 5;
        }

        items.add({
          'id': 'event_${event.id}',
          'category': 'Events',
          'type': isLive ? 'EVENT_LIVE' : (isToday ? 'EVENT_TODAY' : 'EVENT_UPCOMING'),
          'event': event,
          'title': title,
          'body': timeDisplay,
          'badge': badge,
          'color': event.colorValue != null ? Color(event.colorValue!) : AppTheme.neonLime,
          'date': start,
          'priority': priority,
          'isRead': isEndedToday || isRecent,
        });
      }
    } catch (e) {
      debugPrint('Error loading event notifications: $e');
    }

    // 3. Load Logged / Push Notifications from NotificationRepository
    try {
      final persistedNotifs = await _notificationRepo.getAllNotifications(limit: 50);
      for (var p in persistedNotifs) {
        // Avoid duplicate items if event or fee alert already added
        if (items.any((i) => i['id'] == p.id)) continue;

        String cat = 'All';
        Color color = AppTheme.neonLime;
        if (p.type.contains('EVENT')) {
          cat = 'Events';
          color = AppTheme.neonLime;
        } else if (p.type.contains('OVERDUE')) {
          cat = 'Overdue';
          color = AppTheme.statusOverdue;
        } else {
          cat = 'Fee Dues';
          color = AppTheme.statusDueSoon;
        }

        final date = p.triggeredAt ?? p.scheduledAt;
        final timeStr = _formatNotificationDate(date);

        items.add({
          'id': p.id,
          'category': cat,
          'type': p.type,
          'title': p.title,
          'body': '${p.message} ($timeStr)',
          'badge': p.type.replaceAll('_', ' '),
          'color': color,
          'date': date,
          'priority': p.isRead ? 4 : 1,
          'isRead': p.isRead,
          'persisted': p,
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted notifications: $e');
    }

    // Sort by priority, then date descending (newest first)
    items.sort((a, b) {
      final pA = a['priority'] as int? ?? 5;
      final pB = b['priority'] as int? ?? 5;
      if (pA != pB) return pA.compareTo(pB);
      final dateA = a['date'] as DateTime? ?? now;
      final dateB = b['date'] as DateTime? ?? now;
      return dateB.compareTo(dateA);
    });

    if (mounted) {
      setState(() {
        _allNotifications = items;
        _isLoading = false;
      });
    }
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && date.day == now.day) return DateFormat('hh:mm a').format(date);
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'All') return _allNotifications;
    if (_selectedCategory == 'Events') {
      return _allNotifications.where((i) => i['category'] == 'Events').toList();
    }
    if (_selectedCategory == 'Fee Dues') {
      return _allNotifications.where((i) => i['category'] == 'Fee Dues').toList();
    }
    if (_selectedCategory == 'Overdue') {
      return _allNotifications.where((i) => i['category'] == 'Overdue').toList();
    }
    return _allNotifications;
  }

  int _countFor(String cat) {
    if (cat == 'All') return _allNotifications.length;
    if (cat == 'Events') return _allNotifications.where((i) => i['category'] == 'Events').length;
    if (cat == 'Fee Dues') return _allNotifications.where((i) => i['category'] == 'Fee Dues').length;
    if (cat == 'Overdue') return _allNotifications.where((i) => i['category'] == 'Overdue').length;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATIONS & ALERTS'),
        actions: [
          IconButton(
            tooltip: 'Add Gym Event',
            icon: const Icon(Icons.add_alert_rounded, color: AppTheme.neonLime),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventFormScreen()),
              );
              if (res == true) _loadNotifications();
            },
          ),
          IconButton(
            tooltip: 'Reminder Settings',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textMuted),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Categories Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.darkBackground,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Events', 'Fee Dues', 'Overdue'].map((category) {
                    final isSelected = _selectedCategory == category;
                    final count = _countFor(category);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Text(
                          '$category ($count)',
                          style: TextStyle(
                            color: isSelected ? Colors.black : AppTheme.textWhite,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                        backgroundColor: AppTheme.darkSurface,
                        selectedColor: AppTheme.neonLime,
                        side: BorderSide(
                          color: isSelected ? AppTheme.neonLime : AppTheme.darkBorder,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : _filteredItems.isEmpty
                      ? RefreshIndicator(
                          color: AppTheme.neonLime,
                          onRefresh: () => _loadNotifications(showSpinner: false),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.notifications_none_rounded, size: 54, color: AppTheme.textMuted),
                                    const SizedBox(height: 14),
                                    const Text(
                                      "You're all caught up!",
                                      style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedCategory == 'All'
                                          ? 'No pending fee dues or scheduled gym events.'
                                          : 'No notifications in "$_selectedCategory".',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.neonLime,
                          onRefresh: () => _loadNotifications(showSpinner: false),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              if (item['persisted'] != null) {
                                return _buildPersistedTile(item);
                              } else if (item['category'] == 'Events') {
                                return _buildEventTile(item);
                              } else {
                                return _buildFeeTile(item);
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(Map<String, dynamic> item) {
    final event = item['event'] as EventModel;
    final badge = item['badge'] as String;
    final eventColor = item['color'] as Color? ?? AppTheme.neonLime;
    final isLive = badge == 'LIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
          );
          if (res == true) _loadNotifications();
        },
        leading: CircleAvatar(
          backgroundColor: eventColor.withValues(alpha: 0.18),
          child: Icon(
            isLive ? Icons.sensors_rounded : Icons.event_available_rounded,
            color: eventColor,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isLive ? const Color(0xFF00E676) : eventColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isLive ? const Color(0xFF00E676) : eventColor).withValues(alpha: 0.6),
                  width: 0.8,
                ),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: isLive ? const Color(0xFF00E676) : eventColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppTheme.neonLime, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item['body'],
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (event.description != null && event.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                event.description!.trim(),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildFeeTile(Map<String, dynamic> item) {
    final member = item['member'] as MemberModel;
    final isOverdue = item['type'] == 'OVERDUE';
    final isDueToday = item['type'] == 'DUE_TODAY';

    final Color statusColor = isOverdue
        ? AppTheme.statusOverdue
        : (isDueToday ? Colors.amber : AppTheme.statusDueSoon);

    final String badgeText = isOverdue
        ? 'OVERDUE'
        : (isDueToday ? 'DUE TODAY' : 'DUE SOON');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: member.id)),
          );
        },
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(
            isOverdue ? Icons.warning_rounded : Icons.notifications_active_rounded,
            color: statusColor,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['title'],
                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item['body'],
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildPersistedTile(Map<String, dynamic> item) {
    final n = item['persisted'] as NotificationItemModel;
    final color = item['color'] as Color? ?? AppTheme.neonLime;
    final isUnread = !(item['isRead'] as bool? ?? true);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () async {
          await _notificationRepo.markAsRead(n.id);
          setState(() => item['isRead'] = true);

          if (n.id.startsWith('event_')) {
            final eventId = n.id.replaceFirst('event_', '');
            final event = await _eventRepo.getEventById(eventId);
            if (event != null && mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
              );
              _loadNotifications();
            }
          } else if (n.memberId != null && n.memberId!.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: n.memberId!)),
            );
          }
        },
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(
                n.type.contains('EVENT') ? Icons.event_note_rounded : Icons.notifications_active_rounded,
                color: color,
                size: 22,
              ),
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4FF00),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                n.title,
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                item['badge'] ?? 'ALERT',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item['body'],
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white38),
          onPressed: () async {
            await _notificationRepo.deleteNotification(n.id);
            _loadNotifications(showSpinner: false);
          },
        ),
      ),
    );
  }
}
