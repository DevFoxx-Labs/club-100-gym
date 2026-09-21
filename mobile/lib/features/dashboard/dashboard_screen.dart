import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/models/gym_info_model.dart';
import 'widgets/summary_card.dart';
import '../members/add_edit_member_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String filter) onNavigateToMembers;

  const DashboardScreen({super.key, required this.onNavigateToMembers});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _memberRepo = MemberRepository();
  final _settingsRepo = SettingsRepository();

  bool _isLoading = true;
  GymInfoModel? _gymInfo;

  int _totalMembers = 0;
  int _activeMembers = 0;
  int _feesDueSoon = 0;
  int _feesDueToday = 0;
  int _overdueFees = 0;
  int _expiringSoon = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final gym = await _settingsRepo.getGymInfo();
    final members = await _memberRepo.getMembers();

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

    setState(() {
      _gymInfo = gym;
      _totalMembers = members.length;
      _activeMembers = active;
      _feesDueSoon = dueSoon;
      _feesDueToday = dueToday;
      _overdueFees = overdue;
      _expiringSoon = expiring;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (_gymInfo?.name ?? 'CLUB 100 THE GYM').toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Welcome Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(24),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OVERVIEW SUMMARY',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.neonLime, letterSpacing: 1),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Gym Operations',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Tap any card below to view details',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                            FloatingActionButton.small(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
                                );
                                _loadDashboardData();
                              },
                              backgroundColor: AppTheme.neonLime,
                              foregroundColor: AppTheme.darkBackground,
                              child: const Icon(Icons.person_add_alt_1_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'MEMBERSHIP METRICS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),

                      // 2x3 Metric Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.25,
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

                      // Quick Action Shortcuts
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
                                  );
                                  _loadDashboardData();
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Icon(Icons.person_add_rounded, color: AppTheme.neonLime, size: 24),
                                      SizedBox(height: 6),
                                      Text('Add Member', style: TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.darkBorder),
                            Expanded(
                              child: InkWell(
                                onTap: () => widget.onNavigateToMembers('All'),
                                borderRadius: BorderRadius.circular(14),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      Icon(Icons.payment_rounded, color: AppTheme.neonLime, size: 24),
                                      SizedBox(height: 6),
                                      Text('Record Fee', style: TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

