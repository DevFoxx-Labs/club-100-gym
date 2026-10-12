import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../shared/navigation/main_navigation_screen.dart';
import '../../shared/widgets/neon_button.dart';

class ChangeMpinScreen extends StatefulWidget {
  /// Forgot-MPIN flow: identity was already verified (account password or
  /// fingerprint), so the current MPIN is skipped and, once saved, the admin
  /// goes straight to the dashboard.
  final bool resetMode;

  const ChangeMpinScreen({super.key, this.resetMode = false});

  @override
  State<ChangeMpinScreen> createState() => _ChangeMpinScreenState();
}

class _ChangeMpinScreenState extends State<ChangeMpinScreen> {
  final _security = SecurityService();
  String _oldMpin = '';
  String _newMpin = '';
  String _confirmMpin = '';
  late int _step = widget.resetMode ? 1 : 0; // 0: Old MPIN, 1: New MPIN, 2: Confirm
  String? _errorMsg;

  void _onKeyPress(String digit) {
    setState(() {
      _errorMsg = null;
      if (_step == 0) {
        if (_oldMpin.length < 6) _oldMpin += digit;
      } else if (_step == 1) {
        if (_newMpin.length < 6) _newMpin += digit;
      } else {
        if (_confirmMpin.length < 6) _confirmMpin += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMsg = null;
      if (_step == 0) {
        if (_oldMpin.isNotEmpty) _oldMpin = _oldMpin.substring(0, _oldMpin.length - 1);
      } else if (_step == 1) {
        if (_newMpin.isNotEmpty) _newMpin = _newMpin.substring(0, _newMpin.length - 1);
      } else {
        if (_confirmMpin.isNotEmpty) _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
      }
    });
  }

  Future<void> _proceed() async {
    if (_step == 0) {
      final valid = await _security.verifyMPIN(_oldMpin);
      if (!mounted) return;
      if (valid) {
        setState(() => _step = 1);
      } else {
        setState(() {
          _errorMsg = 'Current MPIN is incorrect.';
          _oldMpin = '';
        });
      }
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else {
      if (_confirmMpin != _newMpin) {
        setState(() {
          _errorMsg = tr('mpin_mismatch');
          _confirmMpin = '';
        });
        return;
      }
      await _security.setMPIN(_newMpin);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('mpin_updated'))));
      if (widget.resetMode) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _step == 0 ? _oldMpin : (_step == 1 ? _newMpin : _confirmMpin);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resetMode ? tr('mpin_reset_title') : 'CHANGE SECURITY MPIN'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.paddingOf(context).bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32 - MediaQuery.paddingOf(context).bottom),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          _step == 0 ? 'Enter Current MPIN' : (_step == 1 ? tr('mpin_enter_new') : tr('mpin_confirm_new')),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final isFilled = index < currentInput.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled ? AppTheme.neonLime : AppTheme.darkBackground,
                                border: Border.all(color: isFilled ? AppTheme.neonLime : AppTheme.darkBorder, width: 2),
                              ),
                            );
                          }),
                        ),
                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorMsg!, style: const TextStyle(color: AppTheme.statusOverdue, fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        for (var row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['', '0', 'DEL']
                        ])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: row.map((key) {
                                if (key == '') return const SizedBox(width: 70, height: 54);
                                if (key == 'DEL') {
                                  return IconButton(onPressed: _onBackspace, icon: const Icon(Icons.backspace_outlined, color: AppTheme.textWhite));
                                }
                                return InkWell(
                                  onTap: () => _onKeyPress(key),
                                  child: Container(
                                    width: 70,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.darkBorder)),
                                    child: Text(key, style: const TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.w900)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 16),
                        NeonButton(
                          text: _step == 0 ? 'Verify MPIN →' : (_step == 1 ? tr('common_next') : tr('mpin_save_new')),
                          width: double.infinity,
                          onPressed: currentInput.length >= 4 ? _proceed : null,
                        ),
                      ],
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

