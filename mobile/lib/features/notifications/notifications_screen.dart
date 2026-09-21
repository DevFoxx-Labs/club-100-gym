import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';
import '../members/member_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _memberRepo = MemberRepository();

  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final members = await _memberRepo.getMembers();
    final List<Map<String, dynamic>> reminders = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var m in members) {
      final ms = await _memberRepo.getLatestMembership(m.id);
      if (ms != null) {
        final endDate = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
        final diffDays = endDate.difference(today).inDays;

        if (diffDays < 0) {
          reminders.add({
            'member': m,
            'title': 'Fee Overdue Alert',
            'body': '${m.name} fee is overdue by ${diffDays.abs()} days (₹${ms.feeAmount.toStringAsFixed(0)}).',
            'type': 'OVERDUE',
            'date': endDate,
          });
        } else if (diffDays <= 7) {
          reminders.add({
            'member': m,
            'title': diffDays == 0 ? 'Fee Due Today' : 'Fee Due Soon ($diffDays Days)',
            'body': '${m.name} membership fee is due in $diffDays days.',
            'type': 'DUE',
            'date': endDate,
          });
        }
      }
    }

    setState(() {
      _reminders = reminders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCAL NOTIFICATIONS'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : _reminders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 50, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text("You're all caught up!", style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text('No pending fee dues or upcoming expiries.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final item = _reminders[index];
                      final member = item['member'] as MemberModel;
                      final isOverdue = item['type'] == 'OVERDUE';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MemberProfileScreen(memberId: member.id)),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundColor: (isOverdue ? AppTheme.statusOverdue : AppTheme.statusDueSoon).withValues(alpha: 0.15),
                            child: Icon(
                              isOverdue ? Icons.warning_rounded : Icons.notifications_active_rounded,
                              color: isOverdue ? AppTheme.statusOverdue : AppTheme.statusDueSoon,
                            ),
                          ),
                          title: Text(item['title'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(item['body'], style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

