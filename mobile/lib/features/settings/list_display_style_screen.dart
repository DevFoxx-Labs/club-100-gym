import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/services/app_state_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';

/// Lets the admin choose whether the Members and Trainers lists are shown as
/// full cards (current detailed design) or compact tiles (matching the
/// Dashboard's Recent Activity rows). The choice applies to both lists.
class ListDisplayStyleScreen extends StatefulWidget {
  const ListDisplayStyleScreen({super.key});

  @override
  State<ListDisplayStyleScreen> createState() => _ListDisplayStyleScreenState();
}

class _ListDisplayStyleScreenState extends State<ListDisplayStyleScreen> {
  final _settingsRepo = SettingsRepository();
  String _selectedStyle = 'card';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final style = await _settingsRepo.getListDisplayStyle();
    if (mounted) {
      setState(() {
        _selectedStyle = style;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _settingsRepo.saveListDisplayStyle(_selectedStyle);
    AppStateService.instance.notifyListDisplayStyleChanged();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('list_style_updated'))),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: Text(tr('list_style_appbar_title'))),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('list_style_description'),
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    _buildOption(
                      value: 'card',
                      icon: Icons.view_agenda_rounded,
                      title: tr('list_style_option_card_title'),
                      desc: tr('list_style_option_card_desc'),
                    ),
                    const SizedBox(height: 14),
                    _buildOption(
                      value: 'tile',
                      icon: Icons.view_list_rounded,
                      title: tr('list_style_option_tile_title'),
                      desc: tr('list_style_option_tile_desc'),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonLime,
                          foregroundColor: AppTheme.darkBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.darkBackground,
                                ),
                              )
                            : Text(
                                tr('list_style_apply'),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOption({
    required String value,
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final isSelected = _selectedStyle == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.08) : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppTheme.neonLime : AppTheme.darkBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.neonLime, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppTheme.neonLime : AppTheme.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
