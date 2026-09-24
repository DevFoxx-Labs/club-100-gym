import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SettingsRepository _repository = SettingsRepository();
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await _repository.getNotificationSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        _isLoading = false;
      });
    }
  }

  Future<void> _update(String key, bool val) async {
    setState(() => _settings[key] = val);
    await _repository.saveNotificationSettings(_settings);
    if (key.startsWith('event') && val) {
      NotificationService().syncAllUpcomingEventNotifications();
    } else if (key.startsWith('expiry')) {
      // Re-syncing re-schedules newly enabled tiers and cancels newly disabled ones.
      NotificationService().syncAllMembershipNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'REMINDER SETTINGS',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                _buildSectionHeader('FEE DUE REMINDERS'),
                Card(
                  child: Column(
                    children: [
                      _buildSwitch(
                        title: '7 Days Before Due',
                        subtitle: 'Early heads-up notification for upcoming member fees',
                        value: _settings['fee7d'] ?? true,
                        onChanged: (v) => _update('fee7d', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: '3 Days Before Due',
                        subtitle: 'Reminder notification 3 days prior to due date',
                        value: _settings['fee3d'] ?? true,
                        onChanged: (v) => _update('fee3d', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: '1 Day Before Due',
                        subtitle: 'Urgent reminder on the eve of due date',
                        value: _settings['fee1d'] ?? true,
                        onChanged: (v) => _update('fee1d', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: 'Due Today Alert',
                        subtitle: 'Notification on the exact due date',
                        value: _settings['feeDue'] ?? true,
                        onChanged: (v) => _update('feeDue', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: 'Overdue Fee Alert',
                        subtitle: 'Daily follow-up alerts when payment is past due',
                        value: _settings['feeOverdue'] ?? true,
                        onChanged: (v) => _update('feeOverdue', v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('MEMBERSHIP EXPIRY REMINDERS'),
                Card(
                  child: Column(
                    children: [
                      _buildSwitch(
                        title: '7 Days Before Expiry',
                        subtitle: 'Encourage member to renew their membership plan',
                        value: _settings['expiry7d'] ?? true,
                        onChanged: (v) => _update('expiry7d', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: '3 Days Before Expiry',
                        subtitle: 'Reminder that subscription is ending soon',
                        value: _settings['expiry3d'] ?? true,
                        onChanged: (v) => _update('expiry3d', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: '1 Day Before Expiry',
                        subtitle: 'Last-day alert before membership status lapses to expired',
                        value: _settings['expiry1d'] ?? true,
                        onChanged: (v) => _update('expiry1d', v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('GYM EVENT & CLASS REMINDERS'),
                Card(
                  child: Column(
                    children: [
                      _buildSwitch(
                        title: 'Event Reminders',
                        subtitle: 'Scheduled classes, bootcamps, and gym events',
                        value: _settings['eventReminders'] ?? true,
                        onChanged: (v) => _update('eventReminders', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: 'Alert 30 Minutes Before',
                        subtitle: 'Timely advance reminder before class commences',
                        value: _settings['event30m'] ?? true,
                        onChanged: (v) => _update('event30m', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: 'Alert 15 Minutes Before',
                        subtitle: 'Imminent heads-up alert to prepare for the session',
                        value: _settings['event15m'] ?? true,
                        onChanged: (v) => _update('event15m', v),
                      ),
                      const Divider(height: 1, color: Color(0xFF252525)),
                      _buildSwitch(
                        title: 'Alert At Start Time',
                        subtitle: 'Notification as soon as the event starts',
                        value: _settings['eventAtStart'] ?? true,
                        onChanged: (v) => _update('eventAtStart', v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: AppTheme.neonLime, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.neonLime,
      activeTrackColor: AppTheme.neonLime.withValues(alpha: 0.3),
      onChanged: onChanged,
    );
  }
}
