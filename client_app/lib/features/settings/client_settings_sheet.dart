import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/client_notification_service.dart';
import '../../core/theme/client_theme.dart';

class ClientSettingsSheet extends StatefulWidget {
  const ClientSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ClientTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ClientSettingsSheet(),
    );
  }

  @override
  State<ClientSettingsSheet> createState() => _ClientSettingsSheetState();
}

class _ClientSettingsSheetState extends State<ClientSettingsSheet> {
  String _deviceToken = 'Loading...';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final token = await ClientNotificationService.instance.getDevicePushToken();
    final enabled = await ClientNotificationService.instance.isNotificationsEnabled();
    if (mounted) {
      setState(() {
        _deviceToken = token;
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await ClientNotificationService.instance.setNotificationsEnabled(value);
  }

  Future<void> _sendTestNotification() async {
    await ClientNotificationService.instance.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.notifications_active_rounded, color: ClientTheme.neonLime, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Test notification dispatched! Check your status bar.', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: ClientTheme.darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: ClientTheme.neonLime),
          ),
        ),
      );
    }
  }

  Future<void> _callGym() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + (safeBottom > 0 ? safeBottom : 8)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ClientTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: ClientTheme.neonLime, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Preferences & Device',
                      style: TextStyle(color: ClientTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClientTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notification Toggle Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: ClientTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClientTheme.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ClientTheme.neonLime.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: ClientTheme.neonLime, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push Notifications',
                          style: TextStyle(color: ClientTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                        Text(
                          'Receive instant gym announcements',
                          style: TextStyle(color: ClientTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: Colors.black,
                    activeTrackColor: ClientTheme.neonLime,
                    onChanged: _toggleNotifications,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Device Push Token Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ClientTheme.darkCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClientTheme.darkBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android_rounded, color: ClientTheme.textMuted, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'REGISTERED DEVICE TOKEN',
                            style: TextStyle(color: ClientTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _deviceToken));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Device token copied'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: ClientTheme.darkSurface,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded, color: ClientTheme.neonLime, size: 12),
                              SizedBox(width: 4),
                              Text('Copy', style: TextStyle(color: ClientTheme.neonLime, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _deviceToken,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ClientTheme.neonLime,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Test Notification Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientTheme.neonLime,
                  side: const BorderSide(color: ClientTheme.neonLime),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send_to_mobile_rounded, size: 18),
                label: const Text(
                  'Trigger Test Push Notification',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                onPressed: _sendTestNotification,
              ),
            ),
            const SizedBox(height: 12),

            // Gym Helpline
            InkWell(
              onTap: _callGym,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: ClientTheme.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ClientTheme.darkBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.headset_mic_rounded, color: ClientTheme.textMuted, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Gym Front Desk', style: TextStyle(color: ClientTheme.textWhite, fontSize: 12.5, fontWeight: FontWeight.w700)),
                          Text('+91 98765 43210 • Open 6:00 AM - 10:00 PM', style: TextStyle(color: ClientTheme.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.call_made_rounded, color: ClientTheme.neonLime, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
