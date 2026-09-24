import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/event_model.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../events/event_form_screen.dart';
import '../members/member_profile_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/member_avatar.dart';

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
  String _selectedCategory = 'All'; // 'All', 'Events', 'Fee Dues', 'Overdue', 'Expiries'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  Future<void> _initAndLoad() async {
    // 1. Run scans to ensure database is up to date with any newly due fees or upcoming events
    try {
      await ReminderScheduler().runDailyScan();
      await NotificationService().syncAllUpcomingEventNotifications();
      await NotificationService().syncAllMembershipNotifications();
    } catch (_) {}

    // 2. Load notifications from the database
    if (mounted) {
      await _loadNotifications(showSpinner: true);
    }
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

    try {
      final persistedNotifs = await _notificationRepo.getAllNotifications(limit: 100);
      final members = await _memberRepo.getMembers();
      final events = await _eventRepo.getAllEvents();

      final memberMap = {for (var m in members) m.id: m};
      final eventMap = {for (var e in events) e.id: e};

      for (var p in persistedNotifs) {
        String cat = 'All';
        Color color = AppTheme.neonLime;
        IconData icon = Icons.notifications_active_rounded;
        String badge = 'NOTIFICATION';

        if (p.type.contains('EVENT')) {
          cat = 'Events';
          color = AppTheme.neonLime;
          icon = Icons.event_available_rounded;
          badge = 'EVENT';
        } else if (p.type.contains('OVERDUE')) {
          cat = 'Overdue';
          color = AppTheme.statusOverdue;
          icon = Icons.warning_amber_outlined;
          badge = 'OVERDUE';
        } else if (p.type.contains('EXPIR')) {
          cat = 'Expiries';
          color = Colors.purple;
          icon = Icons.hourglass_bottom_rounded;
          badge = p.type.contains('EXPIRED') ? 'EXPIRED' : 'EXPIRING';
        } else if (p.type.contains('DUE_TODAY')) {
          cat = 'Fee Dues';
          color = Colors.orange;
          icon = Icons.today_outlined;
          badge = 'DUE TODAY';
        } else {
          cat = 'Fee Dues';
          color = Colors.blue;
          icon = Icons.schedule_rounded;
          badge = 'DUE SOON';
        }

        MemberModel? member;
        if (p.memberId != null && memberMap.containsKey(p.memberId)) {
          member = memberMap[p.memberId];
        }

        EventModel? event;
        if (p.id.startsWith('event_')) {
          final eventId = p.id.replaceFirst('event_', '');
          if (eventMap.containsKey(eventId)) {
            event = eventMap[eventId];
            if (event?.colorValue != null) {
              color = Color(event!.colorValue!);
            }
          }
        }

        final date = p.triggeredAt ?? p.scheduledAt;

        items.add({
          'id': p.id,
          'memberId': p.memberId,
          'member': member,
          'event': event,
          'category': cat,
          'type': p.type,
          'title': p.title,
          'body': p.message,
          'badge': badge,
          'color': color,
          'icon': icon,
          'date': date,
          'isRead': p.isRead,
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    // Sort: Unread first, then by date descending (newest on top)
    items.sort((a, b) {
      final isReadA = a['isRead'] as bool? ?? false;
      final isReadB = b['isRead'] as bool? ?? false;
      if (isReadA != isReadB) {
        return isReadA ? 1 : -1;
      }
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
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && date.day == now.day) return DateFormat('hh:mm a').format(date);
    return DateFormat('dd MMM, hh:mm a').format(date);
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == 'All') return _allNotifications;
    return _allNotifications.where((i) => i['category'] == _selectedCategory).toList();
  }

  int _countFor(String cat) {
    if (cat == 'All') return _allNotifications.length;
    return _allNotifications.where((i) => i['category'] == cat).length;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final item in items) {
      final date = item['date'] as DateTime? ?? now;
      final day = DateTime(date.year, date.month, date.day);

      String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else if (day.isAfter(today)) {
        label = 'Upcoming (${DateFormat('EEE, dd MMM').format(day)})';
      } else {
        label = DateFormat('dd MMM yyyy').format(day);
      }

      groups.putIfAbsent(label, () => []).add(item);
    }

    return groups;
  }

  Future<void> _markAllAsRead() async {
    await _notificationRepo.markAllAsRead();
    if (mounted) {
      setState(() {
        for (var item in _allNotifications) {
          item['isRead'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Clear Notifications?',
        message: 'Are you sure you want to dismiss and clear all notification history?',
        confirmLabel: 'Clear All',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      await _notificationRepo.clearAll();
      if (mounted) {
        setState(() {
          _allNotifications.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _dismissNotification(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    await _notificationRepo.deleteNotification(id);
    if (mounted) {
      setState(() {
        _allNotifications.removeWhere((i) => i['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification dismissed'),
          backgroundColor: Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final groups = _groupByDay(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        actions: [
          IconButton(
            tooltip: 'Mark All Read',
            icon: Icon(Icons.done_all_rounded, color: AppTheme.neonLime),
            onPressed: _allNotifications.any((n) => n['isRead'] == false) ? _markAllAsRead : null,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted),
            color: AppTheme.darkSurface,
            onSelected: (val) async {
              if (val == 'clear') {
                _clearAllNotifications();
              } else if (val == 'add_event') {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventFormScreen()),
                );
                if (res == true) _loadNotifications();
              } else if (val == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'add_event',
                child: Row(
                  children: [
                    Icon(Icons.add_alert_rounded, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 10),
                    Text('Add Gym Event', style: TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.textMuted, size: 20),
                    SizedBox(width: 10),
                    Text('Reminder Settings', style: TextStyle(color: AppTheme.textWhite)),
                  ],
                ),
              ),
              if (_allNotifications.isNotEmpty)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Clear All Alerts', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
            ],
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
                  children: ['All', 'Events', 'Fee Dues', 'Overdue', 'Expiries'].map((category) {
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

            // Content List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppTheme.neonLime,
                          backgroundColor: AppTheme.darkSurface,
                          onRefresh: () async {
                            await ReminderScheduler().runDailyScan();
                            await NotificationService().syncAllUpcomingEventNotifications();
                            await NotificationService().syncAllMembershipNotifications();
                            await _loadNotifications(showSpinner: false);
                          },
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.paddingOf(context).bottom),
                            itemCount: groups.keys.length,
                            itemBuilder: (context, groupIndex) {
                              final groupName = groups.keys.elementAt(groupIndex);
                              final groupItems = groups[groupName]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          groupName.toUpperCase(),
                                          style: TextStyle(
                                            color: AppTheme.neonLime,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.darkSurface,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.darkBorder),
                                          ),
                                          child: Text(
                                            '${groupItems.length}',
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...groupItems.map((item) => _buildNotificationCard(item)),
                                ],
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedCategory == 'All'
                  ? 'No Notifications'
                  : 'No $_selectedCategory Notifications',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'All'
                  ? 'You\'re all caught up! Reminders for dues, expiries, and events will appear here.'
                  : 'No active notifications found in this category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final isUnread = !(item['isRead'] as bool? ?? false);
    final color = item['color'] as Color? ?? AppTheme.neonLime;
    final icon = item['icon'] as IconData? ?? Icons.notifications_active_rounded;
    final badge = item['badge'] as String? ?? 'ALERT';
    final date = item['date'] as DateTime? ?? DateTime.now();
    final timeAgo = _formatNotificationDate(date);
    final member = item['member'] as MemberModel?;
    final id = item['id'] as String;

    return Dismissible(
      key: ValueKey('notif_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.statusOverdue.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (_) => _dismissNotification(item),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isUnread ? color.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08),
            width: isUnread ? 1.2 : 0.8,
          ),
        ),
        color: isUnread ? color.withValues(alpha: 0.06) : AppTheme.darkSurface,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          onTap: () async {
            // Mark as read in database
            await _notificationRepo.markAsRead(id);
            if (mounted) setState(() => item['isRead'] = true);
            if (!mounted) return;

            // Handle navigation
            if (item['event'] != null) {
              final event = item['event'] as EventModel;
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
              );
              if (res == true) _loadNotifications();
            } else if (member != null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: member.id)),
              );
            } else if (item['memberId'] != null) {
              final memberId = item['memberId'] as String;
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: memberId)),
              );
            }
          },
          leading: Stack(
            children: [
              if (member != null)
                MemberAvatar(
                  name: member.name,
                  photoPath: member.photoPath,
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.18),
                  foregroundColor: color,
                )
              else
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(icon, color: color, size: 22),
                ),
              if (isUnread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.neonLime,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.darkSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  item['title'] as String? ?? 'Notification',
                  style: TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
                ),
                child: Text(
                  badge,
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                item['body'] as String? ?? '',
                style: TextStyle(
                  color: isUnread ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 12.5,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 12, color: AppTheme.textMuted.withValues(alpha: 0.8)),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: AppTheme.textMuted.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: AppTheme.neonLime,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.neonLime),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
