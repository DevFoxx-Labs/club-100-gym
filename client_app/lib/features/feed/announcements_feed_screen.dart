import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/client_announcement_model.dart';
import '../../core/services/client_announcement_service.dart';
import '../../core/services/client_notification_service.dart';
import '../../core/theme/client_theme.dart';
import '../settings/client_settings_sheet.dart';
import 'widgets/announcement_card.dart';
import 'widgets/announcement_detail_sheet.dart';

class FilterCategory {
  final String key;
  final String label;
  final IconData icon;

  const FilterCategory({required this.key, required this.label, required this.icon});
}

class AnnouncementsFeedScreen extends StatefulWidget {
  const AnnouncementsFeedScreen({super.key});

  @override
  State<AnnouncementsFeedScreen> createState() => _AnnouncementsFeedScreenState();
}

class _AnnouncementsFeedScreenState extends State<AnnouncementsFeedScreen> {
  final _announcementService = ClientAnnouncementService.instance;
  bool _isLoading = true;
  String _selectedCategory = 'all';

  static const List<FilterCategory> _filterCategories = [
    FilterCategory(key: 'all', label: 'All', icon: Icons.grid_view_rounded),
    FilterCategory(key: 'class', label: 'Classes', icon: Icons.calendar_month_rounded),
    FilterCategory(key: 'equipment', label: 'Equipment', icon: Icons.fitness_center_rounded),
    FilterCategory(key: 'hours', label: 'Hours', icon: Icons.access_time_filled_rounded),
    FilterCategory(key: 'event', label: 'Events', icon: Icons.emoji_events_rounded),
    FilterCategory(key: 'maintenance', label: 'Alerts', icon: Icons.warning_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    ClientNotificationService.instance.onNotificationTapped = (id) {
      _openAnnouncementById(id);
    };
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _announcementService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    await _announcementService.fetchAnnouncements(triggerNotificationsForNew: true);
    if (mounted) setState(() {});
  }

  void _openAnnouncementById(String id) {
    final list = _announcementService.announcements;
    final item = list.firstWhere(
      (a) => a.id == id,
      orElse: () => list.first,
    );
    _openAnnouncement(item);
  }

  Future<void> _openAnnouncement(ClientAnnouncementModel item) async {
    await _announcementService.markAsRead(item.id);
    if (mounted) setState(() {});
    if (mounted) {
      await AnnouncementDetailSheet.show(context, item);
      if (mounted) setState(() {});
    }
  }

  List<ClientAnnouncementModel> get _filteredList {
    final all = _announcementService.announcements;
    if (_selectedCategory == 'all') return all;
    return all.where((a) => a.category == _selectedCategory).toList();
  }

  Future<void> _callGym() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappGym() async {
    final uri = Uri.parse('https://wa.me/919876543210?text=Hello%20Elite%20Fitness%20Gym%20Desk');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final announcements = _filteredList;
    final unreadCount = _announcementService.getUnreadCount();

    return Scaffold(
      backgroundColor: ClientTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: ClientTheme.darkBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ClientTheme.textWhite, letterSpacing: 0.5),
                children: [
                  TextSpan(text: 'THE ELITE '),
                  TextSpan(text: 'FITNESS ', style: TextStyle(color: ClientTheme.neonLime)),
                  TextSpan(text: 'GYM'),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Member Notifications Portal',
              style: TextStyle(fontSize: 11, color: ClientTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ClientTheme.textWhite),
            tooltip: 'Sync Announcements',
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: ClientTheme.textWhite),
            tooltip: 'Preferences',
            onPressed: () => ClientSettingsSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ClientTheme.neonLime,
          backgroundColor: ClientTheme.darkSurface,
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 80 + safeBottom),
            children: [
              // Notification Active Pill Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF132B1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E4624)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: ClientTheme.neonLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Notifications enabled ✓ • Push service connected',
                        style: TextStyle(
                          color: ClientTheme.neonLime,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClientTheme.neonLime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount new',
                          style: const TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in _filterCategories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = f.key),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_selectedCategory == f.key)
                                  ? ClientTheme.neonLime.withValues(alpha: 0.16)
                                  : ClientTheme.darkCard,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_selectedCategory == f.key)
                                    ? ClientTheme.neonLime
                                    : ClientTheme.darkBorder,
                                width: (_selectedCategory == f.key) ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  f.icon,
                                  size: 14,
                                  color: (_selectedCategory == f.key)
                                      ? ClientTheme.neonLime
                                      : ClientTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f.label,
                                  style: TextStyle(
                                    color: (_selectedCategory == f.key)
                                        ? ClientTheme.textWhite
                                        : ClientTheme.textMuted,
                                    fontWeight: (_selectedCategory == f.key)
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Announcements List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: ClientTheme.neonLime)),
                )
              else if (announcements.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ClientTheme.darkCard,
                          shape: BoxShape.circle,
                          border: Border.all(color: ClientTheme.darkBorder),
                        ),
                        child: const Icon(Icons.campaign_outlined, size: 40, color: ClientTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Announcements in this category',
                        style: TextStyle(color: ClientTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Updates sent by gym admin will automatically appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ClientTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...announcements.map((item) => AnnouncementCard(
                      announcement: item,
                      onTap: () => _openAnnouncement(item),
                    )),
            ],
          ),
        ),
      ),

      // Fixed Bottom Quick Contact Bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + (safeBottom > 0 ? safeBottom : 6)),
        decoration: const BoxDecoration(
          color: Color(0xFF0F121A),
          border: Border(top: BorderSide(color: Color(0xFF1E222D))),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClientTheme.textWhite,
                  side: const BorderSide(color: ClientTheme.darkBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: ClientTheme.neonLime),
                label: const Text('Call Gym Desk', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                onPressed: _callGym,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.black),
                label: const Text('WhatsApp Help', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
                onPressed: _whatsappGym,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

