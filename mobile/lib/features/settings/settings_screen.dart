import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/security/security_service.dart';
import '../../core/services/app_state_service.dart';
import '../../core/sync/data_mode.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_service.dart';
import '../../core/localization/app_translations.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../onboarding/welcome_screen.dart';
import 'data_connection_screen.dart';
import 'edit_gym_screen.dart';
import 'payment_settings_screen.dart';
import 'print_format_settings_screen.dart';
import 'packages_and_plans_screen.dart';
import 'archived_members_screen.dart';
import 'notification_settings_screen.dart';
import '../trainers/trainers_list_screen.dart';
import '../events/events_calendar_screen.dart';
import 'backup_screen.dart';
import 'change_mpin_screen.dart';
import 'accent_color_screen.dart';
import 'list_display_style_screen.dart';
import 'language_settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../help/help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settingsRepo = SettingsRepository();
  AdminModel? _admin;
  DataMode _dataMode = DataMode.offline;
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
    final mode = await DataModeService.instance.getMode();

    if (mounted) {
      setState(() {
        _admin = admin;
        _dataMode = mode;
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
        title: tr('settings_reset_title'),
        message: tr('settings_reset_message'),
        confirmText: tr('settings_reset_confirm'),
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
        title: Text(tr('settings_appbar_title')),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 36 + MediaQuery.paddingOf(context).bottom),
                children: [
                  // Gym Operations Section
                  _SectionHeader(title: tr('settings_section_gym_ops')),
                  _SettingsTile(
                    icon: Icons.store_rounded,
                    title: tr('settings_edit_gym_info'),
                    subtitle: tr('settings_edit_gym_info_sub'),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditGymScreen()));
                      _loadSettings();
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.card_membership_rounded,
                    title: tr('settings_packages_plans'),
                    subtitle: tr('settings_packages_plans_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PackagesAndPlansScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.sports_gymnastics_rounded,
                    title: tr('settings_trainers_payouts'),
                    subtitle: tr('settings_trainers_payouts_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrainersListScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.event_note_rounded,
                    title: tr('settings_events_calendar'),
                    subtitle: tr('settings_events_calendar_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EventsCalendarScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.qr_code_2_rounded,
                    title: tr('settings_payment_settings'),
                    subtitle: tr('settings_payment_settings_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentSettingsScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Printing Section
                  _SectionHeader(title: tr('settings_section_printing')),
                  _SettingsTile(
                    icon: Icons.print_rounded,
                    title: tr('settings_print_format'),
                    subtitle: tr('settings_print_format_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintFormatSettingsScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Appearance Section
                  _SectionHeader(title: tr('settings_section_appearance')),
                  _SettingsTile(
                    icon: Icons.palette_rounded,
                    title: tr('settings_highlight_color'),
                    subtitle: tr('settings_highlight_color_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccentColorScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.view_list_rounded,
                    title: tr('settings_list_display_style'),
                    subtitle: tr('settings_list_display_style_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListDisplayStyleScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Member Management Section
                  _SectionHeader(title: tr('settings_section_member_mgmt')),
                  _SettingsTile(
                    icon: Icons.archive_rounded,
                    title: tr('settings_archived_members'),
                    subtitle: tr('settings_archived_members_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchivedMembersScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Notifications & Alerts Section
                  _SectionHeader(title: tr('settings_section_notifications')),
                  _SettingsTile(
                    icon: Icons.alarm_on_rounded,
                    title: tr('settings_reminder_intervals'),
                    subtitle: tr('settings_reminder_intervals_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
                  ),
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    title: tr('settings_view_active_alerts'),
                    subtitle: tr('settings_view_active_alerts_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Security Section
                  _SectionHeader(title: tr('settings_section_security')),
                  _SettingsTile(
                    icon: Icons.lock_rounded,
                    title: tr('settings_change_mpin'),
                    subtitle: tr('settings_change_mpin_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangeMpinScreen())),
                  ),
                  SwitchListTile(
                    value: _admin?.isBiometricEnabled ?? false,
                    onChanged: _toggleBiometric,
                    activeThumbColor: AppTheme.neonLime,
                    title: Text(tr('settings_biometric_login'), style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(tr('settings_biometric_login_sub'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 18),

                  // Backup Section
                  _SectionHeader(title: tr('settings_section_backup')),
                  _SettingsTile(
                    icon: Icons.backup_rounded,
                    title: tr('settings_export_restore_backup'),
                    subtitle: tr('settings_export_restore_backup_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Data & Sync Section
                  _SectionHeader(title: tr('settings_section_data_sync')),
                  _SettingsTile(
                    icon: _dataMode == DataMode.online ? Icons.cloud_rounded : Icons.smartphone_rounded,
                    title: tr('settings_data_storage_mode'),
                    subtitle: _dataMode == DataMode.online
                        ? tr('settings_data_storage_mode_online')
                        : tr('settings_data_storage_mode_offline'),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const DataConnectionScreen()));
                      _loadSettings();
                    },
                  ),
                  const SizedBox(height: 18),

                  // Language Section
                  _SectionHeader(title: tr('settings_section_language')),
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    title: tr('settings_language_title'),
                    subtitle: LocaleService.instance.current == AppLanguage.hi
                        ? 'हिन्दी (Hindi)'
                        : 'English',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()));
                      _loadSettings();
                    },
                  ),
                  const SizedBox(height: 18),

                  // Help & Support Section
                  _SectionHeader(title: tr('settings_section_help')),
                  _SettingsTile(
                    icon: Icons.help_rounded,
                    title: tr('settings_help_center'),
                    subtitle: tr('settings_help_center_sub'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
                  ),
                  const SizedBox(height: 18),

                  // Danger Zone
                  _SectionHeader(title: tr('settings_section_danger_zone')),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: tr('settings_reset_app_data'),
                    subtitle: tr('settings_reset_app_data_sub'),
                    iconColor: AppTheme.statusOverdue,
                    onTap: _resetData,
                  ),
                  const SizedBox(height: 30),

                  // App Version Footer
                  Center(
                    child: Column(
                      children: [
                        Text(tr('settings_footer_version'), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse('https://devfoxxlabs.com'), mode: LaunchMode.externalApplication),
                          child: Text(tr('settings_footer_credit'), style: TextStyle(color: AppTheme.neonLime, fontSize: 10, fontWeight: FontWeight.w600)),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.neonLime, letterSpacing: 1),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? AppTheme.neonLime),
        title: Text(title, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ),
    );
  }
}
