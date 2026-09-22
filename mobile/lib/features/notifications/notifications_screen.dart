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
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../events/event_form_screen.dart';
import '../members/member_profile_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../../shared/widgets/confirmation_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _memberRepo = MemberRepository();
  final _eventRepo = EventRepository();
  final _paymentRepo = PaymentRepository();
  final _notificationRepo = NotificationRepository();

  List<Map<String, dynamic>> _allNotifications = [];
  String _selectedCategory = 'All'; // 'All', 'Events', 'Fee Dues', 'Overdue', 'Expiries'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    AppStateService.instance.addListener(_onAppStateChanged);
    // Background sync of scheduled alerts and daily fee scan
    NotificationService().syncAllUpcomingEventNotifications();
    ReminderScheduler().runDailyScan();
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

    // 1. Load Real-Time Fee & Membership Dues
    try {
      final members = await _memberRepo.getMembers();
      for (var m in members) {
        if (!m.isActive || m.deletedAt != null) continue;

        final ms = await _memberRepo.getLatestMembership(m.id);
        if (ms != null) {
          final endDate = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
          final diffDays = endDate.difference(today).inDays;

          final totalPaid = await _paymentRepo.getTotalPaidForMembership(ms.id);
          final isPaidInFull = totalPaid >= ms.feeAmount;

          if (!isPaidInFull) {
            if (diffDays < 0) {
              items.add({
                'id': 'fee_overdue_${m.id}',
                'memberId': m.id,
                'category': 'Overdue',
                'type': 'FEE_OVERDUE',
                'member': m,
                'title': 'Fee Overdue: ${m.name}',
                'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} is overdue by ${diffDays.abs()} days.',
                'badge': 'OVERDUE',
                'color': AppTheme.statusOverdue,
                'icon': Icons.warning_amber_outlined,
                'date': endDate,
                'priority': 1,
                'isRead': false,
              });
            } else if (diffDays == 0) {
              items.add({
                'id': 'fee_due_${m.id}',
                'memberId': m.id,
                'category': 'Fee Dues',
                'type': 'FEE_DUE_TODAY',
                'member': m,
                'title': 'Fee Due Today: ${m.name}',
                'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} expires and is due today.',
                'badge': 'DUE TODAY',
                'color': Colors.orange,
                'icon': Icons.today_outlined,
                'date': endDate,
                'priority': 2,
                'isRead': false,
              });
            } else if (diffDays <= 7) {
              items.add({
                'id': 'fee_soon_${m.id}',
                'memberId': m.id,
                'category': 'Fee Dues',
                'type': 'FEE_DUE_SOON',
                'member': m,
                'title': 'Fee Due in $diffDays Days: ${m.name}',
                'body': 'Membership fee of ₹${ms.feeAmount.toStringAsFixed(0)} is due in $diffDays days.',
                'badge': 'DUE SOON',
                'color': Colors.blue,
                'icon': Icons.schedule,
                'date': endDate,
                'priority': 4,
                'isRead': false,
              });
            }
          }

          // Membership Expiry Notifications
          if (diffDays <= 7) {
            final isExpired = diffDays < 0;
            final isExpiringToday = diffDays == 0;
            final badgeText = isExpired
                ? 'EXPIRED'
                : (isExpiringToday ? 'EXPIRES TODAY' : 'EXPIRING');
            final titleText = isExpired
                ? 'Membership Expired: ${m.name}'
                : (isExpiringToday
                    ? 'Membership Expires Today: ${m.name}'
                    : 'Membership Expiring in $diffDays Days: ${m.name}');
            final bodyText = isExpired
                ? "${m.name}'s gym membership expired ${diffDays.abs()} days ago."
                : (isExpiringToday
                    ? "${m.name}'s gym membership expires at the end of today."
                    : "${m.name}'s gym membership expires in $diffDays days.");

            items.add({
              'id': 'expiry_${m.id}',
              'memberId': m.id,
              'category': 'Expiries',
              'type': isExpired ? 'MEMBERSHIP_EXPIRED' : 'MEMBERSHIP_EXPIRING',
              'member': m,
              'title': titleText,
              'body': bodyText,
              'badge': badgeText,
              'color': isExpired ? Colors.purpleAccent : Colors.purple,
              'icon': Icons.hourglass_bottom,
              'date': endDate,
              'priority': isExpired ? 3 : 4,
              'isRead': false,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading member fee/expiry dues: $e');
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

        // Keep all today's events (including earlier today), upcoming, or recent within 3 days
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
          priority = 0;
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
          'icon': isLive ? Icons.sensors_rounded : Icons.event_available_rounded,
          'date': start,
          'priority': priority,
          'isRead': isEndedToday || isRecent,
        });
      }
    } catch (e) {
      debugPrint('Error loading event notifications: $e');
    }

    // 3. Load Logged / Persisted Push Notifications from SQLite
    try {
      final persistedNotifs = await _notificationRepo.getAllNotifications(limit: 60);
      for (var p in persistedNotifs) {
        // Skip duplicate if already represented by active dues or events
        if (items.any((i) => i['id'] == p.id)) continue;

        String cat = 'All';
        Color color = AppTheme.neonLime;
        IconData icon = Icons.notifications_active_rounded;

        if (p.type.contains('EVENT')) {
          cat = 'Events';
          color = AppTheme.neonLime;
          icon = Icons.event_note_rounded;
        } else if (p.type.contains('OVERDUE')) {
          cat = 'Overdue';
          color = AppTheme.statusOverdue;
          icon = Icons.warning_amber_outlined;
        } else if (p.type.contains('EXPIR')) {
          cat = 'Expiries';
          color = Colors.purple;
          icon = Icons.hourglass_bottom;
        } else {
          cat = 'Fee Dues';
          color = Colors.blue;
          icon = Icons.schedule;
        }

        final date = p.triggeredAt ?? p.scheduledAt;
        final timeStr = _formatNotificationDate(date);

        items.add({
          'id': p.id,
          'memberId': p.memberId,
          'category': cat,
          'type': p.type,
          'title': p.title,
          'body': '${p.message} ($timeStr)',
          'badge': p.type.replaceAll('_', ' '),
          'color': color,
          'icon': icon,
          'date': date,
          'priority': p.isRead ? 4 : 1,
          'isRead': p.isRead,
          'persisted': p,
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted notifications: $e');
    }

    // Sort by priority first, then descending by date (newest alerts on top)
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
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Clear Notifications?',
        message: 'Are you sure you want to dismiss and clear all notification history?',
        confirmLabel: 'Clear All',
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      await _notificationRepo.clearAll();
      _loadNotifications();
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
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.neonLime),
            onPressed: _markAllAsRead,
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

            // Notifications Feed
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : filtered.isEmpty
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
                                          ? 'No pending fee dues, expirations, or scheduled gym events.'
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
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            children: groups.entries.expand((entry) sync* {
                              yield Padding(
                                padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.neonLime,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.darkSurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${entry.value.length}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              for (final item in entry.value) {
                                yield Dismissible(
                                  key: ValueKey(item['id']),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade900,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
                                  ),
                                  onDismissed: (_) async {
                                    final id = item['id'] as String;
                                    await _notificationRepo.deleteNotification(id);
                                    _loadNotifications(showSpinner: false);
                                  },
                                  child: _buildItemCard(item),
                                );
                              }
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final color = item['color'] as Color? ?? AppTheme.neonLime;
    final icon = item['icon'] as IconData? ?? Icons.notifications_active_rounded;
    final badge = item['badge'] as String? ?? 'ALERT';
    final isUnread = !(item['isRead'] as bool? ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnread ? color.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08),
          width: isUnread ? 1.2 : 0.8,
        ),
      ),
      color: isUnread ? color.withValues(alpha: 0.05) : AppTheme.darkSurface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () async {
          // Mark as read
          final id = item['id'] as String;
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
          } else if (item['member'] != null) {
            final member = item['member'] as MemberModel;
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
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.18),
              child: Icon(icon, color: color, size: 22),
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['title'],
                style: TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 14.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
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
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
