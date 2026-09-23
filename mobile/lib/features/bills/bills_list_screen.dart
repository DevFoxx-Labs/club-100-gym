import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/bill_model.dart';
import '../../data/repositories/bill_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/status_badge.dart';
import 'bill_detail_screen.dart';

/// Embedded "Bills & Dues" list, shown as a tab within the Payments screen.
/// Tracks membership bills through their lifecycle: Pending -> Overdue -> Paid/Cancelled.
class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  final _billRepo = BillRepository();
  final _searchController = TextEditingController();

  List<BillModel> _allBills = [];
  List<BillModel> _filteredBills = [];
  String _statusFilter = 'Due';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBills();
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
      final type = AppStateService.instance.lastEventType;
      if (type == AppStateEventType.billsChanged || type == AppStateEventType.paymentsChanged || type == AppStateEventType.all) {
        _loadBills(showSpinner: false);
      }
    }
  }

  Future<void> _loadBills({bool showSpinner = true}) async {
    if (showSpinner || _allBills.isEmpty) {
      setState(() => _isLoading = true);
    }
    await _billRepo.refreshOverdueStatuses();
    final bills = await _billRepo.getBills();
    if (mounted) {
      setState(() {
        _allBills = bills;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  Future<void> _deleteCancelledBill(BillModel bill) async {
    await _billRepo.deleteCancelledBill(bill.id);
    AppStateService.instance.notifyBillsChanged();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredBills = _allBills.where((b) {
        final matchesStatus = switch (_statusFilter) {
          'Due' => b.isDue,
          'Overdue' => b.status == 'Overdue',
          'Paid' => b.isPaid,
          _ => true,
        };
        final matchesQuery = query.isEmpty ||
            b.memberName.toLowerCase().contains(query) ||
            b.billNumber.toLowerCase().contains(query) ||
            b.planName.toLowerCase().contains(query);
        return matchesStatus && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: tr('bills_search_hint'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Due', 'Overdue', 'Paid', 'All'].map((f) {
                final selected = _statusFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(tr('bills_filter_${f.toLowerCase()}')),
                    selectedColor: AppTheme.neonLime,
                    backgroundColor: AppTheme.darkSurface,
                    labelStyle: TextStyle(color: selected ? AppTheme.darkBackground : AppTheme.textWhite, fontWeight: FontWeight.bold),
                    onSelected: (val) {
                      setState(() => _statusFilter = f);
                      _applyFilters();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
              : _filteredBills.isEmpty
                  ? Center(
                      child: Text(tr('bills_none_found'), style: const TextStyle(color: AppTheme.textMuted)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottom + 108),
                      itemCount: _filteredBills.length,
                      itemBuilder: (context, index) {
                        final bill = _filteredBills[index];
                        final card = Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BillDetailScreen(bill: bill)),
                              );
                              _loadBills(showSpinner: false);
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              bill.memberName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 15.5),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    StatusBadge(status: bill.status, label: tr('bill_status_${bill.status.toLowerCase()}')),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tr('bills_due_row', {'date': dateFormat.format(bill.dueDate)}),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr('bills_number_plan_row', {'number': bill.billNumber, 'plan': bill.planName}),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                            trailing: Text(
                              '₹${bill.amount.toStringAsFixed(0)}',
                              style: TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                        );

                        if (!bill.isCancelled) return card;

                        return Dismissible(
                          key: ValueKey(bill.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.statusOverdue.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => ConfirmationDialog(
                                title: tr('bill_detail_delete_title'),
                                message: tr('bill_detail_delete_message'),
                                confirmText: tr('common_delete'),
                                isDestructive: true,
                              ),
                            );
                          },
                          onDismissed: (direction) => _deleteCancelledBill(bill),
                          child: card,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
