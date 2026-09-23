import 'package:flutter/material.dart';
import '../../core/printing/print_format.dart';
import '../../core/services/app_state_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/gym_info_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Lets the admin lock in a default paper format for bills & receipts so the
/// format picker sheet is skipped every time on print/share.
class PrintFormatSettingsScreen extends StatefulWidget {
  const PrintFormatSettingsScreen({super.key});

  @override
  State<PrintFormatSettingsScreen> createState() => _PrintFormatSettingsScreenState();
}

class _PrintFormatSettingsScreenState extends State<PrintFormatSettingsScreen> {
  final _settingsRepo = SettingsRepository();
  GymInfoModel? _gymInfo;
  PrintFormat? _selected;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGymInfo();
  }

  Future<void> _loadGymInfo() async {
    final gym = await _settingsRepo.getGymInfo();
    if (mounted) {
      setState(() {
        _gymInfo = gym;
        _selected = printFormatFromName(gym.defaultPrintFormat);
        _isLoading = false;
      });
    }
  }

  Future<void> _select(PrintFormat? format) async {
    final gym = _gymInfo;
    if (gym == null || _isSaving) return;
    setState(() {
      _selected = format;
      _isSaving = true;
    });

    final updated = format == null
        ? gym.copyWith(clearDefaultPrintFormat: true, updatedAt: DateTime.now())
        : gym.copyWith(defaultPrintFormat: format.name, updatedAt: DateTime.now());

    await _settingsRepo.saveGymInfo(updated);
    AppStateService.instance.notifyGymInfoChanged();

    if (mounted) {
      setState(() {
        _gymInfo = updated;
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PRINT FORMAT'),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : ListView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
                children: [
                  Text(
                    'DEFAULT PAPER FORMAT',
                    style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pick a format to use every time you print or share a bill or receipt, so you no longer need to choose one each time.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  _FormatOptionTile(
                    icon: Icons.touch_app_rounded,
                    title: 'Always Ask',
                    subtitle: 'Show the paper format picker every time',
                    isSelected: _selected == null,
                    onTap: () => _select(null),
                  ),
                  const SizedBox(height: 10),
                  for (final format in PrintFormat.values) ...[
                    _FormatOptionTile(
                      icon: format.isThermal ? Icons.receipt_long_rounded : Icons.description_rounded,
                      title: format.label,
                      subtitle: format.description,
                      isSelected: _selected == format,
                      onTap: () => _select(format),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _FormatOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOptionTile({
    required this.icon,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.neonLime.withValues(alpha: 0.08) : AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.neonLime : AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.neonLime.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.neonLime, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                  ),
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
