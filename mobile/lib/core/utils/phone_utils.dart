import 'package:country_code_picker/country_code_picker.dart' show codes;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'country_names_en.dart';

/// Helpers for splitting/combining a phone number and its country dial code.
///
/// Numbers are persisted as a single string (e.g. `+919876543210`) so no
/// database/model migration is needed; screens split it back into a dial
/// code + local number for editing, and combine it again before saving.
class PhoneUtils {
  PhoneUtils._();

  static const String _fallbackDialCode = '+91';
  static const MethodChannel _regionChannel = MethodChannel('gymyardhq/device_region');

  static String _defaultDialCode = _fallbackDialCode;

  /// Dial code pre-selected for new phone numbers, matching the country the
  /// admin's device is in (see [init]). Falls back to +91 when unknown.
  static String get defaultDialCode => _defaultDialCode;

  /// The picker's country list with English names, so admins can search in
  /// English instead of each country's native script.
  static final List<Map<String, String>> englishCountryList = [
    for (final c in codes) {...c, 'name': countryNamesEn[c['code']] ?? c['name'] ?? ''},
  ];

  /// Detects the admin's country without any location permission: on Android
  /// the SIM / mobile network country, otherwise the device region setting.
  /// Call once at startup, before any phone field is built.
  static Future<void> init() async {
    final candidates = <String?>[];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        candidates.add(await _regionChannel.invokeMethod<String>('getCountryCode'));
      } catch (e) {
        debugPrint('Device region lookup failed: $e');
      }
    }
    candidates.addAll(PlatformDispatcher.instance.locales.map((l) => l.countryCode));

    for (final iso in candidates) {
      final dialCode = dialCodeForIso(iso);
      if (dialCode != null) {
        _defaultDialCode = dialCode;
        return;
      }
    }
  }

  static String? dialCodeForIso(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final upper = iso.toUpperCase();
    for (final c in codes) {
      if (c['code'] == upper && (c['dial_code'] ?? '').isNotEmpty) return c['dial_code'];
    }
    return null;
  }

  /// All real dial codes (e.g. `+91`, `+1`, `+971`), longest first so a
  /// number is matched against the most specific code before a shorter,
  /// ambiguous prefix (avoids mis-splitting `+91...` as some 4-digit code).
  static final List<String> _knownDialCodes = () {
    final set = <String>{
      for (final c in codes)
        if ((c['dial_code'] ?? '').isNotEmpty) c['dial_code']!,
    };
    final list = set.toList();
    list.sort((a, b) => b.length.compareTo(a.length));
    return list;
  }();

  /// Expected local-number digit length per dial code, used for
  /// country-aware validation. Falls back to a generic 6-14 digit range
  /// for dial codes not listed here.
  static const Map<String, int> _expectedLength = {
    '+91': 10, // India
    '+1': 10, // US / Canada
    '+44': 10, // UK
    '+61': 9, // Australia
    '+971': 9, // UAE
    '+65': 8, // Singapore
    '+966': 9, // Saudi Arabia
    '+974': 8, // Qatar
    '+968': 8, // Oman
    '+973': 8, // Bahrain
    '+965': 8, // Kuwait
    '+92': 10, // Pakistan
    '+880': 10, // Bangladesh
    '+977': 10, // Nepal
    '+94': 9, // Sri Lanka
  };

  static int? expectedLength(String dialCode) => _expectedLength[dialCode];

  /// Splits a stored phone value into `(dialCode, localNumber)`.
  /// Numbers without a leading `+` are legacy data saved before country codes
  /// were tracked, when the app only supported Indian (+91) numbers.
  static (String, String) split(String? raw) {
    final value = (raw ?? '').trim();
    if (value.startsWith('+')) {
      for (final code in _knownDialCodes) {
        if (value.startsWith(code)) {
          final digits = value.substring(code.length).replaceAll(RegExp(r'\D'), '');
          return (code, digits);
        }
      }
      final match = RegExp(r'^(\+\d{1,4})(.*)$').firstMatch(value);
      if (match != null) {
        final digits = match.group(2)!.replaceAll(RegExp(r'\D'), '');
        return (match.group(1)!, digits);
      }
    }
    return (_fallbackDialCode, value.replaceAll(RegExp(r'\D'), ''));
  }

  static String combine(String dialCode, String localNumber) {
    final digits = localNumber.trim().replaceAll(RegExp(r'\D'), '');
    return '$dialCode$digits';
  }
}
