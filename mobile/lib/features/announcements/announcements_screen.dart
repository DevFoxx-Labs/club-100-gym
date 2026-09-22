import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/services/app_state_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/member_photo_picker.dart';
import '../../data/models/announcement_model.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../notifications/notifications_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const AnnouncementsScreen({super.key, this.onOpenDrawer});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _announcementRepo = AnnouncementRepository();
  final _memberRepo = MemberRepository();
  final _planRepo = PlanRepository();
  final _settingsRepo = SettingsRepository();
  final _notificationRepo = NotificationRepository();
  final _messageController = TextEditingController();

  static const int _maxLength = 500;

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<AnnouncementModel> _announcements = [];
  String _selectedFilter = 'All';
  final Set<String> _expandedIds = {};

  String? _gymName;
  int _unreadNotifCount = 0;

  // Composer state
  String? _pickedImagePath;
  bool _isImportant = false;
  bool _isScheduleEnabled = false;
  DateTime? _scheduledDateTime;

  // Audience state
  List<Map<String, dynamic>> _audienceOptions = [];
  String _audienceType = 'all';
  String _audienceLabel = 'All Members';
  String? _audiencePlanId;

  @override
  void initState() {
    super.initState();
    AppStateService.instance.addListener(_onAppStateChanged);
    _initAndLoad();
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadAnnouncements(showSpinner: false);
      _loadUnreadNotifCount();
    }
  }

  Future<void> _initAndLoad() async {
    await Future.wait([
      _loadGymInfo(),
      _loadAudienceOptions(),
      _loadAnnouncements(showSpinner: true),
      _loadUnreadNotifCount(),
    ]);
  }

  Future<void> _loadGymInfo() async {
    try {
      final gym = await _settingsRepo.getGymInfo();
      if (mounted) setState(() => _gymName = gym.name);
    } catch (_) {}
  }

  Future<void> _loadUnreadNotifCount() async {
    try {
      final count = await _notificationRepo.getUnreadCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (_) {}
  }

  Future<void> _loadAudienceOptions() async {
    try {
      final members = await _memberRepo.getMembers();
      final plans = await _planRepo.getPlans();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int active = 0, overdue = 0, expiring = 0;
      final Map<String, int> planCounts = {};

      for (final member in members) {
        final membership = await _memberRepo.getLatestMembership(member.id);
        if (membership != null) {
          final endDate = DateTime(
            membership.endDate.year,
            membership.endDate.month,
            membership.endDate.day,
          );
          final diffDays = endDate.difference(today).inDays;
          if (diffDays < 0) {
            overdue++;
          } else if (diffDays <= 7) {
            expiring++;
            active++;
          } else {
            active++;
          }
          planCounts[membership.planId] = (planCounts[membership.planId] ?? 0) + 1;
        }
      }

      final options = <Map<String, dynamic>>[
        {'type': 'all', 'label': 'All Members', 'count': members.length, 'icon': Icons.groups_rounded},
        {'type': 'active', 'label': 'Active Members', 'count': active, 'icon': Icons.verified_rounded},
        {'type': 'expiring', 'label': 'Expiring Soon (7 Days)', 'count': expiring, 'icon': Icons.hourglass_bottom_rounded},
        {'type': 'overdue', 'label': 'Overdue Members', 'count': overdue, 'icon': Icons.warning_amber_rounded},
      ];

      for (final plan in plans) {
        options.add({
          'type': 'plan',
          'label': 'Plan: ${plan.name}',
          'count': planCounts[plan.id] ?? 0,
          'icon': Icons.card_membership_rounded,
          'planId': plan.id,
        });
      }

      if (mounted) setState(() => _audienceOptions = options);
    } catch (e) {
      debugPrint('Error loading audience options: $e');
    }
  }

  Future<void> _loadAnnouncements({bool showSpinner = true}) async {
    if (showSpinner && mounted) setState(() => _isLoading = true);
    try {
      final promoted = await _announcementRepo.promoteDueScheduled();
      for (final item in promoted) {
        try {
          await NotificationService().showNotification(
            id: item.id.hashCode.abs() % 100000,
            title: item.displayTitle,
            body: item.message,
          );
        } catch (_) {}
      }

      final list = await _announcementRepo.getAll();
      if (mounted) {
        setState(() {
          _announcements = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AnnouncementModel> get _filteredAnnouncements {
    switch (_selectedFilter) {
      case 'Pinned':
        return _announcements.where((a) => a.isPinned).toList();
      case 'Important':
        return _announcements.where((a) => a.isImportant).toList();
      case 'Scheduled':
        return _announcements.where((a) => a.isScheduled).toList();
      case 'Sent':
        return _announcements.where((a) => a.status == 'sent').toList();
      default:
        return _announcements;
    }
  }

  Future<void> _pickImage() async {
    final result = await pickProfilePhoto(
      context: context,
      currentPath: _pickedImagePath,
      subfolder: 'announcement_images',
    );
    if (result != null && mounted) {
      setState(() => _pickedImagePath = result.isEmpty ? null : result);
    }
  }

  Future<void> _toggleSchedule() async {
    if (_isScheduleEnabled) {
      setState(() {
        _isScheduleEnabled = false;
        _scheduledDateTime = null;
      });
      return;
    }

    final picked = await _pickScheduleDateTime();
    if (picked != null && mounted) {
      setState(() {
        _isScheduleEnabled = true;
        _scheduledDateTime = picked;
      });
    }
  }

  Future<DateTime?> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledDateTime ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(data: AppTheme.darkTheme, child: child!),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (context, child) => Theme(data: AppTheme.darkTheme, child: child!),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectAudience() async {
    if (_audienceOptions.isEmpty) return;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + (bottomInset > 0 ? bottomInset : 10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Audience',
                  style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose who receives this announcement.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _audienceOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final option = _audienceOptions[index];
                      final isSelected = option['type'] == _audienceType &&
                          (option['type'] != 'plan' || option['planId'] == _audiencePlanId);
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.12) : AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.neonLime : AppTheme.darkBorder,
                              width: isSelected ? 1.4 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color: isSelected ? AppTheme.neonLime : AppTheme.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option['label'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.textWhite : AppTheme.textMuted,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.darkSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.darkBorder),
                                ),
                                child: Text(
                                  '${option['count']}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check_circle_rounded, color: AppTheme.neonLime, size: 18),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _audienceType = selected['type'] as String;
        _audienceLabel = selected['label'] as String;
        _audiencePlanId = selected['planId'] as String?;
      });
    }
  }

  String _inferCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('zumba') || lower.contains('class') || lower.contains('session') || lower.contains('workout') || lower.contains('batch')) {
      return 'class';
    }
    if (lower.contains('equipment') || lower.contains('machine') || lower.contains('dumbbell') || lower.contains('weight') || lower.contains('bench')) {
      return 'equipment';
    }
    if (lower.contains('hour') || lower.contains('timing') || lower.contains('sunday') || lower.contains('holiday') || lower.contains('close') || lower.contains('open')) {
      return 'hours';
    }
    if (lower.contains('thank') || lower.contains('appreciation') || lower.contains('offer') || lower.contains('discount') || lower.contains('celebrate') || lower.contains('event')) {
      return 'event';
    }
    if (lower.contains('maintenance') || lower.contains('repair') || lower.contains('sauna') || lower.contains('notice') || lower.contains('water') || lower.contains('power')) {
      return 'maintenance';
    }
    return 'general';
  }

  Future<void> _submitAnnouncement() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSubmitting) return;

    if (_isScheduleEnabled && (_scheduledDateTime == null || _scheduledDateTime!.isBefore(DateTime.now()))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a valid future date and time to schedule.'),
          backgroundColor: AppTheme.statusOverdue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final id = const Uuid().v4();
    final isScheduled = _isScheduleEnabled && _scheduledDateTime != null;

    // Detect title from first line
    final lines = message.split('\n');
    final titleCandidate = lines.first.trim();
    final title = titleCandidate.length <= 60 ? titleCandidate : '${titleCandidate.substring(0, 57)}...';
    final category = _inferCategory(message);

    final announcement = AnnouncementModel(
      id: id,
      title: title,
      message: message,
      imagePath: _pickedImagePath,
      category: category,
      audienceType: _audienceType,
      audienceLabel: _audienceLabel,
      audiencePlanId: _audiencePlanId,
      isImportant: _isImportant,
      isPinned: false,
      status: isScheduled ? 'scheduled' : 'sent',
      scheduledAt: isScheduled ? _scheduledDateTime : null,
      sentAt: isScheduled ? null : now,
      createdAt: now,
    );

    try {
      await _announcementRepo.insert(announcement);

      // Trigger local notification to alert the device
      try {
        if (isScheduled) {
          await NotificationService().scheduleNotification(
            id: id.hashCode.abs() % 100000,
            title: title,
            body: message,
            scheduledDate: _scheduledDateTime!,
          );
        } else {
          await NotificationService().showNotification(
            id: id.hashCode.abs() % 100000,
            title: '📣 $title',
            body: message,
          );
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _messageController.clear();
          _pickedImagePath = null;
          _isImportant = false;
          _isScheduleEnabled = false;
          _scheduledDateTime = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(isScheduled ? Icons.event_available_rounded : Icons.check_circle_rounded, color: AppTheme.neonLime, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isScheduled
                        ? 'Announcement scheduled for ${DateFormat('dd MMM, hh:mm a').format(announcement.scheduledAt!)}'
                        : 'Broadcast sent to $_audienceLabel',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF141720),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.neonLime.withValues(alpha: 0.4))),
          ),
        );
      }

      await _loadAnnouncements(showSpinner: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteAnnouncement(AnnouncementModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Delete Announcement?',
        message: 'This announcement will be permanently removed.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      await _announcementRepo.delete(item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement deleted'),
            backgroundColor: Color(0xFF1E1E1E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadAnnouncements(showSpinner: false);
    }
  }

  Future<void> _shareToWhatsApp({required String message, String? imagePath}) async {
    if (message.isEmpty) return;
    try {
      if (imagePath != null && imagePath.isNotEmpty && await File(imagePath).exists()) {
        await Share.shareXFiles([XFile(imagePath)], text: message);
      } else {
        await Share.share(message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open share sheet: $e'),
            backgroundColor: AppTheme.statusOverdue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  ({IconData icon, Color iconColor, Color bgColor}) _categoryVisuals(String category) {
    switch (category) {
      case 'class':
        return (
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF69F0AE),
          bgColor: const Color(0xFF142918),
        );
      case 'equipment':
        return (
          icon: Icons.fitness_center_rounded,
          iconColor: const Color(0xFF38BDF8),
          bgColor: const Color(0xFF132238),
        );
      case 'hours':
        return (
          icon: Icons.access_time_filled_rounded,
          iconColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFF2E1C0C),
        );
      case 'event':
        return (
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFA855F7),
          bgColor: const Color(0xFF261338),
        );
      case 'maintenance':
        return (
          icon: Icons.warning_rounded,
          iconColor: const Color(0xFFF43F5E),
          bgColor: const Color(0xFF331418),
        );
      default:
        return (
          icon: Icons.campaign_rounded,
          iconColor: AppTheme.neonLime,
          bgColor: const Color(0xFF142918),
        );
    }
  }

  String _formatCardDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatCardTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final filtered = _filteredAnnouncements;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.neonLime),
          tooltip: 'Open Menu',
          onPressed: widget.onOpenDrawer,
        ),
        title: _buildAppBarTitle(),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textWhite, size: 24),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  _loadUnreadNotifCount();
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: AppTheme.neonLime, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppTheme.neonLime,
          backgroundColor: AppTheme.darkSurface,
          onRefresh: () async {
            await _loadAudienceOptions();
            await _loadAnnouncements(showSpinner: false);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + safeBottom),
            children: [
              _buildSectionHeader(),
              const SizedBox(height: 16),
              _buildComposeCard(),
              const SizedBox(height: 22),
              _buildRecentHeader(),
              const SizedBox(height: 12),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppTheme.neonLime)),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map(_buildAnnouncementCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    final rawName = (_gymName ?? 'THE ELITE FITNESS GYM').toUpperCase();
    final name = rawName.isEmpty ? 'THE ELITE FITNESS GYM' : rawName;

    Widget titleText;
    if (name.contains('FITNESS')) {
      final parts = name.split('FITNESS');
      titleText = RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textWhite, letterSpacing: 0.5),
          children: [
            TextSpan(text: parts[0]),
            TextSpan(text: 'FITNESS', style: TextStyle(color: AppTheme.neonLime)),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    } else {
      titleText = Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textWhite, letterSpacing: 0.5),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleText,
        const SizedBox(height: 2),
        const Text(
          'Admin Panel',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF142918),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.campaign_rounded, color: Color(0xFF69F0AE), size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcements',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.3),
              ),
              SizedBox(height: 2),
              Text(
                'Send important updates to all gym members.',
                maxLines: 2,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _selectAudience,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF132B1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1E4624)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFF69F0AE), size: 16),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.28),
                  child: Text(
                    _audienceLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF69F0AE), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF69F0AE), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposeCard() {
    final length = _messageController.text.length;
    final canSubmit = _messageController.text.trim().isNotEmpty && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222838)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Create Announcement',
                style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 15),
              ),
              Text(
                '$length/$_maxLength',
                style: TextStyle(
                  color: length > _maxLength ? AppTheme.statusOverdue : AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F121A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF222838)),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              maxLength: _maxLength,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13.5),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              decoration: const InputDecoration(
                hintText: 'Type your announcement here...',
                contentPadding: EdgeInsets.all(14),
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_pickedImagePath != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(_pickedImagePath!),
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => setState(() => _pickedImagePath = null),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_isScheduleEnabled && _scheduledDateTime != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await _pickScheduleDateTime();
                if (picked != null && mounted) setState(() => _scheduledDateTime = picked);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.statusDueSoon.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.statusDueSoon.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppTheme.statusDueSoon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled for ${DateFormat('dd MMM yyyy, hh:mm a').format(_scheduledDateTime!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textWhite, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.edit_rounded, color: AppTheme.statusDueSoon, size: 14),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionChip(
                  icon: Icons.image_outlined,
                  label: _pickedImagePath == null ? 'Add Image' : 'Change',
                  isActive: _pickedImagePath != null,
                  hasSwitch: false,
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildActionChip(
                  icon: Icons.push_pin_outlined,
                  label: 'Important',
                  isActive: _isImportant,
                  hasSwitch: true,
                  onTap: () => setState(() => _isImportant = !_isImportant),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildActionChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Schedule',
                  isActive: _isScheduleEnabled,
                  hasSwitch: true,
                  onTap: _toggleSchedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF2A3A2F),
                disabledForegroundColor: Colors.white38,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isScheduleEnabled
                    ? 'Schedule Announcement'
                    : 'Broadcast to $_audienceLabel',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.2),
              ),
              onPressed: canSubmit ? _submitAnnouncement : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required bool hasSwitch,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F121A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF69F0AE).withValues(alpha: 0.6) : const Color(0xFF222838),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isActive ? const Color(0xFF69F0AE) : AppTheme.textMuted),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isActive ? AppTheme.textWhite : AppTheme.textMuted,
                ),
              ),
            ),
            if (hasSwitch) ...[
              const SizedBox(width: 3),
              Container(
                width: 16,
                height: 10,
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF69F0AE) : const Color(0xFF2E3445),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.black : Colors.white60,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Announcements',
          style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        PopupMenuButton<String>(
          color: const Color(0xFF161922),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF222838))),
          onSelected: (val) => setState(() => _selectedFilter = val),
          itemBuilder: (context) => ['All', 'Pinned', 'Important', 'Scheduled', 'Sent']
              .map((f) => PopupMenuItem(
                    value: f,
                    child: Row(
                      children: [
                        if (_selectedFilter == f) const Icon(Icons.check_rounded, color: Color(0xFF69F0AE), size: 16),
                        if (_selectedFilter == f) const SizedBox(width: 8),
                        Text(f, style: const TextStyle(color: AppTheme.textWhite)),
                      ],
                    ),
                  ))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF222838)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedFilter, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF161922),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF222838)),
            ),
            child: const Icon(Icons.campaign_outlined, size: 40, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All' ? 'No Announcements Yet' : 'No $_selectedFilter Announcements',
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Broadcasts you send to members will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(AnnouncementModel item) {
    final visuals = _categoryVisuals(item.category);
    final isExpanded = _expandedIds.contains(item.id);
    final date = item.status == 'sent' ? (item.sentAt ?? item.createdAt) : (item.scheduledAt ?? item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPinned ? const Color(0xFF69F0AE).withValues(alpha: 0.35) : const Color(0xFF222838),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visuals.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visuals.icon, color: visuals.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                        ),
                        if (item.isPinned) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF69F0AE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pinned',
                              style: TextStyle(color: Colors.black, fontSize: 9.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCardDate(date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500)),
                  Text(_formatCardTime(date), style: const TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500)),
                ],
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 18),
                color: const Color(0xFF161922),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFF222838))),
                onSelected: (val) async {
                  if (val == 'pin') {
                    await _announcementRepo.setPinned(item.id, !item.isPinned);
                    _loadAnnouncements(showSpinner: false);
                  } else if (val == 'important') {
                    await _announcementRepo.setImportant(item.id, !item.isImportant);
                    _loadAnnouncements(showSpinner: false);
                  } else if (val == 'delete') {
                    _deleteAnnouncement(item);
                  } else if (val == 'whatsapp') {
                    _shareToWhatsApp(message: item.message, imagePath: item.imagePath);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 18),
                        SizedBox(width: 10),
                        Text('Share to WhatsApp', style: TextStyle(color: AppTheme.textWhite)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(item.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(item.isPinned ? 'Unpin' : 'Pin to Top', style: const TextStyle(color: AppTheme.textWhite)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'important',
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(item.isImportant ? 'Remove Important' : 'Mark Important', style: const TextStyle(color: AppTheme.textWhite)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedIds.remove(item.id);
              } else {
                _expandedIds.add(item.id);
              }
            }),
            child: Text(
              item.message,
              maxLines: isExpanded ? null : 3,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
            ),
          ),
          if (item.imagePath != null && item.imagePath!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(item.imagePath!),
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
