import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_service.dart';
import '../../core/localization/app_translations.dart';

/// Lets the admin switch the app's display language between English and
/// Hindi. The choice is persisted and applied instantly across every screen.
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    _selected = LocaleService.instance.current;
  }

  Future<void> _select(AppLanguage language) async {
    if (language == _selected) return;
    setState(() => _selected = language);
    await LocaleService.instance.setLanguage(language);
    AppStateService.instance.notifyLanguageChanged();
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: Text(tr('language_title'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('language_subtitle'),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 20),
              _LanguageCard(
                flag: '🇬🇧',
                title: 'English',
                subtitle: 'Use the app in English',
                isSelected: _selected == AppLanguage.en,
                onTap: () => _select(AppLanguage.en),
              ),
              const SizedBox(height: 12),
              _LanguageCard(
                flag: '🇮🇳',
                title: 'हिन्दी (Hindi)',
                subtitle: 'ऐप को हिन्दी में इस्तेमाल करें',
                isSelected: _selected == AppLanguage.hi,
                onTap: () => _select(AppLanguage.hi),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.08) : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.neonLime : AppTheme.darkBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(flag, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.neonLime : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
