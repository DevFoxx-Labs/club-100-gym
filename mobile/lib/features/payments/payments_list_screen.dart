import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../core/services/app_state_service.dart';
import '../receipts/receipt_preview_screen.dart';

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
            p.receiptNumber.toLowerCase().contains(query) ||
            p.paymentMethod.toLowerCase().contains(query) ||
            p.amount.toString().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAYMENT TRANSACTIONS'),
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
                  hintText: 'Search by receipt number, method, amount...',
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
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
                  : _filteredPayments.isEmpty
                      ? const Center(
                          child: Text('No payment history found', style: TextStyle(color: AppTheme.textMuted)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _filteredPayments.length,
                          itemBuilder: (context, index) {
                            final pay = _filteredPayments[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () async {
                                  final nav = Navigator.of(context);
                                  final receipt = await _paymentRepo.getReceiptByPaymentId(pay.id);
                                  if (receipt != null) {
                                    nav.push(
                                      MaterialPageRoute(builder: (context) => ReceiptPreviewScreen(receipt: receipt)),
                                    );
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.neonLime.withValues(alpha: 0.15),
                                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.neonLime),
                                ),
                                title: Text(
                                  'Receipt: ${pay.receiptNumber}',
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '${pay.paymentMethod} • ${dateFormat.format(pay.paymentDate)}',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                trailing: Text(
                                  '₹${pay.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(color: AppTheme.neonLime, fontWeight: FontWeight.w900, fontSize: 16),
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

