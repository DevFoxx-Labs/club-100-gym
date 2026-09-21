import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../shared/widgets/neon_button.dart';
import 'biometric_setup_screen.dart';

class MpinSetupScreen extends StatefulWidget {
  final String gymName;
  final String ownerName;
  final String gymPhone;
  final String email;
  final String address;
  final String city;
  final String currency;
  final String adminName;
  final String adminPhone;

  const MpinSetupScreen({
    super.key,
    required this.gymName,
    required this.ownerName,
    required this.gymPhone,
    required this.email,
    required this.address,
    required this.city,
    required this.currency,
    required this.adminName,
    required this.adminPhone,
  });

  @override
  State<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends State<MpinSetupScreen> {
  String _mpin = '';
  String _confirmMpin = '';
  bool _isConfirming = false;
  String? _errorMsg;

  void _onKeyPress(String digit) {
    setState(() {
      _errorMsg = null;
      if (!_isConfirming) {
        if (_mpin.length < 6) _mpin += digit;
      } else {
        if (_confirmMpin.length < 6) _confirmMpin += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMsg = null;
      if (!_isConfirming) {
        if (_mpin.isNotEmpty) _mpin = _mpin.substring(0, _mpin.length - 1);
      } else {
        if (_confirmMpin.isNotEmpty) _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
      }
    });
  }

  Future<void> _proceed() async {
    if (!_isConfirming) {
      if (_mpin.length < 4) {
        setState(() => _errorMsg = 'MPIN must be at least 4 digits');
        return;
      }
      setState(() => _isConfirming = true);
    } else {
      if (_mpin != _confirmMpin) {
        setState(() {
          _errorMsg = 'MPINs do not match. Please try again.';
          _confirmMpin = '';
        });
        return;
      }

      // Save encrypted MPIN hash
      final security = SecurityService();
      await security.setMPIN(_mpin);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BiometricSetupScreen(
            gymName: widget.gymName,
            ownerName: widget.ownerName,
            gymPhone: widget.gymPhone,
            email: widget.email,
            address: widget.address,
            city: widget.city,
            currency: widget.currency,
            adminName: widget.adminName,
            adminPhone: widget.adminPhone,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _isConfirming ? _confirmMpin : _mpin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('STEP 3 OF 4: MPIN SETUP'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    _isConfirming ? 'Confirm Security MPIN' : 'Create Security MPIN',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isConfirming
                        ? 'Re-enter your MPIN to confirm authentication credentials.'
                        : 'Enter a 4 to 6 digit security MPIN to lock application data.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 30),

                  // MPIN Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFilled = index < currentInput.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppTheme.neonLime : AppTheme.darkBackground,
                          border: Border.all(
                            color: isFilled ? AppTheme.neonLime : AppTheme.darkBorder,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMsg != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMsg!,
                      style: const TextStyle(color: AppTheme.statusOverdue, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              // Custom Keypad Grid
              Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                    ['', '0', 'DEL']
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row.map((key) {
                          if (key == '') return const SizedBox(width: 70, height: 60);
                          if (key == 'DEL') {
                            return IconButton(
                              onPressed: _onBackspace,
                              icon: const Icon(Icons.backspace_outlined, color: AppTheme.textWhite),
                              iconSize: 26,
                            );
                          }
                          return InkWell(
                            onTap: () => _onKeyPress(key),
                            borderRadius: BorderRadius.circular(35),
                            child: Container(
                              width: 70,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.darkSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.darkBorder),
                              ),
                              child: Text(
                                key,
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 20),

                  NeonButton(
                    text: _isConfirming ? 'Confirm & Next →' : 'Continue →',
                    width: double.infinity,
                    onPressed: currentInput.length >= 4 ? _proceed : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

