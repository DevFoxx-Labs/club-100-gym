import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/admin_model.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/events/events_calendar_screen.dart';
import '../../features/receipts/qr_scanner_screen.dart';
import '../../features/settings/archived_members_screen.dart';
import '../../features/settings/backup_screen.dart';
import '../../features/settings/edit_gym_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/packages_and_plans_screen.dart';
import '../../features/trainers/trainers_list_screen.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectTab;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelectTab,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final SettingsRepository _settingsRepo = SettingsRepository();
  GymInfoModel? _gymInfo;
  AdminModel? _adminInfo;

  @override
  void initState() {
    super.initState();
    _loadHeaderInfo();
  }

  Future<void> _loadHeaderInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    final admin = await _settingsRepo.getAdminInfo();
    if (mounted) {
      setState(() {
        _gymInfo = gym;
        _adminInfo = admin;
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final hasLogo = _gymInfo?.logoPath != null &&
        _gymInfo!.logoPath!.isNotEmpty &&
        File(_gymInfo!.logoPath!).existsSync();

    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).viewPadding.top + 20, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(bottom: BorderSide(color: Color(0xFF252525))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF121212),
                      border: Border.all(color: const Color(0xFFD4FF00), width: 2),
                      image: hasLogo
                          ? DecorationImage(
                              image: FileImage(File(_gymInfo!.logoPath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasLogo
                        ? const Icon(Icons.fitness_center, color: Color(0xFFD4FF00), size: 30)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _gymInfo?.name ?? 'Club 100 Gym',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_greeting, ${_adminInfo?.name ?? 'Admin'}',
                    style: const TextStyle(color: Color(0xFFD4FF00), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Main Destinations
            _buildDrawerTile(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              title: 'Dashboard',
              isSelected: widget.currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(0);
              },
            ),
            _buildDrawerTile(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              title: 'Gym Members',
              isSelected: widget.currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(1);
              },
            ),
            _buildDrawerTile(
              icon: Icons.payments_outlined,
              selectedIcon: Icons.payments,
              title: 'Payments & Receipts',
              isSelected: widget.currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(2);
              },
            ),
            _buildDrawerTile(
              icon: Icons.notifications_outlined,
              selectedIcon: Icons.notifications,
              title: 'Notifications & Alerts',
              isSelected: widget.currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(3);
              },
            ),
            _buildDrawerTile(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              title: 'Settings',
              isSelected: widget.currentIndex == 4,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(4);
              },
            ),

            const Divider(color: Color(0xFF252525), height: 24),

            // Modules & Feature Shortcuts
            _buildDrawerTile(
              icon: Icons.event_available_outlined,
              title: 'Events & Schedule',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsCalendarScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.sports_gymnastics_outlined,
              title: 'Trainers & Staff',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainersListScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.inventory_2_outlined,
              title: 'Packages & Plans',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PackagesAndPlansScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.qr_code_scanner,
              title: 'Scan & Verify Receipt',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.archive_outlined,
              title: 'Archived Members',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedMembersScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.notifications_active_outlined,
              title: 'Reminder Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.storefront_outlined,
              title: 'Gym Info & Logo',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditGymScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.backup_outlined,
              title: 'Backup & Restore',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
              },
            ),

            const Divider(color: Color(0xFF252525), height: 24),

            // Lock App
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFFFF5252)),
              title: const Text(
                'Lock App',
                style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    IconData? selectedIcon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD4FF00).withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? (selectedIcon ?? icon) : icon,
          color: isSelected ? const Color(0xFFD4FF00) : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFFD4FF00) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

