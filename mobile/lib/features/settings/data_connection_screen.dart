import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/supabase_config.dart';
import '../../core/localization/app_translations.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/neon_button.dart';
import '../auth/account_auth_screen.dart';
import 'sign_out_flow.dart';

class DataConnectionScreen extends StatefulWidget {
  const DataConnectionScreen({super.key});

  @override
  State<DataConnectionScreen> createState() => _DataConnectionScreenState();
}

class _DataConnectionScreenState extends State<DataConnectionScreen> {
  String? _cloudGymId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gymId = await SupabaseConfig.getActiveGymId();
    if (!mounted) return;
    setState(() {
      _cloudGymId = gymId;
    });
  }

  String _formatLastSync(DateTime? dt) {
    if (dt == null) return tr('sync_never');
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return tr('sync_just_now');
    if (diff.inMinutes < 60) return tr('sync_minutes_ago', {'n': '${diff.inMinutes}'});
    if (diff.inHours < 24) return tr('sync_hours_ago', {'n': '${diff.inHours}'});
    return tr('sync_days_ago', {'n': '${diff.inDays}'});
  }

  Future<void> _handleSyncNow() async {
    setState(() => _isLoading = true);
    final ok = await SyncEngine.instance.syncNow();
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? tr('sync_completed') : tr('sync_deferred')),
        backgroundColor: ok ? AppTheme.neonLime : AppTheme.darkCard,
      ),
    );
  }

  Future<void> _handleReDownload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: tr('cloud_redownload_confirm_title'),
        message: tr('cloud_redownload_confirm_desc'),
        confirmLabel: tr('cloud_redownload'),
        isDestructive: true,
      ),
    );

    if (confirmed != true || !mounted) return;

    final gymId = _cloudGymId ?? await AuthService.instance.findMyGymId();
    if (!mounted) return;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('cloud_no_gym_found'))),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.neonLime),
                const SizedBox(height: 20),
                Text(
                  tr('authRestoreLoading'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('cloud_replacing_local'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final res = await SyncEngine.instance.restoreFromCloud(gymId);

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('authRestoreSuccess')),
          backgroundColor: AppTheme.neonLime,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${tr('authRestoreFailed')}: ${res.error}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await runSignOutFlow(
      context,
      title: tr('cloud_sign_out'),
      message: tr('cloud_sign_out_desc'),
      confirmLabel: tr('cloud_sign_out'),
    );
  }

  @override
  Widget build(BuildContext context) {
    // "Connected" means signed in AND this phone is bound to a cloud gym; a
    // session without a binding can't sync anything.
    final isAuth = AuthService.instance.isAuthenticated && _cloudGymId != null;
    final email = AuthService.instance.currentEmail;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(tr('cloud_account_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + safeBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARD 1: ACCOUNT
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAuth
                        ? AppTheme.neonLime.withValues(alpha: 0.3)
                        : AppTheme.darkBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isAuth
                                ? AppTheme.neonLime.withValues(alpha: 0.15)
                                : AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isAuth ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            color: isAuth ? AppTheme.neonLime : AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr('cloud_account_card'),
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isAuth
                                ? AppTheme.neonLime.withValues(alpha: 0.15)
                                : AppTheme.darkCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isAuth ? AppTheme.neonLime : AppTheme.darkBorder,
                            ),
                          ),
                          child: Text(
                            isAuth ? tr('cloud_connected') : tr('cloud_disconnected'),
                            style: TextStyle(
                              color: isAuth ? AppTheme.neonLime : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isAuth) ...[
                      _InfoRow(
                        label: tr('cloud_linked_as'),
                        value: email ?? '-',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: tr('cloud_gym_id'),
                        value: _cloudGymId ?? '-',
                        icon: Icons.fitness_center_rounded,
                      ),
                    ] else ...[
                      Text(
                        tr('cloud_not_linked_desc'),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      NeonButton(
                        text: tr('cloud_link_button'),
                        icon: Icons.link_rounded,
                        width: double.infinity,
                        onPressed: () async {
                          final linked = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AccountAuthScreen(
                                initialMode: AccountAuthMode.signIn,
                                linkExistingLocalData: true,
                              ),
                            ),
                          );
                          if (linked == true) {
                            _load();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CARD 2: SYNC STATUS
              ValueListenableBuilder<SyncStatus>(
                valueListenable: SyncEngine.instance.status,
                builder: (context, status, _) {
                  final isSyncing = status.phase == SyncPhase.syncing;
                  final isOffline = status.phase == SyncPhase.offline;
                  final isError = status.phase == SyncPhase.error;
                  final pendingCount = status.pendingChanges;
                  final lastSync = status.lastSyncedAt;
                  final lastError = status.error;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.darkBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.darkCard,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSyncing
                                    ? Icons.sync_rounded
                                    : (isOffline
                                        ? Icons.wifi_off_rounded
                                        : (isError
                                            ? Icons.error_outline_rounded
                                            : Icons.cloud_sync_rounded)),
                                color: isError
                                    ? Colors.redAccent
                                    : (isOffline ? AppTheme.textMuted : AppTheme.neonLime),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tr('cloud_sync_card'),
                                style: const TextStyle(
                                  color: AppTheme.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isSyncing)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.neonLime,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Pending changes count
                        _InfoRow(
                          label: tr('sync_pending_label'),
                          value: pendingCount == 0
                              ? tr('sync_status_idle')
                              : tr('sync_pending_changes', {'count': '$pendingCount'}),
                          icon: Icons.pending_actions_rounded,
                          highlight: pendingCount > 0,
                        ),
                        const SizedBox(height: 10),

                        // Last sync time
                        _InfoRow(
                          label: tr('sync_last_label'),
                          value: _formatLastSync(lastSync),
                          icon: Icons.access_time_rounded,
                        ),

                        // Error message if present
                        if (lastError != null && lastError.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lastError,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Sync Now Action
                        NeonButton(
                          text: tr('cloud_sync_now'),
                          icon: Icons.sync_rounded,
                          width: double.infinity,
                          isLoading: _isLoading || isSyncing,
                          onPressed: _handleSyncNow,
                        ),

                        if (isAuth) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textMuted,
                              ),
                              icon: const Icon(Icons.cloud_download_outlined, size: 16),
                              label: Text(
                                tr('cloud_redownload'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: _handleReDownload,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              // CARD 3: SIGN OUT (Only if authenticated)
              if (isAuth) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('cloud_sign_out'),
                              style: const TextStyle(
                                color: AppTheme.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('cloud_sign_out_desc'),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _handleSignOut,
                        child: Center(
                          child: Text(
                            tr('cloud_sign_out'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
            color: highlight ? AppTheme.neonLime : AppTheme.textWhite,
            fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
