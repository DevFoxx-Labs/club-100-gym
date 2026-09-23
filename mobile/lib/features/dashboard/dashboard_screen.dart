import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/models/admin_model.dart';
import '../../data/models/payment_model.dart';
import 'widgets/summary_card.dart';
import '../members/add_edit_member_screen.dart';
import '../trainers/trainers_list_screen.dart';
import '../events/events_calendar_screen.dart';
import '../receipts/receipt_preview_screen.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_translations.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String filter) onNavigateToMembers;
  final VoidCallback? onOpenDrawer;

  const DashboardScreen({
    super.key,
    required this.onNavigateToMembers,
    this.onOpenDrawer,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _memberRepo = MemberRepository();
  final _settingsRepo = SettingsRepository();
  final _paymentRepo = PaymentRepository();

  bool _isLoading = true;
  GymInfoModel? _gymInfo;
  AdminModel? _admin;

  int _totalMembers = 0;
  int _activeMembers = 0;
  int _feesDueSoon = 0;
  int _feesDueToday = 0;
  int _overdueFees = 0;
  int _expiringSoon = 0;

  List<PaymentModel> _recentPayments = [];
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadDashboardData(showSpinner: false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('drawer_greeting_morning');
    if (hour < 17) return tr('drawer_greeting_afternoon');
    return tr('drawer_greeting_evening');
  }

  Future<void> _loadDashboardData({bool showSpinner = true}) async {
    if (showSpinner || _gymInfo == null) {
      setState(() => _isLoading = true);
    }

    final gym = await _settingsRepo.getGymInfo();
    final admin = await _settingsRepo.getAdminInfo();
    final members = await _memberRepo.getMembers();
    final payments = await _paymentRepo.getRecentPayments(limit: 5);

    final namesMap = <String, String>{};
    for (var m in members) {
      namesMap[m.id] = m.name;
    }

    int active = 0;
    int dueSoon = 0;
    int dueToday = 0;
    int overdue = 0;
    int expiring = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var member in members) {
      final membership = await _memberRepo.getLatestMembership(member.id);
      if (membership != null) {
        final endDate = DateTime(membership.endDate.year, membership.endDate.month, membership.endDate.day);
        final diffDays = endDate.difference(today).inDays;

        if (diffDays < 0) {
          overdue++;
        } else if (diffDays == 0) {
          dueToday++;
          active++;
        } else if (diffDays <= 7) {
          dueSoon++;
          expiring++;
          active++;
        } else {
          active++;
        }
      }
    }

    if (mounted) {
      setState(() {
        _gymInfo = gym;
        _admin = admin;
        _memberNames = namesMap;
        _recentPayments = payments;
        _totalMembers = members.length;
        _activeMembers = active;
        _feesDueSoon = dueSoon;
        _feesDueToday = dueToday;
        _overdueFees = overdue;
        _expiringSoon = expiring;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    // Format gym name with dual-tone styling
    final gymName = (_gymInfo?.name != null && _gymInfo!.name.isNotEmpty)
        ? _gymInfo!.name.toUpperCase().trim()
        : tr('dashboard_default_gym_name');
    final words = gymName.split(' ');
    String firstPart = gymName;
    String lastPart = '';
    if (words.length > 1) {
      lastPart = words.removeLast();
      firstPart = words.join(' ');
    }

    final adminFirstName = (_admin?.name != null && _admin!.name.isNotEmpty)
        ? _admin!.name.split(' ').first
        : tr('drawer_default_admin');

    return Scaffold(
      backgroundColor: const Color(0xFF0C0F14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: AppTheme.neonLime, size: 28),
          tooltip: tr('dashboard_open_menu'),
          onPressed: widget.onOpenDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$firstPart ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (lastPart.isNotEmpty)
                    TextSpan(
                      text: lastPart,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.neonLime,
                        letterSpacing: 0.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Text(
              tr('dashboard_subtitle'),
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Material(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _loadDashboardData,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222838), width: 1),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: AppTheme.textWhite, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fullscreen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/app-bg-2.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
          // Readability scrim over the background image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0C0F14).withValues(alpha: 0.82),
                    const Color(0xFF0C0F14).withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.neonLime,
              backgroundColor: AppTheme.darkSurface,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 36 + safeBottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting & Slogan Banner Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Greeting
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          height: 11,
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonLime,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$_greeting,',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.neonLime,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$adminFirstName 👋',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textWhite,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tr('dashboard_whats_happening'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right: Vertical Slogan
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: RichText(
                                  textAlign: TextAlign.right,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      height: 1.25,
                                      letterSpacing: 0.6,
                                    ),
                                    children: [
                                      TextSpan(text: "${tr('dashboard_slogan_line1')}\n", style: TextStyle(color: AppTheme.neonLime)),
                                      TextSpan(text: "${tr('dashboard_slogan_line2')}\n", style: const TextStyle(color: Colors.white)),
                                      TextSpan(text: "${tr('dashboard_slogan_line3')}\n", style: const TextStyle(color: Colors.white)),
                                      TextSpan(text: tr('dashboard_slogan_line4'), style: TextStyle(color: AppTheme.neonLime)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Quick Actions Grid (4 Cards)
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.person_add_alt_1_rounded,
                                  label: tr('dashboard_add_member'),
                                  badgeColor: const Color(0xFF132B1A),
                                  iconColor: AppTheme.neonLime,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
                                    );
                                    _loadDashboardData();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.credit_card_rounded,
                                  label: tr('dashboard_record_fee'),
                                  badgeColor: const Color(0xFF102138),
                                  iconColor: const Color(0xFF389BF2),
                                  onTap: () => widget.onNavigateToMembers('All'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.event_note_rounded,
                                  label: tr('dashboard_events'),
                                  badgeColor: const Color(0xFF261536),
                                  iconColor: const Color(0xFFA855F7),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const EventsCalendarScreen()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.people_alt_rounded,
                                  label: tr('dashboard_trainers'),
                                  badgeColor: const Color(0xFF332014),
                                  iconColor: const Color(0xFFF97316),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TrainersListScreen()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // Section 1 Header: MEMBERSHIP METRICS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonLime,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('dashboard_membership_metrics'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => widget.onNavigateToMembers('All'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        tr('common_view_all'),
                                        style: TextStyle(
                                          color: AppTheme.neonLime,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.arrow_forward_rounded, color: AppTheme.neonLime, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 2x3 Metric Cards Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.15,
                            children: [
                              SummaryCard(
                                title: tr('dashboard_total_members'),
                                count: _totalMembers,
                                subtitle: tr('dashboard_all_registered_members'),
                                icon: Icons.people_alt_rounded,
                                accentColor: AppTheme.neonLime,
                                onTap: () => widget.onNavigateToMembers('All'),
                              ),
                              SummaryCard(
                                title: tr('dashboard_active_members'),
                                count: _activeMembers,
                                subtitle: tr('dashboard_currently_active'),
                                icon: Icons.check_circle_rounded,
                                accentColor: const Color(0xFF10B981),
                                onTap: () => widget.onNavigateToMembers('Active'),
                              ),
                              SummaryCard(
                                title: tr('dashboard_fees_due_soon'),
                                count: _feesDueSoon,
                                subtitle: tr('dashboard_in_next_7_days'),
                                icon: Icons.access_time_filled_rounded,
                                accentColor: const Color(0xFFF59E0B),
                                onTap: () => widget.onNavigateToMembers('Due Soon'),
                              ),
                              SummaryCard(
                                title: tr('dashboard_fees_due_today'),
                                count: _feesDueToday,
                                subtitle: tr('dashboard_due_today'),
                                icon: Icons.notifications_active_rounded,
                                accentColor: const Color(0xFFEAB308),
                                onTap: () => widget.onNavigateToMembers('Due Soon'),
                              ),
                              SummaryCard(
                                title: tr('dashboard_overdue_fees'),
                                count: _overdueFees,
                                subtitle: tr('dashboard_pending_payments'),
                                icon: Icons.warning_rounded,
                                accentColor: const Color(0xFFEF4444),
                                onTap: () => widget.onNavigateToMembers('Overdue'),
                              ),
                              SummaryCard(
                                title: tr('dashboard_expiring_soon'),
                                count: _expiringSoon,
                                subtitle: tr('dashboard_in_next_30_days'),
                                icon: Icons.access_time_rounded,
                                accentColor: const Color(0xFFA855F7),
                                onTap: () => widget.onNavigateToMembers('Due Soon'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Section 2 Header: RECENT ACTIVITY
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.neonLime,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('dashboard_recent_activity'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textMuted,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => widget.onNavigateToMembers('All'),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        tr('common_view_all'),
                                        style: TextStyle(
                                          color: AppTheme.neonLime,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.arrow_forward_rounded, color: AppTheme.neonLime, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Activity Content
                          if (_recentPayments.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161922).withValues(alpha: 0.90),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF222838), width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: AppTheme.textMuted,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    tr('dashboard_no_recent_activity'),
                                    style: const TextStyle(
                                      color: AppTheme.textWhite,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tr('dashboard_activity_will_appear'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.textMuted.withValues(alpha: 0.8),
                                      fontSize: 11.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _recentPayments.length,
                              itemBuilder: (context, index) {
                                final pay = _recentPayments[index];
                                final memberName = _memberNames[pay.memberId] ?? tr('dashboard_member_fallback');

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161922).withValues(alpha: 0.90),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF222838)),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.neonLime.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime, size: 20),
                                    ),
                                    title: Text(
                                      memberName,
                                      style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      tr('dashboard_receipt_line', {
                                        'number': pay.receiptNumber,
                                        'method': pay.paymentMethod,
                                        'date': dateFormat.format(pay.paymentDate),
                                      }),
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₹${pay.amount.toStringAsFixed(0)}',
                                          style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 15),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 18),
                                      ],
                                    ),
                                    onTap: () async {
                                      final receipt = await _paymentRepo.getReceiptByPaymentId(pay.id);
                                      if (receipt != null && context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: receipt)),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color badgeColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.badgeColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF161922).withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222838), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
