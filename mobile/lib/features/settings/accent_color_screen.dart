import 'package:flutter/material.dart';
import 'package:flutter_color_picker_plus/flutter_color_picker_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../data/repositories/settings_repository.dart';

/// Lets the admin pick a favorite highlight color that replaces the app's
/// default neon-lime accent everywhere (buttons, badges, active states, icons).
class AccentColorScreen extends StatefulWidget {
  const AccentColorScreen({super.key});

  @override
  State<AccentColorScreen> createState() => _AccentColorScreenState();
}

class _AccentColorScreenState extends State<AccentColorScreen> {
  final _settingsRepo = SettingsRepository();
  late Color _selectedColor;
  bool _isSaving = false;

  static const List<Color> _presetColors = [
    AppTheme.defaultAccentColor,
    Color(0xFF389BF2),
    Color(0xFFA855F7),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFF25D366),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = AppTheme.neonLime;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await _settingsRepo.saveAccentColor(_selectedColor);
    AppTheme.setAccentColor(_selectedColor);
    AppStateService.instance.notifyThemeChanged();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Highlight color updated')),
    );
    Navigator.pop(context);
  }

  bool _isPresetSelected(Color preset) => preset.toARGB32() == _selectedColor.toARGB32();

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('HIGHLIGHT COLOR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a favorite color to replace the app\'s highlight color everywhere — buttons, badges, active states, and icons.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 14),
              _buildPreviewCard(),
              const SizedBox(height: 20),

              const Text(
                'PRESET COLORS',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _presetColors.map((preset) => _buildSwatch(preset)).toList(),
              ),
              const SizedBox(height: 24),

              const Text(
                'CUSTOM COLOR',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: ColorPicker(
                  pickerColor: _selectedColor,
                  onColorChanged: (color) => setState(() => _selectedColor = color),
                  enableAlpha: false,
                  hexInputBar: true,
                  portraitOnly: true,
                  displayThumbColor: true,
                  labelTypes: const [],
                  pickerAreaBorderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedColor,
                    foregroundColor: _selectedColor.computeLuminance() > 0.5 ? AppTheme.darkBackground : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _selectedColor.computeLuminance() > 0.5 ? AppTheme.darkBackground : Colors.white,
                          ),
                        )
                      : const Text(
                          'Apply Highlight Color',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwatch(Color preset) {
    final selected = _isPresetSelected(preset);
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = preset),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: preset,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppTheme.textWhite : AppTheme.darkBorder,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                color: preset.computeLuminance() > 0.5 ? AppTheme.darkBackground : Colors.white,
                size: 20,
              )
            : null,
      ),
    );
  }

  /// Single-row preview (icon, badge, pill button) — kept deliberately small
  /// since the swatches right below already show the color itself.
  Widget _buildPreviewCard() {
    final onAccent = _selectedColor.computeLuminance() > 0.5 ? AppTheme.darkBackground : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(Icons.fitness_center_rounded, color: _selectedColor, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _selectedColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'ACTIVE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _selectedColor, fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Button',
              style: TextStyle(color: onAccent, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
