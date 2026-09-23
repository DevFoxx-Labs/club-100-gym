/// Helpers for splitting/combining a phone number and its country dial code.
///
/// Numbers are persisted as a single string (e.g. `+919876543210`) so no
/// database/model migration is needed; screens split it back into a dial
/// code + local number for editing, and combine it again before saving.
class PhoneUtils {
  PhoneUtils._();

  static const String defaultDialCode = '+91';

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
  /// Numbers without a leading `+` are assumed to already be [defaultDialCode]
  /// local numbers (legacy data saved before country codes were tracked).
  static (String, String) split(String? raw) {
    final value = (raw ?? '').trim();
    if (value.startsWith('+')) {
      final match = RegExp(r'^(\+\d{1,4})(.*)$').firstMatch(value);
      if (match != null) {
        final digits = match.group(2)!.replaceAll(RegExp(r'\D'), '');
        return (match.group(1)!, digits);
      }
    }
    return (defaultDialCode, value.replaceAll(RegExp(r'\D'), ''));
  }

  static String combine(String dialCode, String localNumber) {
    final digits = localNumber.trim().replaceAll(RegExp(r'\D'), '');
    return '$dialCode$digits';
  }
}
