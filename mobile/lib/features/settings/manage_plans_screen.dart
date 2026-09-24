import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/plan_model.dart';
import '../../data/repositories/plan_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class ManagePlansScreen extends StatefulWidget {
  const ManagePlansScreen({super.key});

  @override
  State<ManagePlansScreen> createState() => _ManagePlansScreenState();
}

class _ManagePlansScreenState extends State<ManagePlansScreen> {
  final _planRepo = PlanRepository();
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final plans = await _planRepo.getPlans(activeOnly: false);
    if (mounted) {
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    }
  }

  void _showAddEditPlanModal({PlanModel? plan}) {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final durationController = TextEditingController(text: plan?.durationDays.toString() ?? '30');
    final feeController = TextEditingController(text: plan?.defaultFee.toStringAsFixed(0) ?? '1500');
    final descController = TextEditingController(text: plan?.description ?? '');

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + (bottomInset > 0 ? bottomInset + 12 : 24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan == null ? 'ADD MEMBERSHIP PLAN' : 'EDIT PLAN',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                ),
                const SizedBox(height: 16),
                CustomTextField(label: 'Plan Name *', controller: nameController),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: CustomTextField(label: 'Duration (Days) *', controller: durationController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: CustomTextField(label: 'Default Fee (₹) *', controller: feeController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(label: 'Description', controller: descController, maxLines: 2),
                const SizedBox(height: 24),
                NeonButton(
                  text: 'Save Plan',
                  width: double.infinity,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    const uuid = Uuid();
                    final now = DateTime.now();

                    final newPlan = PlanModel(
                      id: plan?.id ?? uuid.v4(),
                      name: nameController.text.trim(),
                      durationDays: int.tryParse(durationController.text.trim()) ?? 30,
                      defaultFee: double.tryParse(feeController.text.trim()) ?? 1500.0,
                      description: descController.text.trim(),
                      createdAt: plan?.createdAt ?? now,
                      updatedAt: now,
                    );

                    if (plan == null) {
                      await _planRepo.addPlan(newPlan);
                    } else {
                      await _planRepo.updatePlan(newPlan);
                    }

                    nav.pop();
                    _loadPlans();
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      durationController.dispose();
      feeController.dispose();
      descController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEMBERSHIP PLANS'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppTheme.neonLime),
            onPressed: () => _showAddEditPlanModal(),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + MediaQuery.paddingOf(context).bottom),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final p = _plans[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(p.name, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${p.durationDays} Days • ₹${p.defaultFee.toStringAsFixed(0)}', style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.bold)),
                          if (p.description != null && p.description!.isNotEmpty)
                            Text(p.description!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.textWhite, size: 20),
                            onPressed: () => _showAddEditPlanModal(plan: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue, size: 20),
                            onPressed: () async {
                              await _planRepo.deletePlan(p.id);
                              _loadPlans();
                            },
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

