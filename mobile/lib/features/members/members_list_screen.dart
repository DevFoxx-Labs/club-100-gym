import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member_model.dart';
import '../../data/models/membership_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../shared/widgets/status_badge.dart';
import 'add_edit_member_screen.dart';
import 'member_profile_screen.dart';

class MembersListScreen extends StatefulWidget {
  final String? initialFilter;

  const MembersListScreen({super.key, this.initialFilter});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _memberRepo = MemberRepository();
  final _searchController = TextEditingController();

  List<MemberModel> _allMembers = [];
  Map<String, MembershipModel?> _memberships = {};
  List<MemberModel> _filteredMembers = [];
  bool _isLoading = true;

  String _selectedTab = 'All'; // All, Active, Due Soon, Overdue, Expired

  @override
  void initState() {
    super.initState();
    if (widget.initialFilter != null) {
      _selectedTab = widget.initialFilter!;
    }
    _loadMembers();
    _searchController.addListener(_applyFilters);
  }

  @override
  void didUpdateWidget(covariant MembersListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() {
        _selectedTab = widget.initialFilter!;
      });
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    final members = await _memberRepo.getMembers();
    final Map<String, MembershipModel?> memberships = {};

    for (var m in members) {
      final ms = await _memberRepo.getLatestMembership(m.id);
      memberships[m.id] = ms;
    }

    setState(() {
      _allMembers = members;
      _memberships = memberships;
      _isLoading = false;
    });

    _applyFilters();
  }

  String _getMemberStatus(String memberId) {
    final ms = _memberships[memberId];
    if (ms == null) return 'No Plan';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(ms.endDate.year, ms.endDate.month, ms.endDate.day);
    final diffDays = endDate.difference(today).inDays;

    if (diffDays < 0) return 'Overdue by ${diffDays.abs()} days';
    if (diffDays == 0) return 'Fee Due Today';
    if (diffDays <= 7) return 'Due in $diffDays days';
    return 'Active';
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

        final status = _getMemberStatus(m.id).toLowerCase();

        if (_selectedTab == 'Active') {
          return !status.contains('overdue');
        } else if (_selectedTab == 'Due Soon') {
          return status.contains('due') || status.contains('expiring');
        } else if (_selectedTab == 'Overdue') {
          return status.contains('overdue');
        } else if (_selectedTab == 'Expired') {
          return status.contains('overdue');
        }

        return true; // All
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GYM MEMBERS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppTheme.neonLime),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEditMemberScreen()),
              );
              _loadMembers();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instant Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or ID...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filter Tabs Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: ['All', 'Active', 'Due Soon', 'Overdue', 'Expired'].map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(tab),
                      selectedColor: AppTheme.neonLime,
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.darkBackground : AppTheme.textWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedTab = tab);
                          _applyFilters();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // Members List View
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
                              const Text('No members found', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Add your first member to start managing your gym.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final status = _getMemberStatus(member.id);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MemberProfileScreen(memberId: member.id),
                                    ),
                                  );
                                  _loadMembers();
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.neonLime.withValues(alpha: 0.2),
                                  child: Text(
                                    member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                                    style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                title: Text(
                                  member.name,
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text(member.phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    StatusBadge(status: status),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

