import 'package:flutter/material.dart';
import '../../data/models/member_model.dart';
import '../../data/repositories/member_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/member_avatar.dart';

class ArchivedMembersScreen extends StatefulWidget {
  const ArchivedMembersScreen({super.key});

  @override
  State<ArchivedMembersScreen> createState() => _ArchivedMembersScreenState();
}

class _ArchivedMembersScreenState extends State<ArchivedMembersScreen> {
  final MemberRepository _memberRepo = MemberRepository();
  List<MemberModel> _archivedMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchived();
  }

  Future<void> _loadArchived() async {
    setState(() => _isLoading = true);
    final members = await _memberRepo.getArchivedMembers();
    if (mounted) {
      setState(() {
        _archivedMembers = members;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreMember(MemberModel member) async {
    await _memberRepo.restoreMember(member.id);
    _loadArchived();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} has been restored to active members.'),
          backgroundColor: const Color(0xFF00E676),
        ),
      );
    }
  }

  Future<void> _hardDeleteMember(MemberModel member) async {
    final canDelete = await _memberRepo.canHardDelete(member.id);
    if (!canDelete) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text('Cannot Permanently Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Text(
              '${member.name} has payment and receipt records in the system. '
              'To protect accounting and tax audit integrity, members with financial history are kept in the archive and cannot be permanently wiped.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Understood', style: TextStyle(color: Color(0xFFD4FF00))),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Permanently?',
        message: 'This will permanently remove ${member.name} and cannot be undone.',
        confirmLabel: 'Delete Forever',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      await _memberRepo.hardDeleteMember(member.id);
      _loadArchived();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} permanently deleted.'),
            backgroundColor: const Color(0xFFFF5252),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'ARCHIVED MEMBERS',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4FF00)))
          : _archivedMembers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text(
                        'No archived members',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFD4FF00),
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: _loadArchived,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _archivedMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final member = _archivedMembers[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              MemberAvatar(
                                name: member.name,
                                photoPath: member.photoPath,
                                radius: 20,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      member.phone,
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _restoreMember(member),
                                icon: const Icon(Icons.restore, size: 16, color: Color(0xFFD4FF00)),
                                label: const Text('Restore', style: TextStyle(color: Color(0xFFD4FF00), fontSize: 12)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFFFF5252), size: 20),
                                tooltip: 'Delete forever',
                                onPressed: () => _hardDeleteMember(member),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

