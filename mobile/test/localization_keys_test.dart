import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/core/localization/app_translations.dart';

void main() {
  test('every tr() key used in lib/ exists in AppTranslations with EN and HI', () {
    // tr() silently falls back to the raw key, so a missing entry shows up
    // on screen as e.g. "authTitleSignIn" — catch that here instead.
    final keyPattern = RegExp(r"""\btr\(\s*'([A-Za-z0-9_]+)'""");
    final missing = <String>{};
    final incomplete = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      for (final match in keyPattern.allMatches(entity.readAsStringSync())) {
        final key = match.group(1)!;
        final entry = AppTranslations.values[key];
        if (entry == null) {
          missing.add(key);
        } else if ((entry['en'] ?? '').isEmpty || (entry['hi'] ?? '').isEmpty) {
          incomplete.add(key);
        }
      }
    }

    expect(missing, isEmpty, reason: 'Missing translation keys: ${missing.toList()..sort()}');
    expect(incomplete, isEmpty, reason: 'Keys without both en and hi: ${incomplete.toList()..sort()}');
  });
}
