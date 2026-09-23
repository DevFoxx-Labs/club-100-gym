import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/phone_utils.dart';

/// A phone number input: a country-code dropdown (flag + dial code) next to
/// the local number field, matching the app's dark theme. The dial code is
/// tracked in [dialCodeNotifier] so callers can read it (and combine it with
/// [controller].text via [PhoneUtils.combine]) when saving.
class PhoneInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueNotifier<String> dialCodeNotifier;
  final String? Function(String?)? validator;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.dialCodeNotifier,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppTheme.darkBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: dialCodeNotifier,
                builder: (context, dialCode, _) {
                  return CountryCodePicker(
                    enabled: enabled,
                    onChanged: (c) => dialCodeNotifier.value = c.dialCode ?? PhoneUtils.defaultDialCode,
                    initialSelection: dialCode,
                    favorite: const ['+91', 'IN', '+1', '+44', '+971'],
                    showFlag: true,
                    showDropDownButton: true,
                    alignLeft: false,
                    padding: EdgeInsets.zero,
                    flagWidth: 22,
                    textStyle: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    dialogTextStyle: const TextStyle(color: Colors.black87),
                    searchStyle: const TextStyle(color: Colors.black87),
                    dialogBackgroundColor: Colors.white,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.phone,
                maxLength: 14,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(counterText: ''),
                validator: validator,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
