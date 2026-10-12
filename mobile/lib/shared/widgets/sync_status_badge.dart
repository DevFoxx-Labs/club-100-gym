import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../features/settings/data_connection_screen.dart';

class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key});

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DataConnectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: SyncEngine.instance.status,
      builder: (context, status, _) {
        final phase = status.phase;
        final pendingCount = status.pendingChanges;

        if (phase == SyncPhase.syncing) {
          if (!_spinController.isAnimating) {
            _spinController.repeat();
          }
        } else {
          if (_spinController.isAnimating) {
            _spinController.stop();
            _spinController.reset();
          }
        }

        IconData icon;
        Color iconColor;
        String tooltip;

        switch (phase) {
          case SyncPhase.syncing:
            icon = Icons.sync_rounded;
            iconColor = AppTheme.neonLime;
            tooltip = tr('sync_status_syncing');
            break;
          case SyncPhase.offline:
            icon = Icons.cloud_off_rounded;
            iconColor = AppTheme.textMuted;
            tooltip = tr('sync_status_offline');
            break;
          case SyncPhase.error:
            icon = Icons.cloud_queue_rounded;
            iconColor = Colors.redAccent;
            tooltip = tr('sync_status_error');
            break;
          case SyncPhase.disabled:
          case SyncPhase.signedOut:
            icon = Icons.cloud_outlined;
            iconColor = AppTheme.textMuted;
            tooltip = tr('cloud_not_linked_desc');
            break;
          case SyncPhase.idle:
            if (pendingCount > 0) {
              icon = Icons.cloud_upload_rounded;
              iconColor = AppTheme.neonLime;
              tooltip = tr('sync_pending_changes', {'count': '$pendingCount'});
            } else {
              icon = Icons.cloud_done_rounded;
              iconColor = AppTheme.neonLime;
              tooltip = tr('sync_status_idle');
            }
            break;
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: tooltip,
            child: Material(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onTap(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: phase == SyncPhase.error
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : const Color(0xFF222838),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      phase == SyncPhase.syncing
                          ? AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _spinController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child: Icon(icon, color: iconColor, size: 20),
                            )
                          : Icon(icon, color: iconColor, size: 20),
                      if (phase == SyncPhase.idle && pendingCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      if (phase == SyncPhase.error)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
