import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/form_validators.dart';
import '../../core/services/app_state_service.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _settingsRepo = SettingsRepository();

  late TextEditingController _upiIdController;
  late TextEditingController _upiPayeeNameController;
  late TextEditingController _bankAccountHolderController;
  late TextEditingController _bankAccountNumberController;
  late TextEditingController _bankIfscController;
  late TextEditingController _bankNameController;

  GymInfoModel? _gymInfo;
  bool _showUpiQrOnBill = true;
  bool _showBankDetailsOnBill = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _upiIdController = TextEditingController();
    _upiPayeeNameController = TextEditingController();
    _bankAccountHolderController = TextEditingController();
    _bankAccountNumberController = TextEditingController();
    _bankIfscController = TextEditingController();
    _bankNameController = TextEditingController();
    _loadGymInfo();
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _upiPayeeNameController.dispose();
    _bankAccountHolderController.dispose();
    _bankAccountNumberController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGymInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    if (mounted) {
      setState(() {
        _gymInfo = gym;
        _upiIdController.text = gym.upiId ?? '';
        _upiPayeeNameController.text = gym.upiPayeeName ?? '';
        _bankAccountHolderController.text = gym.bankAccountHolder ?? '';
        _bankAccountNumberController.text = gym.bankAccountNumber ?? '';
        _bankIfscController.text = gym.bankIfsc ?? '';
        _bankNameController.text = gym.bankName ?? '';
        _showUpiQrOnBill = gym.showUpiQrOnBill;
        _showBankDetailsOnBill = gym.showBankDetailsOnBill;
        _isLoading = false;
      });
    }
  }

  Future<void> _savePaymentSettings() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gymInfo == null) return;
    setState(() => _isSaving = true);

    final updated = _gymInfo!.copyWith(
      upiId: _upiIdController.text.trim().isNotEmpty ? _upiIdController.text.trim() : null,
      upiPayeeName: _upiPayeeNameController.text.trim().isNotEmpty ? _upiPayeeNameController.text.trim() : null,
      bankAccountHolder: _bankAccountHolderController.text.trim().isNotEmpty ? _bankAccountHolderController.text.trim() : null,
      bankAccountNumber: _bankAccountNumberController.text.trim().isNotEmpty ? _bankAccountNumberController.text.trim() : null,
      bankIfsc: _bankIfscController.text.trim().isNotEmpty ? _bankIfscController.text.trim().toUpperCase() : null,
      bankName: _bankNameController.text.trim().isNotEmpty ? _bankNameController.text.trim() : null,
      showUpiQrOnBill: _showUpiQrOnBill,
      showBankDetailsOnBill: _showBankDetailsOnBill,
      updatedAt: DateTime.now(),
    );

    await _settingsRepo.saveGymInfo(updated);
    AppStateService.instance.notifyGymInfoChanged();

    if (mounted) {
      setState(() {
        _gymInfo = updated;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment settings updated successfully')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('PAYMENT SETTINGS'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + (bottomInset > 0 ? bottomInset : safeBottom)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECEIVE PAYMENTS VIA UPI',
                        style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add your UPI ID to show a scan-to-pay QR on every bill with the amount pre-filled.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'UPI ID (VPA)',
                        hint: 'e.g. gymname@okhdfcbank',
                        controller: _upiIdController,
                        keyboardType: TextInputType.text,
                        validator: (v) => FormValidators.validateUpiId(v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Payee Name (shown to payer)',
                        hint: 'e.g. Elite Fitness Gym',
                        controller: _upiPayeeNameController,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _showUpiQrOnBill,
                        onChanged: (v) => setState(() => _showUpiQrOnBill = v),
                        activeThumbColor: AppTheme.neonLime,
                        title: const Text('Show UPI QR on Bill', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Members can scan and pay directly from the bill', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.darkBorder),
                      const SizedBox(height: 16),

                      Text(
                        'RECEIVE PAYMENTS VIA BANK TRANSFER',
                        style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Optionally show bank account details on the bill for direct transfers.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Account Holder Name',
                        controller: _bankAccountHolderController,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Account Number',
                        controller: _bankAccountNumberController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'IFSC Code',
                        hint: 'e.g. HDFC0001234',
                        controller: _bankIfscController,
                        validator: (v) => FormValidators.validateIfsc(v),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Bank Name',
                        controller: _bankNameController,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _showBankDetailsOnBill,
                        onChanged: (v) => setState(() => _showBankDetailsOnBill = v),
                        activeThumbColor: AppTheme.neonLime,
                        title: const Text('Show Bank Details on Bill', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Print account number & IFSC on printed/shared bills', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      ),
                      const SizedBox(height: 32),
                      NeonButton(
                        text: 'Save Payment Settings',
                        width: double.infinity,
                        isLoading: _isSaving,
                        onPressed: _savePaymentSettings,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
