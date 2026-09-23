import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_language.dart';

/// Persists the admin's chosen display language and keeps an in-memory cache
/// so [tr] (see app_translations.dart) can resolve strings synchronously
/// everywhere, without threading a Future through every widget build.
class LocaleService {
  LocaleService._internal();
  static final LocaleService instance = LocaleService._internal();

  static const _languageKey = 'app_language';
  final _storage = const FlutterSecureStorage();

  AppLanguage _current = AppLanguage.en;
  AppLanguage get current => _current;

  /// Loads the saved language from secure storage into the in-memory cache.
  /// Must be called once at app startup, before the first paint.
  Future<AppLanguage> load() async {
    final code = await _storage.read(key: _languageKey);
    _current = AppLanguageX.fromCode(code);
    return _current;
  }

  Future<void> setLanguage(AppLanguage language) async {
    _current = language;
    await _storage.write(key: _languageKey, value: language.code);
  }
}
