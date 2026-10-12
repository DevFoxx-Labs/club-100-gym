import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../sync/supabase_service.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_schema.dart';

/// Gym-owner account (Supabase Auth, email + password) and the binding
/// between that account and its single cloud gym.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  SupabaseClient? get _client => SupabaseService.instance.client;

  bool get isAvailable => _client != null;
  User? get currentUser => _client?.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isAuthenticated => isSignedIn;
  String? get email => currentUser?.email;
  String? get currentEmail => email;

  /// Returns null on success, or a user-facing error message.
  /// [needsEmailConfirmation] is true when the project requires email
  /// verification before the first sign-in.
  Future<({String? error, bool needsEmailConfirmation})> signUp(String email, String password) async {
    final client = _client;
    if (client == null) return (error: 'Cloud service is not configured.', needsEmailConfirmation: false);
    try {
      final res = await client.auth.signUp(email: email.trim(), password: password);
      return (error: null, needsEmailConfirmation: res.session == null);
    } on AuthException catch (e) {
      return (error: e.message, needsEmailConfirmation: false);
    } catch (e) {
      debugPrint('[AuthService] signUp error: $e');
      return (error: 'Could not reach the server. Check your internet connection.', needsEmailConfirmation: false);
    }
  }

  Future<String?> signIn(String email, String password) async {
    final client = _client;
    if (client == null) return 'Cloud service is not configured.';
    try {
      await client.auth.signInWithPassword(email: email.trim(), password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('[AuthService] signIn error: $e');
      return 'Could not reach the server. Check your internet connection.';
    }
  }

  /// Re-checks the signed-in owner's account password (identity proof for
  /// resetting a forgotten MPIN). Returns null on success, or an error.
  Future<String?> verifyPassword(String password) async {
    final email = currentUser?.email;
    if (_client == null || email == null) return 'No cloud account is linked on this phone.';
    return signIn(email, password);
  }

  Future<String?> sendPasswordResetCode(String email) async {
    try {
      await _client!.auth.resetPasswordForEmail(email.trim());
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> resetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      await _client!.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.recovery);
      await _client!.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// The cloud gym owned by the signed-in user, if one exists.
  Future<String?> findMyGymId() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return null;
    final row = await client.from('gyms').select('id').eq('owner_id', user.id).maybeSingle();
    return row?['id'] as String?;
  }

  /// Binds the current local data (just created by onboarding, or an existing
  /// offline install) to a NEW cloud gym and queues everything for upload.
  /// Works offline: the upload happens whenever connectivity returns.
  Future<void> registerNewGym() async {
    final gymId = const Uuid().v4();
    await SupabaseConfig.setActiveGymId(gymId);
    final db = await AppDatabase.instance.database;
    await SyncSchema.enqueueAll(db);
    SyncEngine.instance.requestSync(immediate: true);
  }

  /// Binds this device to an EXISTING cloud gym and uploads this device's
  /// local data into it (merge; this device's version wins for rows that
  /// exist in both). Nothing local is deleted.
  Future<void> linkToExistingGym(String gymId) async {
    await SupabaseConfig.setActiveGymId(gymId);
    final db = await AppDatabase.instance.database;
    await SyncSchema.enqueueAll(db);
    SyncEngine.instance.requestSync(immediate: true);
  }

  /// Ends the Supabase session only — local data and the gym binding are
  /// kept. Used when the admin signs in but then cancels linking.
  Future<void> discardSession() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] discardSession error: $e');
    }
  }

  /// Signs out and wipes this device's local copy. Cloud data is untouched.
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
    }
    await SupabaseConfig.clearBinding();
    await AppDatabase.instance.clearAllData();
  }
}

