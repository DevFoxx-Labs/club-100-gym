import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/security_service.dart';
import '../../shared/widgets/neon_button.dart';
import 'biometric_setup_screen.dart';

class MpinSetupScreen extends StatefulWidget {
  final String gymName;
  final String? ownerName;
  final String? gymPhone;
  final String? email;
  final String? website;
  final String? address;
  final String? city;
  final String? currency;
  final String adminName;
  final String? adminPhone;
  final bool restoreMode;

  const MpinSetupScreen({
    super.key,
    required this.gymName,
    required this.ownerName,
    required this.gymPhone,
    required this.email,
    this.website,
    required this.address,
    required this.city,
    required this.currency,
    required this.adminName,
    required this.adminPhone,
    this.restoreMode = false,
  });

  const MpinSetupScreen.restore({
    super.key,
    required this.gymName,
    required this.adminName,
  })  : ownerName = null,
        gymPhone = null,
        email = null,
        website = null,
        address = null,
        city = null,
        currency = null,
        adminPhone = null,
        restoreMode = true;

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
        if (_mpin.length < SecurityService.mpinLength) _mpin += digit;
      } else {
        if (_confirmMpin.length < SecurityService.mpinLength) _confirmMpin += digit;
      }
    });
    // All 4 digits entered: move on without an extra tap.
    final current = _isConfirming ? _confirmMpin : _mpin;
    if (current.length == SecurityService.mpinLength) _proceed();
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
      if (_mpin.length != SecurityService.mpinLength) {
        setState(() => _errorMsg = tr('mpin_must_be_4'));
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
      if (widget.restoreMode) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen.restore(
              gymName: widget.gymName,
              adminName: widget.adminName,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BiometricSetupScreen(
              gymName: widget.gymName,
              ownerName: widget.ownerName ?? '',
              gymPhone: widget.gymPhone ?? '',
              email: widget.email ?? '',
              website: widget.website,
              address: widget.address ?? '',
              city: widget.city ?? '',
              currency: widget.currency ?? '₹',
              adminName: widget.adminName,
              adminPhone: widget.adminPhone ?? '',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentInput = _isConfirming ? _confirmMpin : _mpin;

    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restoreMode ? tr('restore_step_mpin') : 'STEP 3 OF 4: MPIN SETUP'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + safeBottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 32 - safeBottom).clamp(0, double.infinity),
                ),
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
                              : tr('mpin_setup_hint'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 30),

                        // MPIN Indicator Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(SecurityService.mpinLength, (index) {
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
                          onPressed: currentInput.length == SecurityService.mpinLength ? _proceed : null,
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

