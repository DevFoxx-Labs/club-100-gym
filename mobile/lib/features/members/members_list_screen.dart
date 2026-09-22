import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../shared/widgets/member_avatar.dart';
import '../../core/services/app_state_service.dart';
import 'add_edit_member_screen.dart';
import 'member_profile_screen.dart';

enum _MemberSortOption {
  nameAsc,
  nameDesc,
  joinDateDesc,
  expiryAsc,
}

enum _MemberHealth {
  active,
  dueSoon,
  dueToday,
  overdue,
  expired,
  noPlan,
}

class MembersListScreen extends StatefulWidget {
  final String? initialFilter;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNavigateToNotifications;

  const MembersListScreen({
    super.key,
    this.initialFilter,
    this.onOpenDrawer,
    this.onNavigateToNotifications,
  });

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _memberRepo = MemberRepository();
  final _settingsRepo = SettingsRepository();
  final _notificationRepo = NotificationRepository();
  final _searchController = TextEditingController();

  List<MemberModel> _allMembers = [];
  Map<String, MembershipModel?> _memberships = {};
  List<MemberModel> _filteredMembers = [];
  bool _isLoading = true;
  int _unreadNotifCount = 0;
  GymInfoModel? _gymInfo;

  String _selectedTab = 'All'; // All, Active, Due Soon, Overdue, Expired
  _MemberSortOption _sortOption = _MemberSortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedTab = _normalizeFilterTab(widget.initialFilter!);
    }
    _loadMembers();
    _searchController.addListener(_applyFilters);
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void didUpdateWidget(covariant MembersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedTab = _normalizeFilterTab(widget.initialFilter!);
      });
      _applyFilters();
    }
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeFilterTab(String raw) {
    switch (raw.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'duesoon':
      case 'due soon':
      case 'duetoday':
      case 'due today':
        return 'Due Soon';
      case 'overdue':
        return 'Overdue';
      case 'expired':
        return 'Expired';
      default:
        return 'All';
    }
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadMembers(showSpinner: false);
    }
  }

  Future<void> _loadMembers({bool showSpinner = true}) async {
    if (showSpinner || _allMembers.isEmpty) {
      setState(() => _isLoading = true);
    }

    final members = await _memberRepo.getMembers();
    final Map<String, MembershipModel?> memberships = {};

    for (var m in members) {
      final ms = await _memberRepo.getLatestMembership(m.id);
      memberships[m.id] = ms;
    }

    final unread = await _notificationRepo.getUnreadCount();
    final gymInfo = await _settingsRepo.getGymInfo();

    if (mounted) {
      setState(() {
        _allMembers = members;
        _memberships = memberships;
        _unreadNotifCount = unread;
        _gymInfo = gymInfo;
        _isLoading = false;
      });

      _applyFilters();
    }
  }

  _MemberHealth _getHealth(String memberId) {
    final ms = _memberships[memberId];
    if (ms == null) return _MemberHealth.noPlan;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
    final diffDays = endDate.difference(today).inDays;

    if (diffDays < 0) return _MemberHealth.overdue;
    if (diffDays == 0) return _MemberHealth.dueToday;
    if (diffDays <= 7) return _MemberHealth.dueSoon;
    return _MemberHealth.active;
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredMembers = _allMembers.where((m) {
        final matchesQuery = query.isEmpty ||
            m.name.toLowerCase().contains(query) ||
            m.phone.contains(query) ||
            m.id.toLowerCase().contains(query);

        if (!matchesQuery) return false;

        final health = _getHealth(m.id);

        if (_selectedTab == 'Active') {
          return health == _MemberHealth.active;
        } else if (_selectedTab == 'Due Soon') {
          return health == _MemberHealth.dueSoon || health == _MemberHealth.dueToday;
        } else if (_selectedTab == 'Overdue') {
          return health == _MemberHealth.overdue;
        } else if (_selectedTab == 'Expired') {
          return health == _MemberHealth.overdue || health == _MemberHealth.expired;
        }

        return true; // All
      }).toList();

      // Apply sorting
      switch (_sortOption) {
        case _MemberSortOption.nameAsc:
          _filteredMembers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case _MemberSortOption.nameDesc:
          _filteredMembers.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case _MemberSortOption.joinDateDesc:
          _filteredMembers.sort((a, b) {
            final aJoin = _memberships[a.id]?.startDate ?? a.createdAt;
            final bJoin = _memberships[b.id]?.startDate ?? b.createdAt;
            return bJoin.compareTo(aJoin);
          });
          break;
        case _MemberSortOption.expiryAsc:
          _filteredMembers.sort((a, b) {
            final aEnd = _memberships[a.id]?.endDate;
            final bEnd = _memberships[b.id]?.endDate;
            if (aEnd == null && bEnd == null) return 0;
            if (aEnd == null) return 1;
            if (bEnd == null) return -1;
            return aEnd.compareTo(bEnd);
          });
          break;
      }
    });
  }

  void _handleMemberAction(String action, MemberModel member) async {
    switch (action) {
      case 'view':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MemberProfileScreen(memberId: member.id),
          ),
        );
        _loadMembers(showSpinner: false);
        break;
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditMemberScreen(member: member),
          ),
        );
        _loadMembers(showSpinner: false);
        break;
      case 'call':
        if (member.phone.isNotEmpty) {
          final uri = Uri.parse('tel:${member.phone}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
        break;
      case 'whatsapp':
        if (member.phone.isNotEmpty) {
          final cleanPhone = member.phone.replaceAll(RegExp(r'\D'), '');
          final phoneWithCode = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
          final uri = Uri.parse('https://wa.me/$phoneWithCode');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
    }
  }

  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.paddingOf(context).bottom;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  16 + (bottomInset > 0 ? bottomInset : 10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter & Sort Members',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SORT BY',
                      style: TextStyle(
                        color: AppTheme.neonLime,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _sortChoiceChip('Name (A-Z)', _MemberSortOption.nameAsc, setSheetState),
                        _sortChoiceChip('Name (Z-A)', _MemberSortOption.nameDesc, setSheetState),
                        _sortChoiceChip('Join Date (Newest)', _MemberSortOption.joinDateDesc, setSheetState),
                        _sortChoiceChip('Expiry (Soonest)', _MemberSortOption.expiryAsc, setSheetState),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _applyFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonLime,
                          foregroundColor: AppTheme.darkBackground,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortChoiceChip(String label, _MemberSortOption option, StateSetter setSheetState) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppTheme.neonLime,
      backgroundColor: AppTheme.darkBackground,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.darkBackground : AppTheme.textWhite,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) {
          setSheetState(() => _sortOption = option);
          setState(() => _sortOption = option);
        }
      },
    );
  }

  Widget _buildAppBarTitle() {
    final rawName = (_gymInfo?.name ?? 'THE ELITE FITNESS GYM').toUpperCase();
    final name = rawName.isEmpty ? 'THE ELITE FITNESS GYM' : rawName;

    if (name.contains('FITNESS')) {
      final parts = name.split('FITNESS');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppTheme.textWhite,
                letterSpacing: 0.5,
              ),
              children: [
                TextSpan(text: parts[0]),
                const TextSpan(
                  text: 'FITNESS',
                  style: TextStyle(color: AppTheme.neonLime),
                ),
                if (parts.length > 1) TextSpan(text: parts[1]),
              ],
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Stronger People. Healthier Lives.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppTheme.textWhite,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Stronger People. Healthier Lives.',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? dotColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected && dotColor == null
              ? AppTheme.neonLime
              : (isSelected
                  ? dotColor!.withValues(alpha: 0.18)
                  : AppTheme.darkSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (dotColor ?? AppTheme.neonLime)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected && dotColor == null ? AppTheme.darkBackground : Colors.white70,
              ),
              const SizedBox(width: 6),
            ],
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected && dotColor == null ? AppTheme.darkBackground : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String statusText, Color statusColor) {
    IconData icon;
    if (statusText == 'Active') {
      icon = Icons.check_circle_rounded;
    } else if (statusText.contains('Due')) {
      icon = Icons.access_time_rounded;
    } else if (statusText == 'No Plan') {
      icon = Icons.help_outline_rounded;
    } else {
      icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: statusColor),
          const SizedBox(width: 5),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    // 108dp padding ensures the last list item can be scrolled completely clear of FAB and bottom navigation
    final listBottomPadding = safeBottomInset + 108.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.neonLime),
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
                onPressed: widget.onNavigateToNotifications,
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.neonLime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Members Headline & Total Members Stat Card (Wrapped with Expanded to prevent horizontal overflow)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: TextStyle(
                            color: AppTheme.textWhite,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Manage and view all gym members',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = 'All';
                        _searchController.clear();
                      });
                      _applyFilters();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.neonLime.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: AppTheme.neonLime,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_allMembers.length}',
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  height: 1.1,
                                ),
                              ),
                              const Text(
                                'Total Members',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.textMuted,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Button Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, or ID...',
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 22),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppTheme.textWhite, size: 20),
                      tooltip: 'Filter / Sort',
                      onPressed: _showFilterSortSheet,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'All',
                    icon: Icons.groups_rounded,
                    isSelected: _selectedTab == 'All',
                    onTap: () {
                      setState(() => _selectedTab = 'All');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Active',
                    dotColor: const Color(0xFF00E676),
                    isSelected: _selectedTab == 'Active',
                    onTap: () {
                      setState(() => _selectedTab = 'Active');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Due Soon',
                    dotColor: const Color(0xFFFFB300),
                    isSelected: _selectedTab == 'Due Soon',
                    onTap: () {
                      setState(() => _selectedTab = 'Due Soon');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Overdue',
                    dotColor: const Color(0xFFFF3B30),
                    isSelected: _selectedTab == 'Overdue',
                    onTap: () {
                      setState(() => _selectedTab = 'Overdue');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Expired',
                    dotColor: const Color(0xFF8E8E93),
                    isSelected: _selectedTab == 'Expired',
                    onTap: () {
                      setState(() => _selectedTab = 'Expired');
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),

            // Members List (Safe-area aware bottom padding)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : _filteredMembers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              const Text(
                                'No members found',
                                style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Add your first member to start managing your gym.',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
                                  );
                                  _loadMembers();
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Member'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 8, 20, listBottomPadding),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final ms = _memberships[member.id];
                            final health = _getHealth(member.id);

                            Color statusColor;
                            String statusText;
                            switch (health) {
                              case _MemberHealth.active:
                                statusColor = const Color(0xFF00E676);
                                statusText = 'Active';
                                break;
                              case _MemberHealth.dueSoon:
                                statusColor = const Color(0xFFFFB300);
                                final now = DateTime.now();
                                final today = DateTime(now.year, now.month, now.day);
                                final end = DateTime(ms!.endDate.year, ms.endDate.month, ms.endDate.day);
                                final diff = end.difference(today).inDays;
                                statusText = 'Due in $diff d';
                                break;
                              case _MemberHealth.dueToday:
                                statusColor = const Color(0xFFFFB300);
                                statusText = 'Fee Due Today';
                                break;
                              case _MemberHealth.overdue:
                                statusColor = const Color(0xFFFF3B30);
                                statusText = 'Overdue';
                                break;
                              case _MemberHealth.expired:
                                statusColor = const Color(0xFF8E8E93);
                                statusText = 'Expired';
                                break;
                              case _MemberHealth.noPlan:
                                statusColor = Colors.white60;
                                statusText = 'No Plan';
                                break;
                            }

                            // Dates & Days Left calculation
                            final joinDateStr = dateFormat.format(ms?.startDate ?? member.createdAt);
                            final expiryDateStr = ms != null ? dateFormat.format(ms.endDate) : 'N/A';

                            String daysLeftText = '';
                            Color daysLeftColor = const Color(0xFFD4FF00);

                            if (ms != null) {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              final end = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
                              final diff = end.difference(today).inDays;

                              if (diff > 0) {
                                daysLeftText = '($diff days left)';
                                daysLeftColor = diff <= 7 ? const Color(0xFFFFB300) : const Color(0xFFD4FF00);
                              } else if (diff == 0) {
                                daysLeftText = '(Due today)';
                                daysLeftColor = const Color(0xFFFFB300);
                              } else {
                                daysLeftText = '(${diff.abs()} days overdue)';
                                daysLeftColor = const Color(0xFFFF3B30);
                              }
                            }

                            final planName = ms?.planName ?? 'No Plan';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                              color: AppTheme.darkSurface,
                              elevation: 0,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemberProfileScreen(memberId: member.id),
                                    ),
                                  );
                                  _loadMembers(showSpinner: false);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Avatar with status dot, Info, Actions
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              MemberAvatar(
                                                name: member.name,
                                                photoPath: member.photoPath,
                                                radius: 28,
                                                fontSize: 20,
                                              ),
                                              Positioned(
                                                top: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: AppTheme.darkSurface,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  member.name,
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  member.phone,
                                                  style: const TextStyle(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                _buildStatusPill(statusText, statusColor),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              PopupMenuButton<String>(
                                                icon: const Icon(
                                                  Icons.more_vert_rounded,
                                                  color: Colors.white38,
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                color: AppTheme.darkCard,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                                                ),
                                                onSelected: (action) => _handleMemberAction(action, member),
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'view',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.person_outline_rounded, size: 18, color: Colors.white70),
                                                        SizedBox(width: 10),
                                                        Text('View Profile', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                                                        SizedBox(width: 10),
                                                        Text('Edit Member', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                      ],
                                                    ),
                                                  ),
                                                  if (member.phone.isNotEmpty) ...[
                                                    const PopupMenuItem(
                                                      value: 'call',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.phone_outlined, size: 18, color: Colors.white70),
                                                          SizedBox(width: 10),
                                                          Text('Call Member', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'whatsapp',
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.chat_outlined, size: 18, color: Colors.white70),
                                                          SizedBox(width: 10),
                                                          Text('WhatsApp', style: TextStyle(color: Colors.white, fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                width: 34,
                                                height: 34,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.04),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                                ),
                                                child: const Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: Colors.white60,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Divider
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: Colors.white.withValues(alpha: 0.05),
                                        ),
                                      ),

                                      // Bottom 3-column stats row (with Flexible protection against overflow)
                                      Row(
                                        children: [
                                          // Column 1: Membership
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.fitness_center_rounded,
                                                      size: 14,
                                                      color: Color(0xFF00E676),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Membership',
                                                        style: TextStyle(
                                                          color: AppTheme.textMuted,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  planName,
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Vertical Divider 1
                                          Container(
                                            width: 1,
                                            height: 32,
                                            color: Colors.white.withValues(alpha: 0.06),
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                          ),

                                          // Column 2: Join Date
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today_outlined,
                                                      size: 13,
                                                      color: AppTheme.textMuted,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Join Date',
                                                        style: TextStyle(
                                                          color: AppTheme.textMuted,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  joinDateStr,
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Vertical Divider 2
                                          Container(
                                            width: 1,
                                            height: 32,
                                            color: Colors.white.withValues(alpha: 0.06),
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                          ),

                                          // Column 3: Expiry Date & Days Left
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month_outlined,
                                                      size: 13,
                                                      color: AppTheme.textMuted,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Flexible(
                                                      child: Text(
                                                        'Expiry Date',
                                                        style: TextStyle(
                                                          color: AppTheme.textMuted,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  expiryDateStr,
                                                  style: const TextStyle(
                                                    color: AppTheme.textWhite,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12.5,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (daysLeftText.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    daysLeftText,
                                                    style: TextStyle(
                                                      color: daysLeftColor,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 11,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
          );
          _loadMembers();
        },
        backgroundColor: AppTheme.neonLime,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: AppTheme.darkBackground, size: 22),
        label: const Text(
          'Add Member',
          style: TextStyle(
            color: AppTheme.darkBackground,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
