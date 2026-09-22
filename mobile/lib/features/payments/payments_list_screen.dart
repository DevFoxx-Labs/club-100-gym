import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../core/services/app_state_service.dart';
import '../receipts/receipt_preview_screen.dart';
import 'select_member_for_payment_screen.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  final _paymentRepo = PaymentRepository();
  final _searchController = TextEditingController();

  List<PaymentModel> _allPayments = [];
  List<PaymentModel> _filteredPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _searchController.addListener(_filterPayments);
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
      _loadPayments(showSpinner: false);
    }
  }

  Future<void> _loadPayments({bool showSpinner = true}) async {
    if (showSpinner || _allPayments.isEmpty) {
      setState(() => _isLoading = true);
    }
    final payments = await _paymentRepo.getPayments();
    if (mounted) {
      setState(() {
        _allPayments = payments;
        _filteredPayments = payments;
        _isLoading = false;
      });
      _filterPayments();
    }
  }

  void _filterPayments() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredPayments = _allPayments.where((p) {
        return query.isEmpty ||
            (p.memberName != null && p.memberName!.toLowerCase().contains(query)) ||
            (p.planName != null && p.planName!.toLowerCase().contains(query)) ||
            p.receiptNumber.toLowerCase().contains(query) ||
            p.paymentMethod.toLowerCase().contains(query) ||
            p.amount.toString().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAYMENT TRANSACTIONS'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SelectMemberForPaymentScreen()),
          );
        },
        backgroundColor: AppTheme.neonLime,
        foregroundColor: AppTheme.darkBackground,
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD PAYMENT', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by member name, receipt no, method...',
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
                  : _filteredPayments.isEmpty
                      ? const Center(
                          child: Text('No payment history found', style: TextStyle(color: AppTheme.textMuted)),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(20, 10, 20, safeBottom + 108),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final pay = _filteredPayments[index];
                            final memberName = (pay.memberName != null && pay.memberName!.trim().isNotEmpty)
                                ? pay.memberName!.trim()
                                : 'Gym Member';
                            final initialLetter = memberName.isNotEmpty ? memberName[0].toUpperCase() : 'M';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () async {
                                  final nav = Navigator.of(context);
                                  final receipt = await _paymentRepo.getReceiptByPaymentId(pay.id);
                                  if (receipt != null && mounted) {
                                    nav.push(
                                      MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: receipt)),
                                    );
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.neonLime.withValues(alpha: 0.15),
                                  child: Text(
                                    initialLetter,
                                    style: TextStyle(
                                      color: AppTheme.neonLime,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  memberName,
                                  style: const TextStyle(
                                    color: AppTheme.textWhite,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonLime.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.neonLime.withValues(alpha: 0.35), width: 0.8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.receipt_rounded, color: AppTheme.neonLime, size: 12),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Receipt #${pay.receiptNumber}',
                                                style: TextStyle(
                                                  color: AppTheme.neonLime,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (pay.planName != null && pay.planName!.trim().isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              pay.planName!.trim(),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pay.paymentMethod} • ${dateFormat.format(pay.paymentDate)}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '₹${pay.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppTheme.neonLime,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
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

