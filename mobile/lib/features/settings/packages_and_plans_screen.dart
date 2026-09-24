import 'package:flutter/material.dart';
import '../../data/models/package_model.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../core/services/app_state_service.dart';
import 'package:intl/intl.dart';
import 'package_form_screen.dart';
import 'plan_form_screen.dart';
import '../../core/theme/app_theme.dart';

class PackagesAndPlansScreen extends StatefulWidget {
  const PackagesAndPlansScreen({super.key});

  @override
  State<PackagesAndPlansScreen> createState() => _PackagesAndPlansScreenState();
}

class _PackagesAndPlansScreenState extends State<PackagesAndPlansScreen> {
  final PackageRepository _packageRepo = PackageRepository();
  final PlanRepository _planRepo = PlanRepository();

  List<PackageModel> _packages = [];
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      _loadData(showSpinner: false);
    }
  }

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner || _packages.isEmpty) {
      setState(() => _isLoading = true);
    }
    final packages = await _packageRepo.getAllPackages();
    final plans = await _planRepo.getPlans(activeOnly: false);
    if (mounted) {
      setState(() {
        _packages = packages;
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePackage(PackageModel pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Package?',
        message: 'Are you sure you want to delete package "${pkg.name}"? Existing members on plans in this package will not be affected.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      await _packageRepo.deletePackage(pkg.id);
      _loadData();
    }
  }

  Future<void> _deletePlan(PlanModel plan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'Delete Plan?',
        message: 'Are you sure you want to delete "${plan.name}"? Existing member memberships will keep their historical record.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirm == true) {
      await _planRepo.deletePlan(plan.id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'PACKAGES & PLANS',
          style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: AppTheme.neonLime),
            tooltip: 'Add Package',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PackageFormScreen()),
              );
              if (res == true) _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
          : RefreshIndicator(
              color: AppTheme.neonLime,
              backgroundColor: const Color(0xFF1E1E1E),
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 100 + MediaQuery.paddingOf(context).bottom),
                children: [
                  // Packages with nested plans
                  if (_packages.isEmpty && _plans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No packages or plans configured yet.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else ...[
                    ..._packages.map((pkg) {
                      final pkgPlans = _plans.where((p) => p.packageId == pkg.id).toList()
                        ..sort((a, b) => a.durationDays.compareTo(b.durationDays));
                      return _buildPackageCard(pkg, pkgPlans, currencyFormat);
                    }),
                    // Plans without a package
                    _buildStandalonePlansCard(
                      _plans.where((p) => p.packageId == null || !_packages.any((pkg) => pkg.id == p.packageId)).toList(),
                      currencyFormat,
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'packages_plans_fab',
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlanFormScreen()),
          );
          if (res == true) _loadData();
        },
        backgroundColor: AppTheme.neonLime,
        icon: const Icon(Icons.add, color: Color(0xFF121212)),
        label: const Text(
          'Add Plan',
          style: TextStyle(color: Color(0xFF121212), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageModel pkg, List<PlanModel> plans, NumberFormat currencyFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonLime.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppTheme.neonLime, size: 20),
          ),
          title: Text(
            pkg.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          subtitle: Text(
            pkg.description != null && pkg.description!.isNotEmpty
                ? pkg.description!
                : '${plans.length} duration tiers available',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppTheme.neonLime, size: 20),
                tooltip: 'Add plan to this package',
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlanFormScreen(initialPackageId: pkg.id)),
                  );
                  if (res == true) _loadData();
                },
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1E1E1E),
                onSelected: (val) async {
                  if (val == 'edit') {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PackageFormScreen(package: pkg)),
                    );
                    if (res == true) _loadData();
                  } else if (val == 'delete') {
                    _deletePackage(pkg);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Package', style: TextStyle(color: Colors.white))),
                  const PopupMenuItem(value: 'delete', child: Text('Delete Package', style: TextStyle(color: Color(0xFFFF5252)))),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1, color: Color(0xFF252525)),
            if (plans.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'No plans added under this package yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PlanFormScreen(initialPackageId: pkg.id)),
                        );
                        if (res == true) _loadData();
                      },
                      icon: Icon(Icons.add, size: 16, color: AppTheme.neonLime),
                      label: Text('Add Plan', style: TextStyle(color: AppTheme.neonLime, fontSize: 12)),
                    ),
                  ],
                ),
              )
            else
              ...plans.map((p) => _buildPlanRow(p, currencyFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildStandalonePlansCard(List<PlanModel> plans, NumberFormat currencyFormat) {
    if (plans.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white70, size: 20),
          ),
          title: const Text(
            'General Membership Plans',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          subtitle: Text(
            '${plans.length} standalone plans',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFF252525)),
            ...plans.map((p) => _buildPlanRow(p, currencyFormat)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRow(PlanModel plan, NumberFormat currencyFormat) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              plan.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Text(
            currencyFormat.format(plan.defaultFee),
            style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
      subtitle: Text(
        '${plan.durationDays} Days${plan.description != null && plan.description!.isNotEmpty ? ' · ${plan.description}' : ''}',
        style: const TextStyle(color: Colors.white60, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white60),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PlanFormScreen(plan: plan)),
              );
              if (res == true) _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFFF5252)),
            onPressed: () => _deletePlan(plan),
          ),
        ],
      ),
    );
  }
}

