import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_state_service.dart';
import '../../core/sync/data_mode.dart';
import '../../core/sync/data_mode_service.dart';
import '../../core/sync/mongo_connection_service.dart';
import '../../core/sync/sync_migration_service.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/neon_button.dart';

/// Lets the admin switch the app's storage backend between the local
/// SQLite database (Offline, the default) and their own MongoDB cluster
/// (Online). Credentials are entered here at runtime and kept in secure
/// storage only — never hardcoded in the app.
///
/// Automatic two-way sync is not implemented yet: switching to Online runs
/// a one-time push of all existing local data into MongoDB (upserted by id,
/// so re-running never creates duplicates), and from then on Online mode
/// reads/writes MongoDB exclusively while Offline mode reads/writes SQLite
/// exclusively.
class DataConnectionScreen extends StatefulWidget {
  const DataConnectionScreen({super.key});

  @override
  State<DataConnectionScreen> createState() => _DataConnectionScreenState();
}

class _DataConnectionScreenState extends State<DataConnectionScreen> {
  final _uriController = TextEditingController();
  bool _obscureUri = true;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isMigrating = false;

  DataMode _mode = DataMode.offline;
  DateTime? _lastMigratedAt;
  DateTime? _lastSyncAt;

  String _migrationTable = '';
  int _migrationIndex = 0;
  int _migrationTotal = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final mode = await DataModeService.instance.getMode();
    final uri = await DataModeService.instance.getMongoUri();
    final migratedAt = await DataModeService.instance.getLastMigratedAt();
    final syncAt = await DataModeService.instance.getLastSyncAt();
    if (!mounted) return;
    setState(() {
      _mode = mode;
      _uriController.text = uri ?? '';
      _lastMigratedAt = migratedAt;
      _lastSyncAt = syncAt;
      _isLoading = false;
    });
  }

  String? _parsedDbName(String uri) {
    try {
      final parsed = Uri.parse(uri.trim());
      final path = parsed.path.startsWith('/') ? parsed.path.substring(1) : parsed.path;
      return path.trim().isEmpty ? null : path.trim();
    } catch (_) {
      return null;
    }
  }

  String? _validateUri(String uri) {
    final trimmed = uri.trim();
    if (trimmed.isEmpty) return 'Connection string enter karein.';
    if (!trimmed.startsWith('mongodb://') && !trimmed.startsWith('mongodb+srv://')) {
      return 'Connection string "mongodb://" ya "mongodb+srv://" se shuru honi chahiye.';
    }
    if (_parsedDbName(trimmed) == null) {
      return 'Connection string ke aakhir mein database ka naam bhi hona chahiye (e.g. .../myGymDb).';
    }
    return null;
  }

  Future<void> _testConnection() async {
    final error = _validateUri(_uriController.text);
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    setState(() => _isTesting = true);
    final result = await MongoConnectionService.instance.testConnection(_uriController.text.trim());
    if (!mounted) return;
    setState(() => _isTesting = false);
    _showSnack(result.message, isError: !result.success);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.statusOverdue : null,
      ),
    );
  }

  Future<void> _confirmSwitchToOnline() async {
    final error = _validateUri(_uriController.text);
    if (error != null) {
      _showSnack(error, isError: true);
      return;
    }
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'SWITCH TO ONLINE MODE?',
        message: 'Aapka mojooda offline (SQLite) data pehle MongoDB mein copy kiya jayega, fir se run karne par bhi duplicate nahi banega. Uske baad app sirf MongoDB use karegi jab tak aap wapas Offline mode par switch na karein.',
        confirmText: 'Copy Data & Go Online',
        onConfirm: _switchToOnline,
      ),
    );
  }

  Future<void> _switchToOnline() async {
    final uri = _uriController.text.trim();
    final dbName = _parsedDbName(uri)!;

    setState(() {
      _isMigrating = true;
      _migrationTable = '';
      _migrationIndex = 0;
      _migrationTotal = 0;
    });

    try {
      await DataModeService.instance.saveMongoConnection(uri: uri, databaseName: dbName);

      final testResult = await MongoConnectionService.instance.testConnection(uri);
      if (!testResult.success) {
        throw StateError(testResult.message);
      }

      final counts = await SyncMigrationService.instance.migrateAllTablesToMongo(
        onProgress: (table, index, total) {
          if (!mounted) return;
          setState(() {
            _migrationTable = table;
            _migrationIndex = index;
            _migrationTotal = total;
          });
        },
      );

      await DataModeService.instance.setMode(DataMode.online);
      AppStateService.instance.notifyAll();

      final totalRows = counts.values.fold<int>(0, (a, b) => a + b);
      if (!mounted) return;
      setState(() {
        _mode = DataMode.online;
        _isMigrating = false;
      });
      await _load();
      if (!mounted) return;
      _showSnack('Online mode chalu. $totalRows records MongoDB mein copy ho gaye.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMigrating = false);
      _showSnack('Online mode chalu nahi ho paya: $e', isError: true);
    }
  }

  Future<void> _confirmSwitchToOffline() async {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'SWITCH TO OFFLINE MODE?',
        message: 'App ab is device ke local SQLite data ka use karegi. MongoDB mein jo data hai wo waisa hi surakshit rahega, lekin jab tak aap dobara Online mode par switch nahi karte, naya data sirf is device par save hoga.',
        confirmText: 'Go Offline',
        onConfirm: _switchToOffline,
      ),
    );
  }

  Future<void> _switchToOffline() async {
    setState(() => _isLoading = true);
    await DataModeService.instance.setMode(DataMode.offline);
    await MongoConnectionService.instance.close();
    AppStateService.instance.notifyAll();
    await _load();
    if (!mounted) return;
    _showSnack('Offline mode chalu — ab local storage use ho raha hai.');
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final isOnline = _mode == DataMode.online;

    return Scaffold(
      appBar: AppBar(title: const Text('DATA STORAGE MODE')),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.neonLime))
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      24 + safeBottom + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ModeCard(
                          icon: Icons.smartphone_rounded,
                          title: 'Offline Mode',
                          subtitle: 'Sab kuch is device ki local SQLite database mein save hota hai. Internet ki zaroorat nahi. (Default)',
                          isSelected: !isOnline,
                          onTap: !isOnline ? null : _confirmSwitchToOffline,
                        ),
                        const SizedBox(height: 12),
                        _ModeCard(
                          icon: Icons.cloud_rounded,
                          title: 'Online Mode',
                          subtitle: 'Aapke apne MongoDB cluster mein data save hota hai. Neeche connection details bharein.',
                          isSelected: isOnline,
                          onTap: null,
                        ),
                        const SizedBox(height: 20),

                        Text('MONGODB CONNECTION', style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        const Text(
                          'Apne MongoDB Atlas (ya self-hosted) cluster ki connection string yahan daalein. Isme database ka naam bhi hona chahiye, e.g. mongodb+srv://user:pass@cluster.mongodb.net/myGymDb',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Connection String',
                          hint: 'mongodb+srv://user:pass@cluster.../dbName',
                          controller: _uriController,
                          obscureText: _obscureUri,
                          keyboardType: TextInputType.url,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureUri ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: AppTheme.textMuted, size: 20),
                            onPressed: () => setState(() => _obscureUri = !_obscureUri),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.statusOverdue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.statusOverdue.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'Yeh connection string is device par surakshit (encrypted) storage mein rehti hai. Sirf apna khud ka database/cluster use karein — koi shared/public credential na daalein.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 16),
                        NeonButton(
                          text: 'Test Connection',
                          isSecondary: true,
                          width: double.infinity,
                          isLoading: _isTesting,
                          onPressed: _testConnection,
                        ),
                        const SizedBox(height: 12),
                        NeonButton(
                          text: isOnline ? 'Re-sync Now (Offline data → MongoDB)' : 'Switch to Online Mode',
                          icon: isOnline ? Icons.sync_rounded : Icons.cloud_upload_rounded,
                          width: double.infinity,
                          onPressed: _confirmSwitchToOnline,
                        ),

                        if (_lastMigratedAt != null || _lastSyncAt != null) ...[
                          const SizedBox(height: 20),
                          Text('SYNC STATUS', style: TextStyle(color: AppTheme.neonLime, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          if (_lastSyncAt != null)
                            Text('Last synced to MongoDB: ${_lastSyncAt!.toLocal()}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                        ],

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: const Text(
                            'Note: Abhi ke liye automatic two-way sync uplabdh nahi hai — mode switch karne par ek baar ka data copy hota hai. Jab automatic sync add hoga, tab conflicts ko safely resolve kiya jayega.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isMigrating) _MigrationOverlay(table: _migrationTable, index: _migrationIndex, total: _migrationTotal),
                ],
              ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ModeCard({
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
              child: Icon(icon, color: AppTheme.neonLime, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11.5)),
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

class _MigrationOverlay extends StatelessWidget {
  final String table;
  final int index;
  final int total;

  const _MigrationOverlay({required this.table, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppTheme.darkBackground.withValues(alpha: 0.92),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.neonLime),
                const SizedBox(height: 20),
                const Text('Copying data to MongoDB...', style: TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                if (total > 0)
                  Text(
                    '${table.toUpperCase()} ($index / $total)',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
