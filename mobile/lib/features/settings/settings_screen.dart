import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/app_database.dart';
import '../../core/security/security_service.dart';
import '../../data/models/admin_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../onboarding/welcome_screen.dart';
import 'edit_gym_screen.dart';
import 'manage_plans_screen.dart';
import 'backup_screen.dart';
import 'change_mpin_screen.dart';

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
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final admin = await _settingsRepo.getAdminInfo();

    setState(() {
      _admin = admin;
      _isLoading = false;
    });
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
        message: 'This action cannot be undone. All members, payments, receipts, and settings will be permanently wiped from this device.',
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
                  // Gym Section
                  const _SectionHeader(title: 'GYM INFORMATION'),
                  _SettingsTile(
                    icon: Icons.store_rounded,
                    title: 'Edit Gym Information & Logo',
                    subtitle: 'Name, phone, address, currency settings',
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditGymScreen()));
                      _loadSettings();
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.card_membership_rounded,
                    title: 'Manage Membership Plans',
                    subtitle: 'Create, edit, or remove reusable plans',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePlansScreen())),
                  ),
                  const SizedBox(height: 20),

                  // Account & Security Section
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
                    activeColor: AppTheme.neonLime,
                    title: const Text('Fingerprint / Biometric Login', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Unlock app using device biometrics', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),

                  // Backup & Reminders
                  const _SectionHeader(title: 'DATA BACKUP & REMINDERS'),
                  _SettingsTile(
                    icon: Icons.backup_rounded,
                    title: 'Export / Restore Backup',
                    subtitle: 'Encrypted .gymbackup file export & import',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen())),
                  ),
                  const SizedBox(height: 20),

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
                  const Center(
                    child: Column(
                      children: [
                        Text('CLUB 100 THE GYM • VERSION 1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Offline-First Architecture • Flutter 3.24.4', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
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

