enum AppLanguage { en, hi }

extension AppLanguageX on AppLanguage {
  String get code => this == AppLanguage.hi ? 'hi' : 'en';

  String get label => this == AppLanguage.hi ? 'हिन्दी (Hindi)' : 'English';

  static AppLanguage fromCode(String? code) {
    return code == 'hi' ? AppLanguage.hi : AppLanguage.en;
  }
}
