import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/security/security_service.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../onboarding/welcome_screen.dart';
import 'edit_gym_screen.dart';
import 'packages_and_plans_screen.dart';
import 'archived_members_screen.dart';
import 'notification_settings_screen.dart';
import '../trainers/trainers_list_screen.dart';
import '../events/events_calendar_screen.dart';
import 'backup_screen.dart';
import 'change_mpin_screen.dart';
import '../notifications/notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  AdminModel? _admin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final admin = await _settingsRepo.getAdminInfo();

    if (mounted) {
      setState(() {
        _admin = admin;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool val) async {
    if (_admin == null) return;
    final updated = AdminModel(
      id: _admin!.id,
      name: _admin!.name,
      phone: _admin!.phone,
      isBiometricEnabled: val,
      createdAt: _admin!.createdAt,
      updatedAt: DateTime.now(),
    );
    await _settingsRepo.saveAdminInfo(updated);
    setState(() => _admin = updated);
  }

  Future<void> _resetData() async {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'RESET ALL APPLICATION DATA?',
        message: 'This action cannot be undone. All members, payments, receipts, trainers, events, and settings will be permanently wiped from this device.',
        confirmText: 'Wipe Everything',
        isDestructive: true,
        onConfirm: () async {
          final nav = Navigator.of(context);
          await AppDatabase.instance.clearAllData();
          await SecurityService().clearSecurityData();

          nav.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APPLICATION SETTINGS'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Gym Operations Section
                  const _SectionHeader(title: 'GYM OPERATIONS & CATALOG'),
                  _SettingsTile(
                    icon: Icons.store_rounded,
                    title: 'Edit Gym Information & Logo',
                    subtitle: 'Name, website, phone, address, gym logo',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditGymScreen()));
                      _loadSettings();
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Packages & Membership Plans',
                    subtitle: 'Organize packages and customizable plans',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PackagesAndPlansScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.sports_gymnastics_rounded,
                    title: 'Trainers & Payouts',
                    subtitle: 'Manage trainers, clients, and payout records',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainersListScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.event_note_rounded,
                    title: 'Events & Calendar',
                    subtitle: 'Gym events, challenges, and workshops',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsCalendarScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Member Management Section
                  const _SectionHeader(title: 'MEMBER MANAGEMENT'),
                  _SettingsTile(
                    icon: Icons.archive_rounded,
                    title: 'Archived Members',
                    subtitle: 'View and restore archived member profiles',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchivedMembersScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Notifications & Alerts Section
                  const _SectionHeader(title: 'NOTIFICATIONS & REMINDERS'),
                  _SettingsTile(
                    icon: Icons.alarm_on_rounded,
                    title: 'Reminder Intervals & Notification Settings',
                    subtitle: 'Configure 7-day, 3-day, and 1-day alert timings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    title: 'View Active Alerts',
                    subtitle: 'Scheduled fee due and membership expiry alerts',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Security Section
                  const _SectionHeader(title: 'SECURITY & AUTHENTICATION'),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    title: 'Change Security MPIN',
                    subtitle: 'Update your 4 to 6 digit login MPIN',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeMpinScreen())),
                  ),
                  SwitchListTile(
                    value: _admin?.isBiometricEnabled ?? false,
                    onChanged: _toggleBiometric,
                    activeThumbColor: AppTheme.neonLime,
                    title: const Text('Fingerprint / Biometric Login', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Unlock app using device biometrics', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 18),

                  // Backup Section
                  const _SectionHeader(title: 'DATA BACKUP & RECOVERY'),
                  _SettingsTile(
                    icon: Icons.backup_rounded,
                    title: 'Export / Restore Backup',
                    subtitle: 'Encrypted .gymbackup file export & import',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Danger Zone
                  const _SectionHeader(title: 'DANGER ZONE'),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Reset Application Data',
                    subtitle: 'Wipe all gym members, payments, and settings',
                    iconColor: AppTheme.statusOverdue,
                    onTap: _resetData,
                  ),
                  const SizedBox(height: 30),

                  // App Version Footer
                  Center(
                    child: Column(
                      children: [
                        const Text('ELITE FITNESS GYM • VERSION 2.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://devfoxxlabs.com'), mode: LaunchMode.externalApplication),
                          child: const Text('Designed and developed by DevFoxx Labs', style: TextStyle(color: AppTheme.neonLime, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.neonLime, letterSpacing: 1),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppTheme.neonLime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
