import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/trainer_model.dart';
import '../../data/repositories/trainer_repository.dart';
import '../../core/services/app_state_service.dart';
import '../../shared/widgets/member_avatar.dart';
import 'trainer_detail_screen.dart';
import 'trainer_form_screen.dart';

class TrainersListScreen extends StatefulWidget {
  const TrainersListScreen({super.key});

  @override
  State<TrainersListScreen> createState() => _TrainersListScreenState();
}

class _TrainersListScreenState extends State<TrainersListScreen> {
  final TrainerRepository _repository = TrainerRepository();
  final _searchController = TextEditingController();

  List<TrainerModel> _trainers = [];
  List<TrainerModel> _filteredTrainers = [];
  bool _isLoading = true;
  String _selectedTab = 'All'; // All, Trainers, Staff, Active, Inactive

  @override
  void initState() {
    super.initState();
    _loadTrainers();
    _searchController.addListener(_applyFilters);
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadTrainers(showSpinner: false);
    }
  }

  Future<void> _loadTrainers({bool showSpinner = true}) async {
    if (showSpinner || _trainers.isEmpty) {
      setState(() => _isLoading = true);
    }
    final trainers = await _repository.getAllTrainers(includeInactive: true);
    if (mounted) {
      setState(() {
        _trainers = trainers;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredTrainers = _trainers.where((t) {
        final matchesQuery = query.isEmpty ||
            t.name.toLowerCase().contains(query) ||
            t.phone.contains(query) ||
            t.role.toLowerCase().contains(query) ||
            (t.specialization ?? '').toLowerCase().contains(query);

        if (!matchesQuery) return false;

        switch (_selectedTab) {
          case 'Trainers':
            return t.role == 'Trainer';
          case 'Staff':
            return t.role == 'Staff';
          case 'Active':
            return t.isActive;
          case 'Inactive':
            return !t.isActive;
          default:
            return true;
        }
      }).toList();
    });
  }

  /// Formats the join duration as e.g. "1 year 2 months", or "New" for < 1 month.
  String _joinedDuration(DateTime joined) {
    final now = DateTime.now();
    int totalMonths = (now.year - joined.year) * 12 + (now.month - joined.month);
    if (now.day < joined.day) totalMonths--;
    if (totalMonths < 1) return 'New';

    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    final parts = <String>[];
    if (years > 0) parts.add('$years ${years == 1 ? 'year' : 'years'}');
    if (months > 0) parts.add('$months ${months == 1 ? 'month' : 'months'}');
    return parts.join(' ');
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
              : (isSelected ? dotColor!.withValues(alpha: 0.18) : AppTheme.darkSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? (dotColor ?? AppTheme.neonLime) : Colors.white.withValues(alpha: 0.08),
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
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final safeBottomInset = MediaQuery.paddingOf(context).bottom;
    final listBottomPadding = safeBottomInset + 108.0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title & Total Staff Stat Card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
                            children: [
                              const TextSpan(text: 'TRAINERS & ', style: TextStyle(color: AppTheme.textWhite)),
                              TextSpan(text: 'STAFF', style: TextStyle(color: AppTheme.neonLime)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Manage your gym team',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
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
                          child: Icon(Icons.groups_rounded, color: AppTheme.neonLime, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_trainers.length}',
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                height: 1.1,
                              ),
                            ),
                            const Text(
                              'Total Staff',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
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
                          hintText: 'Search by name, phone, or role...',
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
                      tooltip: 'Filter',
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Filter Chips
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
                    label: 'Trainers',
                    icon: Icons.fitness_center_rounded,
                    isSelected: _selectedTab == 'Trainers',
                    onTap: () {
                      setState(() => _selectedTab = 'Trainers');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Staff',
                    icon: Icons.badge_outlined,
                    isSelected: _selectedTab == 'Staff',
                    onTap: () {
                      setState(() => _selectedTab = 'Staff');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Active',
                    dotColor: AppTheme.statusActive,
                    isSelected: _selectedTab == 'Active',
                    onTap: () {
                      setState(() => _selectedTab = 'Active');
                      _applyFilters();
                    },
                  ),
                  _buildFilterChip(
                    label: 'Inactive',
                    dotColor: AppTheme.statusOverdue,
                    isSelected: _selectedTab == 'Inactive',
                    onTap: () {
                      setState(() => _selectedTab = 'Inactive');
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),

            // Trainer List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : _filteredTrainers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppTheme.neonLime,
                          backgroundColor: AppTheme.darkSurface,
                          onRefresh: _loadTrainers,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(20, 8, 20, listBottomPadding),
                            itemCount: _filteredTrainers.length,
                            itemBuilder: (context, index) {
                              final trainer = _filteredTrainers[index];
                              return _buildTrainerCard(trainer, dateFormat);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
          );
          if (res == true) _loadTrainers();
        },
        backgroundColor: AppTheme.neonLime,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add, color: AppTheme.darkBackground, size: 22),
        label: const Text(
          'Add Trainer',
          style: TextStyle(color: AppTheme.darkBackground, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final noResultsFromSearch = _trainers.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noResultsFromSearch ? Icons.search_off_rounded : Icons.fitness_center_rounded,
              size: 48,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              noResultsFromSearch ? 'No matching staff found' : 'No trainers registered yet',
              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              noResultsFromSearch
                  ? 'Try a different search term or filter.'
                  : 'Add personal trainers and staff to track salaries, assign members, and record disbursements.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            if (!noResultsFromSearch) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
                  );
                  if (res == true) _loadTrainers();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonLime,
                  foregroundColor: AppTheme.darkBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add First Trainer', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerCard(TrainerModel trainer, DateFormat dateFormat) {
    final statusColor = trainer.isActive ? AppTheme.statusActive : AppTheme.statusOverdue;
    final joinedAt = DateTime.tryParse(trainer.createdAt) ?? DateTime.now();
    final tags = trainer.specializationTags;

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
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: trainer.id)),
          );
          if (res == true) _loadTrainers();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar with status dot, Name/Phone/Status, Menu & Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MemberAvatar(name: trainer.name, photoPath: trainer.photoPath, radius: 28, fontSize: 20),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.darkSurface, width: 2),
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
                          trainer.name,
                          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.call_outlined, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                trainer.phone,
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trainer.isActive ? Icons.check_circle_rounded : Icons.pause_circle_outline_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                trainer.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: AppTheme.darkCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        onSelected: (action) async {
                          if (action == 'edit') {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrainerFormScreen(trainer: trainer)),
                            );
                            if (res == true) _loadTrainers();
                          } else if (action == 'view') {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrainerDetailScreen(trainerId: trainer.id)),
                            );
                            if (res == true) _loadTrainers();
                          }
                        },
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
                                Text('Edit Trainer', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
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
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 20),
                      ),
                    ],
                  ),
                ],
              ),

              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.05)),
              ),

              // 3-column stats row: Role, Salary, Joined On
              Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.fitness_center_rounded,
                      label: 'Role',
                      value: trainer.role,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.06),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Salary',
                      value: trainer.monthlySalary != null ? '₹${trainer.monthlySalary!.toStringAsFixed(0)}/mo' : 'Not Set',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.06),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined On',
                      value: dateFormat.format(joinedAt),
                      subValue: '(${_joinedDuration(joinedAt)})',
                    ),
                  ),
                ],
              ),

              // Specialization Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.asMap().entries.map((entry) {
                    final isPrimary = entry.key == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isPrimary ? AppTheme.neonLime.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isPrimary ? AppTheme.neonLime.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isPrimary ? AppTheme.neonLime : AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700, fontSize: 12.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subValue != null) ...[
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w700, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
