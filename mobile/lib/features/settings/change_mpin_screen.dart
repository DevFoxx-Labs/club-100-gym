import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../shared/widgets/neon_button.dart';

class ChangeMpinScreen extends StatefulWidget {
  const ChangeMpinScreen({super.key});

  @override
  State<ChangeMpinScreen> createState() => _ChangeMpinScreenState();
}

class _ChangeMpinScreenState extends State<ChangeMpinScreen> {
  final _security = SecurityService();
  String _oldMpin = '';
  String _newMpin = '';
  int _step = 0; // 0: Old MPIN, 1: New MPIN
  String? _errorMsg;

  void _onKeyPress(String digit) {
    setState(() {
      _errorMsg = null;
      if (_step == 0) {
        if (_oldMpin.length < 6) _oldMpin += digit;
      } else {
        if (_newMpin.length < 6) _newMpin += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMsg = null;
      if (_step == 0) {
        if (_oldMpin.isNotEmpty) _oldMpin = _oldMpin.substring(0, _oldMpin.length - 1);
      } else {
        if (_newMpin.isNotEmpty) _newMpin = _newMpin.substring(0, _newMpin.length - 1);
      }
    });
  }

  Future<void> _proceed() async {
    if (_step == 0) {
      final valid = await _security.verifyMPIN(_oldMpin);
      if (valid) {
        setState(() => _step = 1);
      } else {
        setState(() {
          _errorMsg = 'Current MPIN is incorrect.';
          _oldMpin = '';
        });
      }
    } else {
      await _security.setMPIN(_newMpin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security MPIN updated successfully!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _step == 0 ? _oldMpin : _newMpin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHANGE SECURITY MPIN'),
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
                          _step == 0 ? 'Enter Current MPIN' : 'Enter New MPIN',
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
                          text: _step == 0 ? 'Verify MPIN →' : 'Save New MPIN',
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

