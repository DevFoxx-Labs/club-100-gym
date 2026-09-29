import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../core/sync/supabase_service.dart';
import '../../core/sync/supabase_sync_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

class DataConnectionScreen extends StatefulWidget {
  const DataConnectionScreen({super.key});

  @override
  State<DataConnectionScreen> createState() => _DataConnectionScreenState();
}

class _DataConnectionScreenState extends State<DataConnectionScreen> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSyncing = false;
  bool _isConnected = false;
  String? _connectionMessage;

  DateTime? _lastSyncAt;
  String _gymId = 'default';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final url = await SupabaseConfig.getUrl();
    final anonKey = await SupabaseConfig.getAnonKey();
    final lastSync = await SupabaseConfig.getLastSyncAt();
    final gymInfo = await SettingsRepository().getGymInfo();

    if (!mounted) return;
    setState(() {
      _urlController.text = url ?? '';
      _anonKeyController.text = anonKey ?? '';
      _lastSyncAt = lastSync;
      _gymId = gymInfo.id;
      _isLoading = false;
    });

    if (url != null && anonKey != null && url.isNotEmpty && anonKey.isNotEmpty) {
      _testConnection(silent: true);
    }
  }

  Future<void> _testConnection({bool silent = false}) async {
    if (!silent) setState(() => _isTesting = true);

    final res = await SupabaseService.instance.testConnection(
      customUrl: _urlController.text.trim(),
      customAnonKey: _anonKeyController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isConnected = res.success;
      _connectionMessage = res.error;
    });

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success ? 'Connected to Supabase Cloud successfully!' : 'Connection error: ${res.error}'),
          backgroundColor: res.success ? AppTheme.neonLime : AppTheme.statusOverdue,
        ),
      );
    }
  }

  Future<void> _saveCredentials() async {
    final url = _urlController.text.trim();
    final key = _anonKeyController.text.trim();

    if (url.isEmpty || key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both Supabase Project URL and Anon Key.')),
      );
      return;
    }

    await SupabaseConfig.saveCredentials(url: url, anonKey: key);
    await SupabaseService.instance.init(force: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Supabase credentials saved securely!'), backgroundColor: AppTheme.neonLime),
    );

    await _testConnection();
  }

  Future<void> _confirmPushLocalData() async {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'SYNC LOCAL TO SUPABASE CLOUD?',
        message: 'This will upload all local members, plans, payments, and receipts to your Supabase PostgreSQL cloud database. Existing cloud records with matching IDs will be safely updated without duplicates.',
        confirmText: 'Sync to Cloud Now',
        onConfirm: _pushLocalData,
      ),
    );
  }

  Future<void> _pushLocalData() async {
    setState(() => _isSyncing = true);
    final res = await SupabaseSyncService.instance.pushAllLocalDataToSupabase(_gymId);
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSyncAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Synced ${res.totalPushed} records to Supabase!' : 'Sync failed: ${res.error}'),
        backgroundColor: res.success ? AppTheme.neonLime : AppTheme.statusOverdue,
      ),
    );
  }

  Future<void> _confirmRestoreFromCloud() async {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmationDialog(
        title: 'RESTORE FROM SUPABASE CLOUD?',
        message: 'This will download all records from Supabase into your local app. Local records will be updated to match the cloud records.',
        confirmText: 'Restore from Cloud',
        onConfirm: _restoreFromCloud,
      ),
    );
  }

  Future<void> _restoreFromCloud() async {
    setState(() => _isSyncing = true);
    final res = await SupabaseSyncService.instance.restoreAllGymData(_gymId);
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSyncAt = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Restored ${res.totalRecordsRestored} records from Supabase!' : 'Restore failed: ${res.error}'),
        backgroundColor: res.success ? AppTheme.neonLime : AppTheme.statusOverdue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('SUPABASE CLOUD SYNC')),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + safeBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cloud Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isConnected ? AppTheme.neonLime : AppTheme.darkBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (_isConnected ? AppTheme.neonLime : Colors.white24).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              color: _isConnected ? AppTheme.neonLime : Colors.white54,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected ? 'Connected to Supabase' : 'Offline / Not Connected',
                                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _lastSyncAt != null
                                      ? 'Last synced: ${_lastSyncAt!.day}/${_lastSyncAt!.month}/${_lastSyncAt!.year} at ${_lastSyncAt!.hour.toString().padLeft(2, '0')}:${_lastSyncAt!.minute.toString().padLeft(2, '0')}'
                                      : 'Never synced with cloud',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                                if (_connectionMessage != null && _connectionMessage!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _connectionMessage!,
                                    style: TextStyle(
                                      color: _isConnected ? AppTheme.neonLime : AppTheme.statusOverdue,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('SUPABASE CREDENTIALS', style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 6),
                    const Text(
                      'Enter your Supabase Project URL and public Anon API Key below. These credentials are saved securely on your device.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Project URL',
                      hint: 'https://xxxxxxxxxxxx.supabase.co',
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'Anon Public API Key',
                      hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                      controller: _anonKeyController,
                      obscureText: _obscureKey,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppTheme.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: NeonButton(
                            text: 'Save Credentials',
                            onPressed: _saveCredentials,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NeonButton(
                            text: 'Test Ping',
                            isSecondary: true,
                            isLoading: _isTesting,
                            onPressed: () => _testConnection(silent: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    Text('CLOUD DATA SYNCHRONIZATION', style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 12),

                    NeonButton(
                      text: 'Push Local Data to Supabase',
                      icon: Icons.cloud_upload_rounded,
                      width: double.infinity,
                      isLoading: _isSyncing,
                      onPressed: _confirmPushLocalData,
                    ),
                    const SizedBox(height: 12),

                    NeonButton(
                      text: 'Restore All Data from Supabase',
                      icon: Icons.cloud_download_rounded,
                      isSecondary: true,
                      width: double.infinity,
                      isLoading: _isSyncing,
                      onPressed: _confirmRestoreFromCloud,
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.cyanAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Offline-First Architecture', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Your gym operations always function instantly on your device via local SQLite. When internet is connected, records sync with Supabase Cloud so multiple devices, reception desks, and client apps stay updated in real time.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
