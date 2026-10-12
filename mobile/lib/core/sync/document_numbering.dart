/// Bill / receipt numbering that stays unique when the same gym is used on
/// several phones at once.
///
/// Each phone numbers its documents inside its own series, identified by the
/// phone's device code: `GYM-2026-A00012` on one phone, `GYM-2026-B00003` on
/// another. Without the code two offline phones would both create
/// `GYM-2026-00012`, and because `receiptNumber` / `billNumber` are UNIQUE in
/// SQLite, pulling one would silently replace (delete) the other phone's row.
///
/// Installs not linked to a cloud account (single phone, nothing to collide
/// with) keep the original code-less format `GYM-2026-00012`.
class DocumentNumbering {
  static const int _digits = 5;

  /// The next number for [prefix] (e.g. `GYM-2026-`) in [deviceCode]'s series,
  /// given every number that already exists with that prefix.
  ///
  /// Only numbers of exactly this series are considered, so numbers from other
  /// phones (other codes) or the legacy code-less series never affect it.
  static String next({
    required String prefix,
    required String? deviceCode,
    required Iterable<String> existing,
  }) {
    final code = deviceCode ?? '';
    final series = RegExp('^${RegExp.escape(prefix + code)}(\\d{$_digits,})\$');
    var max = 0;
    for (final number in existing) {
      final match = series.firstMatch(number);
      if (match == null) continue;
      final n = int.parse(match.group(1)!);
      if (n > max) max = n;
    }
    return '$prefix$code${(max + 1).toString().padLeft(_digits, '0')}';
  }
}
