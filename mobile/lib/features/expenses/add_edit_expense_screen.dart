import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/form_validators.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expenseRepo = ExpenseRepository();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  String _category = ExpenseCategories.all.first;
  String _paymentMethod = 'Cash';
  DateTime _expenseDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(text: expense != null ? expense.amount.toStringAsFixed(0) : '');
    _notesController = TextEditingController(text: expense?.notes ?? '');
    _category = expense?.category ?? ExpenseCategories.all.first;
    _paymentMethod = expense?.paymentMethod ?? 'Cash';
    _expenseDate = expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (widget.expense == null) {
      final expense = ExpenseModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        category: _category,
        amount: amount,
        expenseDate: _expenseDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: now,
        updatedAt: now,
      );
      await _expenseRepo.insert(expense);
    } else {
      final updated = widget.expense!.copyWith(
        title: _titleController.text.trim(),
        category: _category,
        amount: amount,
        expenseDate: _expenseDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim(),
        clearNotes: _notesController.text.trim().isEmpty,
      );
      await _expenseRepo.update(updated);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.expense != null;
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEdit ? 'EDIT EXPENSE' : 'ADD EXPENSE'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: 'Expense Title *',
                  hint: 'e.g. Electricity Bill - September',
                  controller: _titleController,
                  validator: (v) => FormValidators.validateName(v, fieldName: 'Expense title'),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Amount (₹) *',
                  hint: 'e.g. 4500',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => FormValidators.validateAmount(v, fieldName: 'Amount'),
                ),
                const SizedBox(height: 20),

                const Text(
                  'CATEGORY',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      isExpanded: true,
                      dropdownColor: AppTheme.darkSurface,
                      style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w700),
                      items: ExpenseCategories.all
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'PAYMENT METHOD',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Other'].map((m) {
                    final selected = _paymentMethod == m;
                    return FilterChip(
                      selected: selected,
                      label: Text(m),
                      selectedColor: AppTheme.neonLime,
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: TextStyle(
                        color: selected ? AppTheme.darkBackground : AppTheme.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (val) => setState(() => _paymentMethod = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                const Text(
                  'EXPENSE DATE',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expenseDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppTheme.neonLime,
                            onPrimary: AppTheme.darkBackground,
                            surface: AppTheme.darkSurface,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _expenseDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.darkBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppTheme.neonLime, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          dateFormat.format(_expenseDate),
                          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'Any additional details...',
                  controller: _notesController,
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                NeonButton(
                  text: isEdit ? 'Update Expense' : 'Save Expense',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _saveExpense,
                ),
                SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
