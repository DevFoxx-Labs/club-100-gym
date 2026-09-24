import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../core/backup/backup_service.dart';
import '../../shared/widgets/neon_button.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService();
  bool _isLoading = false;

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);
    try {
      final file = await _backupService.exportBackup();
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encrypted backup created: ${p.basename(file.path)}')),
      );
      await Share.shareXFiles([XFile(file.path)], text: 'Elite Fitness Gym Data Backup');
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null && mounted) {
      setState(() => _isLoading = true);
      final file = File(result.files.single.path!);
      final success = await _backupService.importBackup(file);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restored successfully! All gym records updated.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to restore backup. Invalid or corrupted file.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BACKUP & DATA EXPORT'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encrypted Backup',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textWhite),
              ),
              const SizedBox(height: 6),
              const Text(
                'Export your entire database (members, payments, receipts, plans) into an encrypted .gymbackup file for safe local storage.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),

              NeonButton(
                text: 'Export Encrypted Backup',
                icon: Icons.upload_file_rounded,
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _exportBackup,
              ),
              const SizedBox(height: 16),

              NeonButton(
                text: 'Restore Backup File',
                icon: Icons.download_rounded,
                isSecondary: true,
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _importBackup,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

