import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/members/members_list_screen.dart';
import '../../features/payments/payments_list_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../core/notifications/reminder_scheduler.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../data/repositories/notification_repository.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String? initialFilter;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialFilter,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  String? _membersFilter;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _membersFilter = widget.initialFilter;
    AppStateService.instance.addListener(_loadUnreadCount);
    _loadUnreadCount();
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_loadUnreadCount);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationRepository().getUnreadCount();
    if (mounted) {
      setState(() => _unreadCount = count);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ReminderScheduler().runDailyScan();
      NotificationService().syncAllUpcomingEventNotifications();
      _loadUnreadCount();
    }
  }

  void _onTabSelected(int index, {String? filter}) {
    setState(() {
      _currentIndex = index;
      if (filter != null) {
        _membersFilter = filter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToMembers: (filter) => _onTabSelected(1, filter: filter),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      MembersListScreen(
        initialFilter: _membersFilter,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onNavigateToNotifications: () => _onTabSelected(3),
      ),
      const PaymentsListScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentIndex: _currentIndex,
        onSelectTab: (index) => _onTabSelected(index),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F121A),
          border: Border(
            top: BorderSide(color: Color(0xFF1E222D), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F121A),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: AppTheme.neonLime,
          unselectedItemColor: AppTheme.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: (index) => _onTabSelected(index),
          items: [
            BottomNavigationBarItem(
              icon: _currentIndex == 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grid_view_rounded, color: AppTheme.neonLime, size: 20),
                    )
                  : const Icon(Icons.grid_view_rounded, size: 22),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded, size: 22),
              label: 'Members',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.credit_card_rounded, size: 22),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: _unreadCount > 0,
                label: Text('$_unreadCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.statusOverdue,
                child: const Icon(Icons.notifications_rounded, size: 22),
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded, size: 22),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
