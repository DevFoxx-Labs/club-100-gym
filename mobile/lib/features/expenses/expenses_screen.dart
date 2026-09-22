import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import 'add_edit_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _expenseRepo = ExpenseRepository();

  bool _isLoading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _selectedCategory = 'All';
  List<ExpenseModel> _expenses = [];
  double _monthTotal = 0;
  double _allTimeTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    AppStateService.instance.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    AppStateService.instance.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted && AppStateService.instance.lastEventType == AppStateEventType.expensesChanged) {
      _loadExpenses(showSpinner: false);
    }
  }

  Future<void> _loadExpenses({bool showSpinner = true}) async {
    if (showSpinner) setState(() => _isLoading = true);

    final expenses = await _expenseRepo.getForMonth(_selectedMonth, category: _selectedCategory);
    final monthTotal = await _expenseRepo.getTotalForMonth(_selectedMonth);
    final allTimeTotal = await _expenseRepo.getTotalAllTime();

    if (mounted) {
      setState(() {
        _expenses = expenses;
        _monthTotal = monthTotal;
        _allTimeTotal = allTimeTotal;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadExpenses();
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _loadExpenses();
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: 'Delete Expense',
        message: 'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
        confirmLabel: 'Delete',
        isDestructive: true,
      ),
    );
    if (confirmed == true) {
      await _expenseRepo.delete(expense.id);
      _loadExpenses();
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_work_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      case 'Salaries & Wages':
        return Icons.badge_rounded;
      case 'Equipment':
        return Icons.fitness_center_rounded;
      case 'Maintenance':
        return Icons.build_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Supplies':
        return Icons.inventory_2_rounded;
      case 'Insurance':
        return Icons.shield_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy');
    final dateFormat = DateFormat('dd MMM yyyy');
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final categories = ['All', ...ExpenseCategories.all];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EXPENSE TRACKER'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.neonLime,
        foregroundColor: AppTheme.darkBackground,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w900)),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditExpenseScreen()),
          );
          if (result == true) _loadExpenses();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : RefreshIndicator(
                color: AppTheme.neonLime,
                onRefresh: _loadExpenses,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, safeBottom + 108),
                  children: [
                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.darkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THIS MONTH',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${_monthTotal.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.statusOverdue, fontWeight: FontWeight.w900, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.darkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ALL TIME',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10.5, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₹${_allTimeTotal.toStringAsFixed(0)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w900, fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Month Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textWhite),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Expanded(
                            child: Text(
                              monthFormat.format(_selectedMonth),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textWhite),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((c) {
                          final selected = _selectedCategory == c;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: selected,
                              label: Text(c),
                              selectedColor: AppTheme.neonLime,
                              backgroundColor: AppTheme.darkSurface,
                              labelStyle: TextStyle(
                                color: selected ? AppTheme.darkBackground : AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                              onSelected: (_) => _onCategorySelected(c),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_expenses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 56),
                            const SizedBox(height: 12),
                            const Text(
                              'No expenses recorded for this period',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._expenses.map((expense) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.darkBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusOverdue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_categoryIcon(expense.category), color: AppTheme.statusOverdue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              expense.category,
                                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
                                            ),
                                          ),
                                          Text(
                                            '${expense.paymentMethod} • ${dateFormat.format(expense.expenseDate)}',
                                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                                          ),
                                        ],
                                      ),
                                      if (expense.notes != null && expense.notes!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          expense.notes!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${expense.amount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppTheme.statusOverdue, fontWeight: FontWeight.w900, fontSize: 15),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMuted, size: 18),
                                      color: AppTheme.darkSurface,
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          final result = await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: expense)),
                                          );
                                          if (result == true) _loadExpenses();
                                        } else if (val == 'delete') {
                                          _deleteExpense(expense);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_rounded, color: AppTheme.textWhite, size: 18),
                                              SizedBox(width: 10),
                                              Text('Edit', style: TextStyle(color: AppTheme.textWhite)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded, color: AppTheme.statusOverdue, size: 18),
                                              SizedBox(width: 10),
                                              Text('Delete', style: TextStyle(color: AppTheme.statusOverdue)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
      ),
    );
  }
}
