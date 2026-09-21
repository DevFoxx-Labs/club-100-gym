import 'dart:io';
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
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppTheme.neonLime),
          tooltip: 'Open Menu',
          onPressed: widget.onOpenDrawer,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (_gymInfo?.name ?? 'CLUB 100 THE GYM').toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
            ),
            const Text(
              'Admin Operations Dashboard',
              style: TextStyle(fontSize: 11, color: AppTheme.neonLime, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textWhite),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppTheme.neonLime,
          backgroundColor: AppTheme.darkSurface,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Welcome Banner with Gym Logo
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonLime.withValues(alpha: 0.08),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_greeting${_admin?.name != null && _admin!.name.isNotEmpty ? ', ${_admin!.name.split(' ').first}' : ''}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.neonLime, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _gymInfo?.name ?? 'Club 100 The Gym',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Tap cards below to filter members',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (_gymInfo?.logoPath != null && File(_gymInfo!.logoPath!).existsSync())
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_gymInfo!.logoPath!),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.neonLime.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.4)),
                                ),
                                child: const Icon(Icons.fitness_center_rounded, color: AppTheme.neonLime, size: 22),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Quick Actions Grid (4 options)
                      const Text(
                        'QUICK ACTIONS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.person_add_alt_1_rounded,
                              label: 'Add Member',
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
                            child: _QuickActionButton(
                              icon: Icons.payments_outlined,
                              label: 'Record Fee',
                              onTap: () => widget.onNavigateToMembers('All'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.event_note_rounded,
                              label: 'Events',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EventsCalendarScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickActionButton(
                              icon: Icons.sports_gymnastics_rounded,
                              label: 'Trainers',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TrainersListScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      const Text(
                        'MEMBERSHIP METRICS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),

                      // 2x3 Metric Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.98,
                        children: [
                          SummaryCard(
                            title: 'Total Members',
                            count: _totalMembers,
                            icon: Icons.people_alt_rounded,
                            accentColor: AppTheme.textWhite,
                            onTap: () => widget.onNavigateToMembers('All'),
                          ),
                          SummaryCard(
                            title: 'Active Members',
                            count: _activeMembers,
                            icon: Icons.check_circle_rounded,
                            accentColor: AppTheme.statusActive,
                            onTap: () => widget.onNavigateToMembers('Active'),
                          ),
                          SummaryCard(
                            title: 'Fees Due Soon',
                            count: _feesDueSoon,
                            icon: Icons.access_time_rounded,
                            accentColor: AppTheme.statusDueSoon,
                            onTap: () => widget.onNavigateToMembers('Due Soon'),
                          ),
                          SummaryCard(
                            title: 'Fees Due Today',
                            count: _feesDueToday,
                            icon: Icons.notifications_active_rounded,
                            accentColor: Colors.amber,
                            onTap: () => widget.onNavigateToMembers('Due Soon'),
                          ),
                          SummaryCard(
                            title: 'Overdue Fees',
                            count: _overdueFees,
                            icon: Icons.warning_rounded,
                            accentColor: AppTheme.statusOverdue,
                            onTap: () => widget.onNavigateToMembers('Overdue'),
                          ),
                          SummaryCard(
                            title: 'Expiring Soon',
                            count: _expiringSoon,
                            icon: Icons.timelapse_rounded,
                            accentColor: Colors.orangeAccent,
                            onTap: () => widget.onNavigateToMembers('Due Soon'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Payments Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'RECENT PAYMENTS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                          ),
                          TextButton(
                            onPressed: () => widget.onNavigateToMembers('All'),
                            child: const Text('View All', style: TextStyle(color: AppTheme.neonLime, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_recentPayments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: const Center(
                            child: Text(
                              'No payments recorded yet',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentPayments.length,
                          itemBuilder: (context, index) {
                            final pay = _recentPayments[index];
                            final memberName = _memberNames[pay.memberId] ?? 'Member';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.darkBorder),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.neonLime.withValues(alpha: 0.15),
                                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime, size: 20),
                                ),
                                title: Text(
                                  memberName,
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${pay.paymentMethod} • ${dateFormat.format(pay.paymentDate)}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${pay.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 15),
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
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.darkSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.neonLime, size: 22),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
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
