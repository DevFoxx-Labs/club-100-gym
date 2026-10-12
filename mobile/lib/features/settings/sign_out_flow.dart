import 'package:flutter/material.dart';
import '../../core/auth/auth_service.dart';
import '../../core/config/supabase_config.dart';
import '../../core/localization/app_translations.dart';
import '../../core/security/security_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/confirmation_dialog.dart';
import '../onboarding/welcome_screen.dart';

/// Shared "sign out / reset this device" flow used by the Cloud Sync screen
/// and Settings → Reset.
///
/// 1. If the gym is linked to a cloud account, tries to upload every pending
///    change first.
/// 2. Asks for confirmation — with an explicit warning if some changes still
///    could not be uploaded (they would be lost).
/// 3. Signs out, wipes this device's local data and MPIN (the cloud backup is
///    kept) and returns to the Welcome screen.
Future<void> runSignOutFlow(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final navigator = Navigator.of(context);

  var pending = 0;
  final isLinked = AuthService.instance.isSignedIn && await SupabaseConfig.getActiveGymId() != null;
  if (isLinked && await SyncEngine.instance.pendingCount() > 0) {
    if (!context.mounted) return;
    _showProgress(context, tr('signout_uploading'));
    pending = await SyncEngine.instance.flushPending();
    navigator.pop(); // dismiss progress
  }

  if (!context.mounted) return;
  final fullMessage = pending > 0
      ? '$message\n\n${tr('signout_pending_warning', {'count': '$pending'})}'
      : message;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => ConfirmationDialog(
      title: title,
      message: fullMessage,
      confirmLabel: confirmLabel,
      isDestructive: true,
    ),
  );
  if (confirmed != true) return;

  await AuthService.instance.signOut();
  await SecurityService().clearSecurityData();

  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    (route) => false,
  );
}

void _showProgress(BuildContext context, String text) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.neonLime),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
