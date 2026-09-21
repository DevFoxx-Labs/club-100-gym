import 'package:flutter/material.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/members/members_list_screen.dart';
import '../../features/payments/payments_list_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

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

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  String? _membersFilter;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _membersFilter = widget.initialFilter;
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
      DashboardScreen(onNavigateToMembers: (filter) => _onTabSelected(1, filter: filter)),
      MembersListScreen(initialFilter: _membersFilter),
      const PaymentsListScreen(),
      const NotificationsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => _onTabSelected(index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_rounded),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

