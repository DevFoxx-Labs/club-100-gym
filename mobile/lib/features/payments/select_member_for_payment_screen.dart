import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../shared/widgets/member_avatar.dart';
import 'add_payment_screen.dart';

/// Lets the admin pick a member directly from the Payments screen (via the FAB)
/// so a payment can be recorded without navigating through the member profile.
class SelectMemberForPaymentScreen extends StatefulWidget {
  const SelectMemberForPaymentScreen({super.key});

  @override
  State<SelectMemberForPaymentScreen> createState() => _SelectMemberForPaymentScreenState();
}

class _SelectMemberForPaymentScreenState extends State<SelectMemberForPaymentScreen> {
  final _memberRepo = MemberRepository();
  final _searchController = TextEditingController();

  List<MemberModel> _allMembers = [];
  List<MemberModel> _filteredMembers = [];
  bool _isLoading = true;
  String? _navigatingMemberId;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await _memberRepo.getMembers();
    if (mounted) {
      setState(() {
        _allMembers = members;
        _filteredMembers = members;
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((m) {
        return query.isEmpty || m.name.toLowerCase().contains(query) || m.phone.contains(query);
      }).toList();
    });
  }

  Future<void> _onMemberSelected(MemberModel member) async {
    setState(() => _navigatingMemberId = member.id);
    final membership = await _memberRepo.getLatestMembership(member.id);
    if (!mounted) return;
    setState(() => _navigatingMemberId = null);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPaymentScreen(member: member, membership: membership),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT MEMBER'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by member name or phone...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : _filteredMembers.isEmpty
                      ? const Center(
                          child: Text('No members found', style: TextStyle(color: AppTheme.textMuted)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottom + 24),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final isNavigating = _navigatingMemberId == member.id;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                enabled: _navigatingMemberId == null,
                                onTap: () => _onMemberSelected(member),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: MemberAvatar(name: member.name, photoPath: member.photoPath),
                                title: Text(
                                  member.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 15.5),
                                ),
                                subtitle: Text(
                                  member.phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                                ),
                                trailing: isNavigating
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: AppTheme.neonLime, strokeWidth: 2.4),
                                      )
                                    : const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
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
