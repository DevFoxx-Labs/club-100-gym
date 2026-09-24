import 'package:flutter/material.dart';
import '../../data/models/admin_model.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../features/auth/login_screen.dart';
import '../../features/events/events_calendar_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/receipts/qr_scanner_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/archived_members_screen.dart';
import '../../features/settings/backup_screen.dart';
import '../../features/settings/edit_gym_screen.dart';
import '../../features/settings/notification_settings_screen.dart';
import '../../features/settings/packages_and_plans_screen.dart';
import '../../features/trainers/trainers_list_screen.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';
import 'gym_logo_view.dart';
import '../../core/theme/app_theme.dart';

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
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
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
    if (hour < 12) return tr('drawer_greeting_morning');
    if (hour < 17) return tr('drawer_greeting_afternoon');
    return tr('drawer_greeting_evening');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF181818),
      child: Column(
        children: [
          // Fixed Drawer Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).viewPadding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Color(0xFF252525))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GymLogoView(
                  size: 64,
                  logoPath: _gymInfo?.logoPath,
                ),
                const SizedBox(height: 12),
                Text(
                  _gymInfo?.name ?? 'GymYardHQ',
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
                  '$_greeting, ${_adminInfo?.name ?? tr('drawer_default_admin')}',
                  style: TextStyle(color: AppTheme.neonLime, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (_gymInfo?.website != null && _gymInfo!.website!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    _gymInfo!.website!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          // Scrollable Menu Items Below Header
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 8, 0, MediaQuery.of(context).viewPadding.bottom + 20),
              children: [
                // Main Destinations
            _buildDrawerTile(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              title: tr('drawer_dashboard'),
              isSelected: widget.currentIndex == 0,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(0);
              },
            ),
            _buildDrawerTile(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              title: tr('drawer_gym_members'),
              isSelected: widget.currentIndex == 1,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(1);
              },
            ),
            _buildDrawerTile(
              icon: Icons.payments_outlined,
              selectedIcon: Icons.payments,
              title: tr('drawer_payments_receipts'),
              isSelected: widget.currentIndex == 2,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(2);
              },
            ),
            _buildDrawerTile(
              icon: Icons.campaign_outlined,
              selectedIcon: Icons.campaign,
              title: tr('drawer_announcements'),
              isSelected: widget.currentIndex == 3,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(3);
              },
            ),
            _buildDrawerTile(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              title: tr('drawer_settings'),
              isSelected: widget.currentIndex == 4,
              onTap: () {
                Navigator.pop(context);
                widget.onSelectTab(4);
              },
            ),

            const Divider(color: Color(0xFF252525), height: 24),

            // Modules & Feature Shortcuts
            _buildDrawerTile(
              icon: Icons.notifications_outlined,
              title: tr('drawer_notifications_alerts'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.event_available_outlined,
              title: tr('drawer_events_schedule'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsCalendarScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.receipt_long_outlined,
              title: tr('drawer_expense_tracker'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.insert_chart_outlined_rounded,
              title: tr('drawer_reports_analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.sports_gymnastics_outlined,
              title: tr('drawer_trainers_staff'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainersListScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.inventory_2_outlined,
              title: tr('drawer_packages_plans'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PackagesAndPlansScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.qr_code_scanner,
              title: tr('drawer_scan_verify_receipt'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.archive_outlined,
              title: tr('drawer_archived_members'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedMembersScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.notifications_active_outlined,
              title: tr('drawer_reminder_settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.storefront_outlined,
              title: tr('drawer_gym_info_logo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditGymScreen()));
              },
            ),
            _buildDrawerTile(
              icon: Icons.backup_outlined,
              title: tr('drawer_backup_restore'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen()));
              },
            ),

            const Divider(color: Color(0xFF252525), height: 24),

            // Lock App
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFFFF5252)),
              title: Text(
                tr('drawer_lock_app'),
                style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold),
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
    ],
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
        color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? (selectedIcon ?? icon) : icon,
          color: isSelected ? AppTheme.neonLime : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.neonLime : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

