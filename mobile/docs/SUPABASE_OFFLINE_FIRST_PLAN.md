# Supabase Account + Offline-First Sync — Implementation Plan

**Target:** `mobile/` Flutter admin app (package `the_elite_fitness`)
**Branch:** `feature-supabse`
**Goal:**
1. The gym admin **signs up** (Supabase Auth, email + password) as part of onboarding. That account owns exactly one gym in the cloud.
2. Everything the admin does (members, plans, payments, bills, trainers, expenses, events, announcements, settings) is written to **local SQLite first** (instant, works offline) and then **synced automatically to Supabase** when internet is available.
3. If the app is uninstalled/reinstalled (or installed on a new phone), the admin **signs in with the same account** and **all data is restored** from Supabase.
4. Reads always come from local SQLite (SQLite *is* the cache), so the app stays fast and fully usable offline.

> **Instructions for the implementing agent**
> - Follow the phases **in order**. Each phase must end with `flutter analyze` = 0 issues and `flutter test` passing.
> - Follow `CLAUDE.md` rules (safe-area padding, `Expanded` in rows, `.withValues(alpha:)` not `.withOpacity`, `resizeToAvoidBottomInset`, etc.).
> - Match the existing code style: singletons with `X._internal(); static final X instance`, `debugPrint('[ClassName] ...')`, `tr('key')` for UI strings, `AppTheme` colors, `NeonButton`, `CustomTextField`.
> - **Do NOT modify the repositories in `lib/data/repositories/`.** Change capture is done with SQLite triggers (see Phase 2), so every existing write path — including bulk updates like `refreshOverdueStatuses()` and `markAllAsRead()` — is captured automatically.

---

## 0. Current State (analysis) and Why It Must Change

What already exists (commit `6c30817`):

| File | What it does | Problem |
|---|---|---|
| `lib/core/config/supabase_config.dart` | URL / anon key typed by the user in-app, stored in secure storage | End users shouldn't paste keys. The app should ship with the project URL + anon key. |
| `lib/core/sync/supabase_service.dart` | Initializes Supabase from stored keys | Fine, but needs to be simplified. |
| `lib/core/sync/supabase_sync_service.dart` | Manual "push everything" / "restore everything" + `syncUpsert`/`syncDelete` | `syncUpsert`/`syncDelete` are **never called** → nothing syncs automatically. No offline queue. No delete propagation. |
| `findGymByEmailOrPhone()` (same file) | Finds a gym by typing a phone/email, then restores it | **Security hole:** anyone who types someone else's phone number can download that gym's entire member list. Must be replaced by authenticated login. |
| `supabase_schema.sql` (root + `mobile/`) | Cloud tables | RLS policy is `USING (true)` for **anon** on every table → the whole database is publicly readable/writable with the anon key. Also `bill_number`/`receipt_number` are globally `UNIQUE` (two gyms can't both have `BILL-2026-00001`), FKs between child tables make out-of-order sync fail, `REAL` (float4) loses money precision. |
| Local `gym` and `admins` rows | Always use `id = 'default'` | With the current cloud schema (`id` as the only PK) every gym would overwrite the same `'default'` row. |
| `app_database.dart` `_createDB` | Seeds 3 default packages + 12 plans on a fresh install | On restore after reinstall these seeded rows would duplicate the cloud packages/plans. |
| `AndroidManifest.xml` (main) | — | **No `INTERNET` permission** → release builds cannot reach Supabase at all. |
| `DataModeService` + `MongoCollectionStore` | A separate "Online = MongoDB" mode in every repository | Replaced by the Supabase design. Turn it off (Phase 1) so all repositories use the SQLite path. |

### Target architecture

```
 UI screens
    │  (unchanged)
 Repositories (unchanged, SQLite path only)
    │
 SQLite  ──AFTER INSERT/UPDATE/DELETE triggers──►  sync_outbox (pending changes)
    ▲                                                   │
    │  pull (apply remote rows,                         │ push (batched upsert /
    │  triggers muted)                                  ▼  soft-delete)
 SyncEngine  ◄──── connectivity change / app resume / AppState events / 3-min timer
    │
 Supabase (Postgres + RLS by auth.uid()) — every row tagged with gym_id
```

- **Write path:** repo writes SQLite → trigger adds `(table, rowKey)` to `sync_outbox` → `SyncEngine` pushes when online.
- **Read path:** always SQLite.
- **Pull path:** incremental by `server_updated_at` cursor per table; remote rows are applied with triggers muted (so they don't bounce back); rows with pending local changes are not overwritten (local wins until pushed).
- **Deletes:** pushed as soft-deletes (`is_deleted = true`) so restores and other devices know the row is gone.
- **Conflict rule:** last writer wins at push time; single-admin app so conflicts are rare.

---

## Phase 1 — Project setup, config, permissions, disable Mongo mode

### 1.1 `mobile/pubspec.yaml`
Add under `dependencies:` (keep `supabase_flutter: ^2.17.2`):
```yaml
  connectivity_plus: ^6.1.0
```
(Optional cleanup, can be done at the very end: remove `mongo_dart` together with `lib/core/sync/mongo_*.dart` and `sync_migration_service.dart` once nothing imports them.)

Add under `dev_dependencies:`:
```yaml
  sqflite_common_ffi: ^2.3.4
```
Run `flutter pub get`.

### 1.2 `mobile/android/app/src/main/AndroidManifest.xml`
Add next to the other `<uses-permission>` lines:
```xml
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```
On the `<application ...>` tag set `android:allowBackup="false"` and `android:fullBackupContent="false"`. Reason: Android Auto Backup restores the `flutter_secure_storage` file after reinstall but not the Keystore key, which breaks MPIN reads. Cloud restore replaces Auto Backup.

### 1.3 Supabase keys via `--dart-define-from-file`
Create `mobile/env/supabase.example.json`:
```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_ID.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_ANON_PUBLIC_KEY"
}
```
Create `mobile/env/supabase.json` with real values. Add to `mobile/.gitignore`:
```
env/supabase.json
```
Run/build with:
```
flutter run --dart-define-from-file=env/supabase.json
flutter build apk --release --dart-define-from-file=env/supabase.json
```
(The anon key is safe to ship in the app **only because** Phase 3 adds strict RLS.)

If `.vscode/launch.json` exists, add `"args": ["--dart-define-from-file=env/supabase.json"]` to the Flutter configurations.

### 1.4 Rewrite `lib/core/config/supabase_config.dart`
Replace the whole file with:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized configuration for the Supabase integration.
///
/// The project URL and anon key are injected at build time via
/// `--dart-define-from-file=env/supabase.json`, so gym owners never have to
/// type credentials. The anon key is safe to ship because every table is
/// protected by row-level security tied to the signed-in owner.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static const _storage = FlutterSecureStorage();
  static const String _keyGymId = 'supabase_active_gym_id';
  static const String _keyLastSyncAt = 'supabase_last_sync_at';

  /// The cloud gym id (UUID) this device is bound to. Null until the admin
  /// creates or restores a gym under their account.
  static Future<String?> getActiveGymId() => _storage.read(key: _keyGymId);

  static Future<void> setActiveGymId(String gymId) async {
    await _storage.write(key: _keyGymId, value: gymId);
  }

  static Future<DateTime?> getLastSyncAt() async {
    final val = await _storage.read(key: _keyLastSyncAt);
    return val != null ? DateTime.tryParse(val) : null;
  }

  static Future<void> setLastSyncAt(DateTime time) async {
    await _storage.write(key: _keyLastSyncAt, value: time.toIso8601String());
  }

  /// Forgets the cloud binding (used on sign-out / reset).
  static Future<void> clearBinding() async {
    await _storage.delete(key: _keyGymId);
    await _storage.delete(key: _keyLastSyncAt);
  }
}
```

### 1.5 Rewrite `lib/core/sync/supabase_service.dart`
```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  /// Initializes Supabase once at startup. Returns false (non-fatal) when the
  /// build has no Supabase keys, so the app keeps working fully offline.
  Future<bool> init() async {
    if (_isInitialized) return true;
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] SUPABASE_URL / SUPABASE_ANON_KEY not provided; cloud sync disabled.');
      return false;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      debugPrint('[SupabaseService] Initialization failed: $e\n$stackTrace');
      return false;
    }
  }
}
```
(`supabase_flutter` persists the auth session itself and refreshes tokens automatically.)

### 1.6 Disable Mongo "Online" mode — `lib/core/sync/data_mode_service.dart`
Change only the `isOnline` getter so every repository takes its SQLite branch:
```dart
  /// Mongo "Online" mode is retired: SQLite is always the source of truth and
  /// Supabase sync runs in the background via SyncEngine.
  Future<bool> get isOnline async => false;
```

### 1.7 Delete `lib/core/sync/supabase_sync_service.dart`
It is fully replaced by `SyncEngine` + `AuthService` below. Remove its imports from `gym_setup_screen.dart`, `welcome_screen.dart`, `data_connection_screen.dart` (those files are rewritten in Phase 5/6).

**End of Phase 1:** the app compiles after Phase 5/6 removes the old references; if you want a green build at this point, temporarily leave the old file and delete it in Phase 5.

---

## Phase 2 — Local sync infrastructure (SQLite)

### 2.1 New file `lib/core/sync/sync_tables.dart`
```dart
/// A local SQLite table that is mirrored to a Supabase table.
class SyncTable {
  final String local;
  final String cloud;

  /// Primary key column name in SQLite (and in the cloud, after snake_case).
  final String key;

  const SyncTable(this.local, this.cloud, {this.key = 'id'});

  bool get isGym => local == 'gym';
}

/// Every table that is backed up to Supabase, in push order (the gym row
/// first, because every other cloud row references it via gym_id).
///
/// Deliberately excluded (device-local only): notifications,
/// dismissed_notifications, notification_fire_markers — these are
/// regenerated by ReminderScheduler on each device.
class SyncTables {
  static const List<SyncTable> all = [
    SyncTable('gym', 'gyms'),
    SyncTable('admins', 'admins'),
    SyncTable('membership_packages', 'membership_packages'),
    SyncTable('membership_plans', 'membership_plans'),
    SyncTable('trainers', 'trainers'),
    SyncTable('trainer_payouts', 'trainer_payouts'),
    SyncTable('members', 'members'),
    SyncTable('memberships', 'memberships'),
    SyncTable('membership_change_logs', 'membership_change_logs'),
    SyncTable('trainer_change_logs', 'trainer_change_logs'),
    SyncTable('bills', 'bills'),
    SyncTable('payments', 'payments'),
    SyncTable('receipts', 'receipts'),
    SyncTable('expenses', 'expenses'),
    SyncTable('events', 'events'),
    SyncTable('announcements', 'announcements'),
    SyncTable('notification_settings', 'notification_settings'),
    SyncTable('app_settings', 'app_settings', key: 'key'),
  ];

  static SyncTable? byLocal(String name) {
    for (final t in all) {
      if (t.local == name) return t;
    }
    return null;
  }
}
```

### 2.2 New file `lib/core/sync/sync_schema.dart`
```dart
import 'package:sqflite/sqflite.dart';
import 'sync_tables.dart';

/// Local bookkeeping for offline-first sync:
/// - `sync_outbox`: one row per local change waiting to be pushed.
/// - `sync_meta`: key/value store (per-table pull cursors).
/// - `sync_control`: single-row flag that mutes the change-capture triggers
///   while remote rows are being applied, so pulled data isn't pushed back.
class SyncSchema {
  static Future<void> ensure(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        rowKey TEXT NOT NULL,
        op TEXT NOT NULL,
        enqueuedAt TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        lastError TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_outbox_row ON sync_outbox(tableName, rowKey);');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_control (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        applyingRemote INTEGER NOT NULL DEFAULT 0
      );
    ''');
    await db.execute('INSERT OR IGNORE INTO sync_control (id, applyingRemote) VALUES (1, 0);');
    // Recover from a crash in the middle of applying remote rows.
    await db.execute('UPDATE sync_control SET applyingRemote = 0 WHERE id = 1;');

    for (final t in SyncTables.all) {
      for (final (event, ref, op) in const [
        ('INSERT', 'NEW', 'upsert'),
        ('UPDATE', 'NEW', 'upsert'),
        ('DELETE', 'OLD', 'delete'),
      ]) {
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS trg_sync_${t.local}_${event.toLowerCase()}
          AFTER $event ON ${t.local}
          WHEN (SELECT applyingRemote FROM sync_control WHERE id = 1) = 0
          BEGIN
            INSERT INTO sync_outbox (tableName, rowKey, op, enqueuedAt)
            VALUES ('${t.local}', $ref."${t.key}", '$op', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
          END;
        ''');
      }
    }
  }

  /// Queues every existing local row for upload. Used when a gym is first
  /// bound to a cloud account (new signup, or an existing offline install
  /// connecting to the cloud for the first time).
  static Future<void> enqueueAll(DatabaseExecutor db) async {
    for (final t in SyncTables.all) {
      await db.rawInsert('''
        INSERT INTO sync_outbox (tableName, rowKey, op, enqueuedAt)
        SELECT '${t.local}', "${t.key}", 'upsert', strftime('%Y-%m-%dT%H:%M:%fZ', 'now') FROM ${t.local}
      ''');
    }
  }

  /// Runs [body] with change-capture triggers muted. Must be called inside a
  /// transaction so the flag can never leak to normal app writes.
  static Future<T> muted<T>(Transaction txn, Future<T> Function() body) async {
    await txn.update('sync_control', {'applyingRemote': 1}, where: 'id = 1');
    try {
      return await body();
    } finally {
      await txn.update('sync_control', {'applyingRemote': 0}, where: 'id = 1');
    }
  }

  /// Wipes all synced tables + sync bookkeeping without generating outbox
  /// entries (used before a full cloud restore and on sign-out/reset).
  static Future<void> wipeLocalData(Database db) async {
    await db.transaction((txn) async {
      await muted(txn, () async {
        for (final t in SyncTables.all) {
          await txn.delete(t.local);
        }
      });
      await txn.delete('sync_outbox');
      await txn.delete('sync_meta');
    });
  }
}
```
> Note on `INSERT ... ConflictAlgorithm.replace`: SQLite's REPLACE does **not** fire DELETE triggers unless `recursive_triggers` is on (it is off by default), so a replace produces exactly one `upsert` entry. Do not enable `recursive_triggers`.

### 2.3 Edit `lib/core/database/app_database.dart`
1. Add import: `import '../sync/sync_schema.dart';`
2. Change `version: 8` → `version: 9`.
3. In `_initDB`, **immediately before `return db;`** (after all the existing `ALTER TABLE` self-heal blocks, so that the seeded rows of a fresh install are NOT captured by triggers):
```dart
    // Offline-first sync bookkeeping + change-capture triggers. Created last
    // so the default packages/plans seeded by _createDB are not queued for
    // upload on their own — they are queued explicitly (SyncSchema.enqueueAll)
    // only when a brand-new gym is registered in the cloud.
    await SyncSchema.ensure(db);
```
4. Replace `clearAllData()` with a version that cannot generate cloud deletes:
```dart
  /// Clears every local table. Uses SyncSchema.wipeLocalData for the synced
  /// tables so a local reset never deletes the gym's cloud backup.
  Future<void> clearAllData() async {
    final db = await instance.database;
    await SyncSchema.wipeLocalData(db);
    await db.delete('notifications');
    await db.delete('dismissed_notifications');
    await db.delete('notification_fire_markers');
  }
```
> **Critical:** the old `clearAllData()` would, with triggers in place, enqueue a `delete` for every row and wipe the cloud backup on the next sync. The new version must be used.

### 2.4 `lib/core/backup/backup_service.dart` — no code change
Its local-file restore deletes and re-inserts rows; the triggers will queue those changes, so the cloud ends up mirroring the restored file. That is the intended behaviour. Add one doc comment line above the restore method stating this.

### 2.5 New file `lib/core/sync/cloud_mapper.dart`
```dart
import 'sync_tables.dart';

/// Converts rows between the local SQLite shape (camelCase columns, gym row
/// id = 'default') and the Supabase shape (snake_case columns, every row
/// tagged with gym_id, gym row keyed by its cloud UUID).
class CloudMapper {
  static const _cloudOnlyColumns = {'gym_id', 'owner_id', 'is_deleted', 'server_updated_at'};
  static const localGymRowId = 'default';

  static Map<String, dynamic> toCloud(
    SyncTable table,
    Map<String, Object?> localRow, {
    required String gymId,
    required String ownerId,
  }) {
    final map = <String, dynamic>{};
    localRow.forEach((k, v) => map[camelToSnake(k)] = v);
    if (table.isGym) {
      map['id'] = gymId;
      map['owner_id'] = ownerId;
    } else {
      map['gym_id'] = gymId;
    }
    map['is_deleted'] = false;
    return map;
  }

  /// [localColumns] is the set of columns that actually exist in the local
  /// table (from PRAGMA table_info); unknown cloud columns are dropped so a
  /// newer cloud schema can never break inserts on an older app version.
  static Map<String, Object?> toLocal(
    SyncTable table,
    Map<String, dynamic> cloudRow,
    Set<String> localColumns,
  ) {
    final map = <String, Object?>{};
    cloudRow.forEach((k, v) {
      if (_cloudOnlyColumns.contains(k)) return;
      final localKey = snakeToCamel(k);
      if (localColumns.contains(localKey)) map[localKey] = v;
    });
    if (table.isGym) map['id'] = localGymRowId;
    return map;
  }

  static String camelToSnake(String camel) =>
      camel.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');

  static String snakeToCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length <= 1) return snake;
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join();
  }
}
```

---

## Phase 3 — Supabase cloud schema (SQL)

### 3.1 New file `mobile/supabase/migrations/001_offline_sync_schema.sql`
Delete `mobile/supabase_schema.sql` and the root `supabase_schema.sql`, and use this file instead. Run it in **Supabase Dashboard → SQL Editor**.

Design rules used below:
- Every child table has `PRIMARY KEY (gym_id, id)` → local ids like `'default'` never collide across gyms.
- **No foreign keys between child tables and no NOT NULL on data columns.** SQLite already validates data; the outbox may push a membership before its member, and that must not fail.
- `double precision` for money (matches SQLite REAL; Postgres `real` is float4 and loses paise).
- `is_deleted` = tombstone; `server_updated_at` = server-side change clock used for incremental pulls.

```sql
-- =====================================================================
-- Elite Fitness — offline-first sync schema (v1)
-- If the OLD schema (supabase_schema.sql) was already run and holds no
-- real data, uncomment and run this block first:
-- drop table if exists member_device_tokens, announcements, events, expenses,
--   receipts, payments, bills, trainer_change_logs, membership_change_logs,
--   memberships, members, trainer_payouts, trainers, membership_plans,
--   membership_packages, admins, notification_settings, app_settings, gyms cascade;
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------- gyms (one per auth user) ----------
create table if not exists gyms (
  id text primary key,
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text, owner_name text, phone text, email text, website text,
  address text, city text, logo_path text, currency text,
  upi_id text, upi_payee_name text,
  bank_account_holder text, bank_account_number text, bank_ifsc text, bank_name text,
  show_upi_qr_on_bill integer, show_bank_details_on_bill integer,
  default_print_format text,
  created_at text, updated_at text,
  is_deleted boolean not null default false,
  server_updated_at timestamptz not null default now()
);

-- ---------- helper to declare child tables ----------
-- Each child table: gym_id + id composite key, tombstone, server clock.

create table if not exists admins (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, is_biometric_enabled integer,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_packages (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, description text, is_active integer,
  created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_plans (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  package_id text, name text, duration_days integer, default_fee double precision,
  description text, is_active integer, created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainers (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, role text, specialization text, monthly_salary double precision,
  photo_path text, is_active integer, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainer_payouts (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  trainer_id text, amount double precision, payout_date text, payout_type text, notes text,
  created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists members (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  name text, phone text, email text, gender text, date_of_birth text, photo_path text,
  notes text, is_archived integer, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists memberships (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, plan_id text, plan_name text, trainer_id text,
  personal_training_fee double precision, package_id text,
  start_date text, end_date text, fee_amount double precision, status text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists membership_change_logs (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, previous_membership_id text, new_membership_id text,
  previous_plan_name_snapshot text, new_plan_name_snapshot text,
  previous_fee_amount double precision, new_fee_amount double precision,
  reason text, changed_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists trainer_change_logs (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, membership_id text,
  previous_trainer_id text, previous_trainer_name_snapshot text,
  new_trainer_id text, new_trainer_name_snapshot text,
  previous_personal_training_fee double precision, new_personal_training_fee double precision,
  reason text, changed_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists bills (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  bill_number text, member_id text, member_name text, member_phone text,
  membership_id text, plan_name text, amount double precision,
  bill_date text, due_date text, status text, paid_amount double precision,
  payment_id text, receipt_id text, notes text, is_auto_generated integer, cycle_key text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists payments (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  member_id text, membership_id text, bill_id text, amount double precision,
  payment_date text, payment_method text, notes text, receipt_id text, receipt_number text,
  created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists receipts (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  payment_id text, receipt_number text, bill_number text, member_name text, member_phone text,
  plan_name text, trainer_name text, personal_training_fee double precision,
  amount double precision, payment_method text, payment_date text,
  start_date text, end_date text, qr_payload text, created_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists expenses (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, category text, amount double precision, expense_date text,
  payment_method text, notes text, created_at text, updated_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists events (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, description text, start_time text, end_time text, location text,
  trainer_id text, color_value bigint, created_at text, updated_at text, deleted_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists announcements (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  title text, message text, image_path text, category text,
  audience_type text, audience_label text, audience_plan_id text,
  is_important integer, is_pinned integer, status text,
  scheduled_at text, sent_at text, created_at text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists notification_settings (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  fee_reminder7_days integer, fee_reminder3_days integer, fee_reminder1_day integer,
  fee_reminder_due_today integer, fee_reminder_overdue integer,
  membership_reminder7_days integer, membership_reminder3_days integer, membership_reminder1_day integer,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);

create table if not exists app_settings (
  gym_id text not null references gyms(id) on delete cascade, key text not null,
  value text,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, key)
);

-- Kept for the client_app (member devices register FCM tokens anonymously).
create table if not exists member_device_tokens (
  id text primary key default gen_random_uuid()::text,
  gym_id text references gyms(id) on delete cascade,
  member_id text,
  fcm_token text not null unique,
  platform text default 'android',
  last_active_at text not null default now()::text,
  created_at text not null default now()::text
);

-- ---------- server change clock + indexes ----------
create or replace function public.touch_server_updated_at()
returns trigger language plpgsql as $$
begin
  new.server_updated_at := now();
  return new;
end $$;

do $$
declare
  tbl text;
  tables text[] := array[
    'gyms','admins','membership_packages','membership_plans','trainers','trainer_payouts',
    'members','memberships','membership_change_logs','trainer_change_logs','bills',
    'payments','receipts','expenses','events','announcements','notification_settings','app_settings'
  ];
begin
  foreach tbl in array tables loop
    execute format('drop trigger if exists trg_touch_%1$s on %1$I;', tbl);
    execute format('create trigger trg_touch_%1$s before insert or update on %1$I
                    for each row execute function public.touch_server_updated_at();', tbl);
    if tbl <> 'gyms' then
      execute format('create index if not exists idx_%1$s_sync on %1$I (gym_id, server_updated_at);', tbl);
    end if;
  end loop;
end $$;

-- ---------- Row Level Security ----------
create or replace function public.owns_gym(p_gym_id text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from gyms where id = p_gym_id and owner_id = auth.uid());
$$;

alter table gyms enable row level security;
drop policy if exists gyms_owner_all on gyms;
create policy gyms_owner_all on gyms for all to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

do $$
declare
  tbl text;
  tables text[] := array[
    'admins','membership_packages','membership_plans','trainers','trainer_payouts',
    'members','memberships','membership_change_logs','trainer_change_logs','bills',
    'payments','receipts','expenses','events','announcements','notification_settings','app_settings'
  ];
begin
  foreach tbl in array tables loop
    execute format('alter table %I enable row level security;', tbl);
    execute format('drop policy if exists %1$s_owner_all on %1$I;', tbl);
    execute format('create policy %1$s_owner_all on %1$I for all to authenticated
                    using (public.owns_gym(gym_id)) with check (public.owns_gym(gym_id));', tbl);
  end loop;
end $$;

-- client_app reads announcements of its gym without logging in.
drop policy if exists announcements_public_read on announcements;
create policy announcements_public_read on announcements for select to anon
  using (is_deleted = false and status = 'sent');

alter table member_device_tokens enable row level security;
drop policy if exists tokens_anon_upsert on member_device_tokens;
create policy tokens_anon_upsert on member_device_tokens for all to anon, authenticated
  using (true) with check (true);

-- Realtime for client_app
do $$ begin
  alter publication supabase_realtime add table announcements;
exception when duplicate_object then null;
end $$;

-- ---------- Storage (Phase 7: photos/logos) ----------
insert into storage.buckets (id, name, public)
values ('gym-media', 'gym-media', false)
on conflict (id) do nothing;

drop policy if exists "gym media owner access" on storage.objects;
create policy "gym media owner access" on storage.objects for all to authenticated
  using (bucket_id = 'gym-media' and public.owns_gym((storage.foldername(name))[1]))
  with check (bucket_id = 'gym-media' and public.owns_gym((storage.foldername(name))[1]));
```

### 3.2 Supabase dashboard settings (manual, document in `SUPABASE_SETUP.md`)
- **Authentication → Providers → Email:** enabled.
- **Authentication → Sign In / Up → "Confirm email":** turn **OFF** for v1 (so signup returns a session immediately). If it is kept ON, the signup screen must show "Check your email, then sign in" when `response.session == null` (already handled in Phase 5 code).
- **Authentication → Email templates → Reset password:** include `{{ .Token }}` (6-digit code) so password reset works in-app without deep links.

### 3.3 `client_app` impact
`client_app` reads `announcements` filtered by `gym_id` with the anon key — still allowed by `announcements_public_read`. `ClientSupabaseService.streamAnnouncements()` should also add `.eq('gym_id', gymId)` to the stream (it currently streams all gyms). No other client_app change is required.

### 3.4 Update `SUPABASE_SETUP.md` (repo root)
Replace the "paste URL/anon key in app settings" instructions with: run `mobile/supabase/migrations/001_offline_sync_schema.sql`, set the Auth settings from 3.2, create `mobile/env/supabase.json`, build with `--dart-define-from-file`. Remove the "auto-discovery by phone/email" description.

---

## Phase 4 — Sync engine and auth service

### 4.1 New file `lib/core/sync/sync_engine.dart`
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../database/app_database.dart';
import '../services/app_state_service.dart';
import 'cloud_mapper.dart';
import 'supabase_service.dart';
import 'sync_schema.dart';
import 'sync_tables.dart';

enum SyncPhase { disabled, signedOut, idle, syncing, offline, error }

class SyncStatus {
  final SyncPhase phase;
  final int pendingChanges;
  final DateTime? lastSyncedAt;
  final String? error;

  const SyncStatus({required this.phase, this.pendingChanges = 0, this.lastSyncedAt, this.error});
}

/// Offline-first sync between local SQLite and Supabase.
///
/// Push: drains `sync_outbox` (filled by SQLite triggers) in batches —
/// rows that still exist locally are upserted, rows that no longer exist are
/// soft-deleted in the cloud. Pull: fetches rows changed since each table's
/// `server_updated_at` cursor and applies them with triggers muted, skipping
/// rows that still have un-pushed local edits.
class SyncEngine {
  SyncEngine._internal();
  static final SyncEngine instance = SyncEngine._internal();

  static const _pushBatchSize = 500;
  static const _pullPageSize = 1000;
  static const _inClauseChunk = 200;

  final ValueNotifier<SyncStatus> status = ValueNotifier(const SyncStatus(phase: SyncPhase.idle));

  Timer? _debounce;
  Timer? _periodic;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _running = false;
  bool _rerunRequested = false;
  bool _started = false;
  final Map<String, Set<String>> _columnCache = {};

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) requestSync();
    });
    _periodic = Timer.periodic(const Duration(minutes: 3), (_) => requestSync());
    AppStateService.instance.addListener(_onAppStateChanged);
    requestSync(immediate: true);
  }

  void stop() {
    _debounce?.cancel();
    _periodic?.cancel();
    _connectivitySub?.cancel();
    AppStateService.instance.removeListener(_onAppStateChanged);
    _started = false;
  }

  void _onAppStateChanged() {
    switch (AppStateService.instance.lastEventType) {
      // Pure UI events, or the notifyAll() this engine itself fires after a pull.
      case AppStateEventType.themeChanged:
      case AppStateEventType.languageChanged:
      case AppStateEventType.listDisplayStyleChanged:
      case AppStateEventType.all:
      case null:
        return;
      default:
        requestSync();
    }
  }

  /// Debounced sync request; safe to call from anywhere, any number of times.
  void requestSync({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediate ? Duration.zero : const Duration(seconds: 2), () => syncNow());
  }

  Future<int> pendingCount() async {
    final db = await AppDatabase.instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(DISTINCT tableName || rowKey) FROM sync_outbox')) ?? 0;
  }

  Future<bool> syncNow() async {
    if (_running) {
      _rerunRequested = true;
      return false;
    }
    _running = true;
    try {
      final client = SupabaseService.instance.client;
      if (client == null) {
        await _emit(SyncPhase.disabled);
        return false;
      }
      final user = client.auth.currentUser;
      final gymId = await SupabaseConfig.getActiveGymId();
      if (user == null || gymId == null) {
        await _emit(SyncPhase.signedOut);
        return false;
      }
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        await _emit(SyncPhase.offline);
        return false;
      }

      await _emit(SyncPhase.syncing);
      await _push(client, gymId, user.id);
      final pulled = await _pull(client, gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());
      if (pulled > 0) AppStateService.instance.notifyAll();
      await _emit(SyncPhase.idle);
      return true;
    } on AuthException catch (e) {
      debugPrint('[SyncEngine] auth error: $e');
      await _emit(SyncPhase.signedOut, error: e.message);
      return false;
    } catch (e, stackTrace) {
      debugPrint('[SyncEngine] sync failed: $e\n$stackTrace');
      final offline = e.toString().contains('SocketException') || e.toString().contains('ClientException');
      await _emit(offline ? SyncPhase.offline : SyncPhase.error, error: e.toString());
      return false;
    } finally {
      _running = false;
      if (_rerunRequested) {
        _rerunRequested = false;
        requestSync();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Push
  // ---------------------------------------------------------------------------

  Future<void> _push(SupabaseClient client, String gymId, String ownerId) async {
    final db = await AppDatabase.instance.database;
    while (true) {
      final batch = await db.query('sync_outbox', orderBy: 'id ASC', limit: _pushBatchSize);
      if (batch.isEmpty) return;
      final maxId = batch.last['id'] as int;

      final keysByTable = <String, Set<String>>{};
      for (final r in batch) {
        keysByTable.putIfAbsent(r['tableName'] as String, () => <String>{}).add(r['rowKey'] as String);
      }

      try {
        for (final table in SyncTables.all) {
          final keys = keysByTable[table.local]?.toList();
          if (keys == null || keys.isEmpty) continue;

          final localRows = <Map<String, Object?>>[];
          for (var i = 0; i < keys.length; i += _inClauseChunk) {
            final chunk = keys.sublist(i, i + _inClauseChunk > keys.length ? keys.length : i + _inClauseChunk);
            localRows.addAll(await db.query(
              table.local,
              where: '"${table.key}" IN (${List.filled(chunk.length, '?').join(',')})',
              whereArgs: chunk,
            ));
          }

          if (localRows.isNotEmpty) {
            final payload = localRows
                .map((r) => CloudMapper.toCloud(table, r, gymId: gymId, ownerId: ownerId))
                .toList();
            await client.from(table.cloud).upsert(payload, onConflict: table.isGym ? 'id' : 'gym_id,${table.key}');
          }

          final present = localRows.map((r) => r[table.key].toString()).toSet();
          final deleted = keys.where((k) => !present.contains(k)).toList();
          if (deleted.isNotEmpty && !table.isGym) {
            await client
                .from(table.cloud)
                .update({'is_deleted': true})
                .eq('gym_id', gymId)
                .inFilter(table.key, deleted);
          }
        }
      } catch (e) {
        await db.rawUpdate(
          'UPDATE sync_outbox SET attempts = attempts + 1, lastError = ? WHERE id <= ?',
          [e.toString(), maxId],
        );
        rethrow;
      }

      // Entries enqueued after this batch was read have larger ids and stay queued.
      await db.delete('sync_outbox', where: 'id <= ?', whereArgs: [maxId]);
    }
  }

  // ---------------------------------------------------------------------------
  // Pull
  // ---------------------------------------------------------------------------

  /// Returns the number of remote rows applied locally.
  Future<int> _pull(SupabaseClient client, String gymId) async {
    final db = await AppDatabase.instance.database;
    var applied = 0;
    for (final table in SyncTables.all) {
      final cursorKey = 'pull_cursor:${table.local}';
      final cursor = await _getMeta(db, cursorKey);

      final rows = <Map<String, dynamic>>[];
      var from = 0;
      while (true) {
        var query = client.from(table.cloud).select().eq(table.isGym ? 'id' : 'gym_id', gymId);
        if (cursor != null) query = query.gt('server_updated_at', cursor);
        final page = await query
            .order('server_updated_at', ascending: true)
            .range(from, from + _pullPageSize - 1);
        rows.addAll(page);
        if (page.length < _pullPageSize) break;
        from += _pullPageSize;
      }
      if (rows.isEmpty) continue;

      applied += await _applyRemoteRows(db, table, rows);
      await _setMeta(db, cursorKey, rows.last['server_updated_at'] as String);
    }
    return applied;
  }

  Future<int> _applyRemoteRows(Database db, SyncTable table, List<Map<String, dynamic>> rows) async {
    final columns = await _localColumns(db, table.local);
    final pending = (await db.query(
      'sync_outbox',
      columns: ['rowKey'],
      where: 'tableName = ?',
      whereArgs: [table.local],
    ))
        .map((r) => r['rowKey'] as String)
        .toSet();

    var applied = 0;
    await db.transaction((txn) async {
      await SyncSchema.muted(txn, () async {
        for (final row in rows) {
          final local = CloudMapper.toLocal(table, row, columns);
          final key = local[table.key]?.toString();
          if (key == null || pending.contains(key)) continue; // un-pushed local edit wins
          if (row['is_deleted'] == true) {
            await txn.delete(table.local, where: '"${table.key}" = ?', whereArgs: [key]);
          } else {
            await txn.insert(table.local, local, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          applied++;
        }
      });
    });
    return applied;
  }

  // ---------------------------------------------------------------------------
  // Full restore (fresh install / new phone)
  // ---------------------------------------------------------------------------

  /// Replaces ALL local synced data with the cloud copy of [gymId].
  Future<({bool success, int restored, String? error})> restoreFromCloud(String gymId) async {
    final client = SupabaseService.instance.client;
    if (client == null || client.auth.currentUser == null) {
      return (success: false, restored: 0, error: 'Not signed in.');
    }
    try {
      final db = await AppDatabase.instance.database;
      await SyncSchema.wipeLocalData(db); // also removes seeded default packages/plans
      await SupabaseConfig.setActiveGymId(gymId);
      final restored = await _pull(client, gymId);
      await SupabaseConfig.setLastSyncAt(DateTime.now());
      AppStateService.instance.notifyAll();
      await _emit(SyncPhase.idle);
      return (success: true, restored: restored, error: null);
    } catch (e, stackTrace) {
      debugPrint('[SyncEngine] restoreFromCloud failed: $e\n$stackTrace');
      return (success: false, restored: 0, error: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Set<String>> _localColumns(Database db, String table) async {
    final cached = _columnCache[table];
    if (cached != null) return cached;
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final cols = info.map((c) => c['name'] as String).toSet();
    _columnCache[table] = cols;
    return cols;
  }

  Future<String?> _getMeta(Database db, String key) async {
    final rows = await db.query('sync_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _setMeta(Database db, String key, String value) async {
    await db.insert('sync_meta', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _emit(SyncPhase phase, {String? error}) async {
    status.value = SyncStatus(
      phase: phase,
      pendingChanges: await pendingCount(),
      lastSyncedAt: await SupabaseConfig.getLastSyncAt(),
      error: error,
    );
  }
}
```
Verify: `AppStateService.notifyAll()` sets `lastEventType = AppStateEventType.all` (check `lib/core/services/app_state_service.dart:107`). If it doesn't, make it do so — the engine relies on ignoring `all` to avoid a sync loop.

### 4.2 New file `lib/core/auth/auth_service.dart`
```dart
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
  String? get email => currentUser?.email;

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
```

### 4.3 Edit `lib/main.dart`
1. Imports: add `import 'core/sync/sync_engine.dart';`
2. Replace the Supabase init block with:
```dart
  // Initialize Supabase (non-fatal: without keys the app runs fully offline)
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }
```
(keep as is, it's already this shape) and **right before `runApp(...)`** add:
```dart
  // Start background offline-first sync (no-op until an account is linked)
  unawaited(SyncEngine.instance.start());
```
Add `import 'dart:async';` for `unawaited`.

### 4.4 Edit `lib/shared/navigation/main_navigation_screen.dart`
In `didChangeAppLifecycleState`, inside `if (state == AppLifecycleState.resumed)` add:
```dart
      SyncEngine.instance.requestSync(immediate: true);
```
And when `state == AppLifecycleState.paused`, also call `SyncEngine.instance.requestSync(immediate: true);` (best-effort flush before the OS suspends the app). Add the import.

---

## Phase 5 — Onboarding: signup / login / restore

### New flow

```
WelcomeScreen
 ├─ "Create Account"  → AccountAuthScreen(mode: signUp)
 │        └─ success → GymSetupScreen (email prefilled) → AdminSetup → MPIN → Biometric
 │                      → finish: save gym/admin locally → AuthService.registerNewGym() → Main
 ├─ "Sign In (Restore my gym)" → AccountAuthScreen(mode: signIn)
 │        └─ success → findMyGymId()
 │              ├─ found → restore progress → SyncEngine.restoreFromCloud(id)
 │              │           → MpinSetupScreen(restoreMode) → BiometricSetupScreen(restoreMode) → Main
 │              └─ not found → GymSetupScreen (same as signup path)
 └─ "Continue offline without account" (small text link) → GymSetupScreen (old behaviour, no cloud)
```
The MPIN stays as the **local quick-unlock** on every app open (`LoginScreen` unchanged). The Supabase session is the **account**; it is persisted by `supabase_flutter` and refreshed automatically, so the admin does not type the password again until they sign out or reinstall.

### 5.1 New file `lib/features/auth/account_auth_screen.dart`
`AccountAuthScreen({required AccountAuthMode mode})` where `enum AccountAuthMode { signUp, signIn }`.

UI (follow CLAUDE.md: `Scaffold(resizeToAvoidBottomInset: true)`, `SafeArea`, `SingleChildScrollView` with bottom padding `16 + MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom`):
- Title: `tr('auth_signup_title')` / `tr('auth_signin_title')`; subtitle explaining the account keeps the gym backed up.
- `CustomTextField` Email (`FormValidators.validateEmail`, required).
- `CustomTextField` Password (`obscureText`, min 6 chars, eye toggle via `suffixIcon`).
- Sign-up only: Confirm password.
- `NeonButton` primary (loading state).
- Sign-in only: "Forgot password?" `TextButton` → bottom sheet (`useSafeArea: true`, `isScrollControlled: true`, safe-area padding) with: email → "Send code" (`AuthService.sendPasswordResetCode`) → 6-digit code + new password → `resetPasswordWithCode`.
- Toggle link at bottom: "Already have an account? Sign in" / "New here? Create account" (replaces the route with the other mode).
- If `!AuthService.instance.isAvailable` show an inline error card "Cloud service not configured in this build".

Logic:
```dart
Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;
  setState(() => _isLoading = true);
  final email = _emailController.text.trim();
  final password = _passwordController.text;

  if (widget.mode == AccountAuthMode.signUp) {
    final res = await AuthService.instance.signUp(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (res.error != null) return _showError(res.error!);
    if (res.needsEmailConfirmation) {
      return _showInfo(tr('auth_confirm_email_message')); // stay on screen, switch to sign-in mode
    }
    // A brand-new account can't have a gym yet, but check anyway (e.g. user re-signed-up).
    await _routeAfterAuth(email);
  } else {
    final error = await AuthService.instance.signIn(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) return _showError(error);
    await _routeAfterAuth(email);
  }
}

Future<void> _routeAfterAuth(String email) async {
  setState(() => _isLoading = true);
  String? gymId;
  try {
    gymId = await AuthService.instance.findMyGymId();
  } catch (_) {}
  if (!mounted) return;
  setState(() => _isLoading = false);

  if (gymId == null) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => GymSetupScreen(prefillEmail: email)));
    return;
  }
  // Restore — show a non-dismissible progress dialog (reuse the style of the old
  // GymSetupScreen._restoreData dialog), then:
  final res = await SyncEngine.instance.restoreFromCloud(gymId);
  // dismiss dialog
  if (!res.success) { _showError(tr('auth_restore_failed', {'error': res.error ?? ''})); return; }
  final gym = await SettingsRepository().getGymInfo();
  final admin = await SettingsRepository().getAdminInfo();
  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
    builder: (_) => MpinSetupScreen.restore(gymName: gym.name, adminName: admin.name)), (r) => false);
  // SnackBar: tr('auth_restored_records', {'count': '${res.restored}', 'gym': gym.name})
}
```

### 5.2 Edit `lib/features/onboarding/welcome_screen.dart`
- Remove the `SupabaseSyncService` import, the whole `_RestoreGymSheet` class and `_openRestoreSheet`.
- Primary `NeonButton` "Get Started →" → text `tr('welcome_create_account')`, navigates to `AccountAuthScreen(mode: AccountAuthMode.signUp)`.
- The `TextButton.icon` (cloud icon) → text `tr('welcome_sign_in_restore')`, navigates to `AccountAuthScreen(mode: AccountAuthMode.signIn)`.
- Add a small muted `TextButton` below: `tr('welcome_continue_offline')` → `GymSetupScreen()` (no account).
- If `!AuthService.instance.isAvailable`, hide the two account buttons and show only the old "Get Started →" to `GymSetupScreen()`.
- Update the first `_FeatureRow` to: icon `Icons.cloud_sync_rounded`, title `Offline-First + Cloud Backup`, subtitle `Works without internet. Syncs to your account when online.`
- Update the hero paragraph text "…offline on your device." → "…works offline and backs up to your account."

### 5.3 Edit `lib/features/onboarding/gym_setup_screen.dart`
- Remove import of `supabase_sync_service.dart`, `security_service.dart`, `main_navigation_screen.dart` (if no longer used), field `_isCheckingCloud`, and the methods `_restoreData` and the cloud-lookup part of `_handleContinue`.
- Add optional constructor param `final String? prefillEmail;` and in `initState` set `_emailController.text = widget.prefillEmail ?? ''`.
- `_handleContinue` becomes: validate → `Navigator.push(... AdminSetupScreen(...))` exactly as the current bottom part.
- Button text back to `'Continue to Admin Setup →'` without the loading state.

### 5.4 Edit `lib/features/onboarding/mpin_setup_screen.dart`
Add a restore mode that needs no gym fields:
- Make the gym/admin fields nullable (`String?`) and add `final bool restoreMode;` (default `false`).
- Add named constructor:
```dart
  const MpinSetupScreen.restore({super.key, required String gymName, required String adminName})
      : gymName = gymName, adminName = adminName, restoreMode = true,
        ownerName = null, gymPhone = null, email = null, website = null,
        address = null, city = null, currency = null, adminPhone = null;
```
  (Adjust to whatever the final field list is; keep the existing positional usage working by keeping the original constructor with `required` params and `restoreMode = false`.)
- In `_proceed()` pass `restoreMode: widget.restoreMode` to `BiometricSetupScreen`.
- AppBar title: when `restoreMode` use `tr('restore_step_mpin')` ("RESTORE: SET MPIN") instead of "STEP 3 OF 4".

### 5.5 Edit `lib/features/onboarding/biometric_setup_screen.dart`
- Same nullable fields + `restoreMode` flag as MpinSetupScreen.
- In `_finishSetup`:
  - If `widget.restoreMode`: load `SettingsRepository().getAdminInfo()`, save it back with `isBiometricEnabled: enableBiometric` and `updatedAt: DateTime.now()` (this syncs automatically), then `setSetupComplete(true)` and go to `MainNavigationScreen`. Do **not** create `GymInfoModel`/`AdminModel` from widget fields.
  - Else (new gym): keep current code; after `repo.saveAdminInfo(admin)` add:
```dart
      // Bind this new gym to the signed-in account (if any) and queue all
      // data — including the seeded default packages/plans — for upload.
      if (AuthService.instance.isSignedIn) {
        await AuthService.instance.registerNewGym();
      }
```

### 5.6 `lib/features/auth/login_screen.dart` (MPIN unlock) — minimal change
No auth change. Optionally after successful unlock (just before `Navigator.pushAndRemoveUntil` at ~line 95) call `SyncEngine.instance.requestSync(immediate: true);`.

---

## Phase 6 — Settings: account & sync screen, sign-out, reset

### 6.1 Rewrite `lib/features/settings/data_connection_screen.dart` → "Cloud Account & Sync"
Keep the class name `DataConnectionScreen` (so `settings_screen.dart` navigation stays valid) or rename to `CloudSyncScreen` and update the import. Remove all URL/anon-key fields, `_testConnection`, `_saveCredentials`, `_pushLocalData`.

Layout (`ListView` padding `EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.paddingOf(context).bottom + 24)`):

**Card 1 — Account**
- Signed in: email (`AuthService.instance.email`), "Gym linked ✓".
- Not signed in (existing offline install): text "Create an account to back up this gym" + two buttons "Create Account" / "Sign In".
  - After auth returns successfully (push `AccountAuthScreen` with a new optional param `linkExistingLocalData: true`; in that mode `_routeAfterAuth` does NOT navigate into onboarding but pops with a result):
    - `findMyGymId()` == null → `AuthService.registerNewGym()` (uploads this device's data).
    - gym exists → `ConfirmationDialog` with two choices:
      - "Use cloud data (replace this phone's data)" → `SyncEngine.restoreFromCloud(id)`.
      - "Upload this phone's data into the cloud gym" → `SupabaseConfig.setActiveGymId(id)`, `SyncSchema.enqueueAll(db)`, `requestSync`.

**Card 2 — Sync status** (`ValueListenableBuilder<SyncStatus>` on `SyncEngine.instance.status`)
- Icon/colour per phase: idle ✓ (neon), syncing (spinner), offline (cloud_off, amber), error (red, show `error` with `maxLines: 2, overflow: ellipsis`), signedOut ("Sign in again").
- "Pending changes: N", "Last synced: dd MMM yyyy, hh:mm a" (`intl`).
- Buttons: "Sync Now" (`SyncEngine.instance.syncNow()`), "Re-download all data from cloud" (confirmation → `restoreFromCloud(gymId)`).

**Card 3 — Sign out**
- Red outlined button "Sign Out of This Device". If `pendingCount() > 0`, the confirmation message must warn: "N changes are not uploaded yet and will be lost. Connect to the internet and Sync Now first." On confirm: `await AuthService.instance.signOut(); await SecurityService().clearSecurityData();` then `pushAndRemoveUntil(WelcomeScreen)`.

### 6.2 Edit `lib/features/settings/settings_screen.dart`
- Remove `DataMode` / `DataModeService` usage (`_dataMode` field and its loading in `_loadSettings`).
- The "Data & Sync" tile: icon `Icons.cloud_sync_rounded`, title `tr('settings_cloud_sync')`, subtitle = signed in ? `tr('settings_cloud_sync_on', {'email': email})` : `tr('settings_cloud_sync_off')`; onTap → the screen from 6.1.
- `_resetData()`: change to
```dart
          final nav = Navigator.of(context);
          await AuthService.instance.signOut(); // signs out + clears local data; cloud backup is kept
          await SecurityService().clearSecurityData();
          nav.pushAndRemoveUntil(...WelcomeScreen...);
```
  and update the `settings_reset_message` translation to say the cloud backup is kept and can be restored by signing in again.

### 6.3 New widget `lib/shared/widgets/sync_status_badge.dart` (optional but recommended)
Small `ValueListenableBuilder<SyncStatus>` icon (cloud_done / cloud_upload with pending count / cloud_off) for the dashboard AppBar `actions` (`lib/features/dashboard/dashboard_screen.dart`). Tap → Cloud Sync screen. Hide when phase == `disabled`.

### 6.4 `lib/core/localization/app_translations.dart`
Add a new `// ===== AUTH & CLOUD SYNC =====` section with EN + HI for every new string used above, e.g.:
```dart
    'auth_signup_title': {'en': 'Create Your Account', 'hi': 'अपना अकाउंट बनाएं'},
    'auth_signin_title': {'en': 'Sign In', 'hi': 'साइन इन करें'},
    'auth_email': {'en': 'Email Address', 'hi': 'ईमेल पता'},
    'auth_password': {'en': 'Password', 'hi': 'पासवर्ड'},
    'auth_confirm_password': {'en': 'Confirm Password', 'hi': 'पासवर्ड की पुष्टि करें'},
    'auth_forgot_password': {'en': 'Forgot password?', 'hi': 'पासवर्ड भूल गए?'},
    'auth_confirm_email_message': {'en': 'We sent a confirmation link to your email. Confirm it, then sign in.', 'hi': 'आपके ईमेल पर पुष्टि लिंक भेजा गया है। पुष्टि करके साइन इन करें।'},
    'auth_restore_failed': {'en': 'Restore failed: {error}', 'hi': 'रिस्टोर विफल: {error}'},
    'auth_restored_records': {'en': 'Welcome back! Restored {count} records for {gym}.', 'hi': 'वापसी पर स्वागत है! {gym} के {count} रिकॉर्ड रिस्टोर हुए।'},
    'welcome_create_account': {'en': 'Create Account →', 'hi': 'अकाउंट बनाएं →'},
    'welcome_sign_in_restore': {'en': 'Already have an account? Sign in & restore', 'hi': 'पहले से अकाउंट है? साइन इन करके रिस्टोर करें'},
    'welcome_continue_offline': {'en': 'Continue offline without account', 'hi': 'बिना अकाउंट के ऑफलाइन जारी रखें'},
    'restore_step_mpin': {'en': 'RESTORE: SET MPIN', 'hi': 'रिस्टोर: MPIN सेट करें'},
    'settings_cloud_sync': {'en': 'Cloud Account & Sync', 'hi': 'क्लाउड अकाउंट और सिंक'},
    'settings_cloud_sync_on': {'en': 'Backed up to {email}', 'hi': '{email} पर बैकअप चालू'},
    'settings_cloud_sync_off': {'en': 'Not backed up — tap to create an account', 'hi': 'बैकअप नहीं — अकाउंट बनाने के लिए टैप करें'},
    'sync_now': {'en': 'Sync Now', 'hi': 'अभी सिंक करें'},
    'sync_pending': {'en': 'Pending changes: {count}', 'hi': 'बाकी बदलाव: {count}'},
    'sync_last': {'en': 'Last synced: {time}', 'hi': 'आखिरी सिंक: {time}'},
    'sync_offline': {'en': 'Offline — changes are saved on this phone and will sync automatically.', 'hi': 'ऑफलाइन — बदलाव फोन में सेव हैं, इंटरनेट आने पर अपने आप सिंक होंगे।'},
    'sync_sign_out': {'en': 'Sign Out of This Device', 'hi': 'इस डिवाइस से साइन आउट करें'},
```
Also update `settings_data_storage_mode*` keys or remove them if unused.

---

## Phase 7 — Photos & logo (Supabase Storage)

`photoPath` (members, trainers), `logoPath` (gym) and `imagePath` (announcements) are **absolute local file paths**; after reinstall the files are gone. Without this phase, text data restores fully but photos show the initials fallback.

### 7.1 New file `lib/core/sync/media_sync.dart`
- `static const _scheme = 'sb://gym-media/';`
- Map of media columns: `{'gym': 'logoPath', 'members': 'photoPath', 'trainers': 'photoPath', 'announcements': 'imagePath'}`.
- `Future<Map<String, dynamic>> uploadIfLocal(SyncTable t, Map<String, dynamic> cloudRow, String gymId)`: if the snake_case media column holds a local path whose `File` exists → upload to bucket `gym-media` at `'$gymId/${t.local}/${row id}${extension}'` with `client.storage.from('gym-media').upload(path, file, fileOptions: const FileOptions(upsert: true))` → replace the value in the **cloud row only** with `'sb://gym-media/<path>'`. Local DB keeps the local path.
- `Future<Map<String, Object?>> downloadIfRemote(SyncTable t, Map<String, Object?> localRow)`: if the value starts with `sb://gym-media/` → download bytes (`storage.from('gym-media').download(path)`), write into `getApplicationDocumentsDirectory()/profile_photos/<file>` (same folder `member_photo_picker.dart` uses), set the local column to that absolute path. On failure set the column to `null` (UI falls back to initials) and log.
- Cache: skip upload when `sync_meta['media:<table>:<id>']` equals the current local path (store it after a successful upload).

### 7.2 Hook into `SyncEngine`
- In `_push`, after building `payload`, `await Future.wait(payload.map((p) => MediaSync.uploadIfLocal(table, p, gymId)))` and use the results.
- In `_applyRemoteRows`, download **before** opening the transaction (network I/O must not run inside a sqflite transaction): map rows through `MediaSync.downloadIfRemote` first, then apply.
- Since the local row keeps a local path but the cloud has `sb://…`, a pull of our own row would replace a valid local path with the downloaded copy — acceptable (same image). To avoid re-downloads, `downloadIfRemote` skips download if the target file already exists.

---

## Phase 8 — Tests

### 8.1 `test/sync/cloud_mapper_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:the_elite_fitness/core/sync/cloud_mapper.dart';
import 'package:the_elite_fitness/core/sync/sync_tables.dart';

void main() {
  group('CloudMapper', () {
    test('camel <-> snake round trip, including digits', () {
      for (final key in ['feeReminder7Days', 'membershipReminder1Day', 'bankIfsc', 'isAutoGenerated', 'qrPayload']) {
        expect(CloudMapper.snakeToCamel(CloudMapper.camelToSnake(key)), key);
      }
    });

    test('gym row maps default id to cloud gym id and owner', () {
      final gym = SyncTables.byLocal('gym')!;
      final cloud = CloudMapper.toCloud(gym, {'id': 'default', 'name': 'X'}, gymId: 'g1', ownerId: 'u1');
      expect(cloud['id'], 'g1');
      expect(cloud['owner_id'], 'u1');
      expect(cloud.containsKey('gym_id'), isFalse);

      final local = CloudMapper.toLocal(gym, {...cloud, 'server_updated_at': 'x'}, {'id', 'name'});
      expect(local, {'id': 'default', 'name': 'X'});
    });

    test('child rows get gym_id and drop unknown columns on the way back', () {
      final members = SyncTables.byLocal('members')!;
      final cloud = CloudMapper.toCloud(members, {'id': 'm1', 'isArchived': 0}, gymId: 'g1', ownerId: 'u1');
      expect(cloud['gym_id'], 'g1');
      expect(cloud['is_archived'], 0);
      final local = CloudMapper.toLocal(members, {...cloud, 'future_column': 1}, {'id', 'isArchived'});
      expect(local, {'id': 'm1', 'isArchived': 0});
    });
  });
}
```

### 8.2 `test/sync/sync_schema_test.dart` (uses `sqflite_common_ffi`)
- `sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;` open in-memory DB, create `DbTables.members` and `DbTables.appSettings` + all other synced tables (loop over every `DbTables` constant used in `_createDB`), call `SyncSchema.ensure(db)`.
- Insert a member → expect 1 outbox row `('members', id, 'upsert')`.
- `insert(..., ConflictAlgorithm.replace)` same id → expect only `upsert` entries (no `delete`).
- Delete → expect a `delete` entry.
- Inside `db.transaction((txn) => SyncSchema.muted(txn, () => txn.insert(...)))` → expect **no** new outbox row.
- `SyncSchema.wipeLocalData(db)` → tables and outbox empty.
- `app_settings` insert → outbox `rowKey` equals the `key` value.

### 8.3 Existing tests
`test/widget_test.dart` / `models_and_features_test.dart` must still pass. If any test pumps `WelcomeScreen`, it must work when `SupabaseConfig.isConfigured == false` (no dart-defines in tests) — that's why WelcomeScreen falls back to the old button when `!AuthService.instance.isAvailable`.

---

## Phase 9 — Manual acceptance checklist (run on a real Android device)

1. **Fresh signup online:** Create account → gym setup → admin → MPIN → biometric. Supabase Table Editor shows a `gyms` row with your `owner_id`, `admins`, 3 packages, 12 plans, `notification_settings`.
2. **Add data online:** add member, payment (receipt), bill, expense, trainer, event, announcement → rows appear in Supabase within ~3 s.
3. **Offline writes:** airplane mode → add 2 members + 1 payment, edit one member, delete an expense. Cloud Sync screen shows "Offline", pending = 5-ish. Turn internet on → pending goes to 0 automatically; cloud shows new rows, edit, and `is_deleted = true` on the expense.
4. **Kill app while offline with pending changes** → reopen online → changes upload (outbox is persistent).
5. **Uninstall → reinstall → Sign in** with same email → "Restoring…" → set MPIN → dashboard shows the same members/payments/bills/expenses, no duplicate default packages, deleted expense stays deleted, bill & receipt numbering continues (next number after the last restored one).
6. **Wrong password / no internet on sign-in** → friendly error, nothing crashes.
7. **Security:** in a SQL query via the anon key without login (`curl https://<proj>.supabase.co/rest/v1/members -H "apikey: <anon>"`) → returns `[]`. A second test account cannot see the first account's gym.
8. **Reset data** in Settings → signs out, local wiped, cloud intact → sign in again restores everything.
9. **Existing offline user upgrade:** install the previous build, create data with no account, upgrade to the new build → data still there; Settings → Cloud Account & Sync → Create Account → all existing local data uploads.
10. `flutter analyze` → 0 issues; `flutter test` → all green.

---

## File change summary

| Action | File |
|---|---|
| edit | `mobile/pubspec.yaml` (connectivity_plus, sqflite_common_ffi dev) |
| edit | `mobile/android/app/src/main/AndroidManifest.xml` (INTERNET, ACCESS_NETWORK_STATE, allowBackup=false) |
| new | `mobile/env/supabase.example.json`, `mobile/env/supabase.json` (gitignored) |
| edit | `mobile/.gitignore` |
| rewrite | `lib/core/config/supabase_config.dart` |
| rewrite | `lib/core/sync/supabase_service.dart` |
| edit | `lib/core/sync/data_mode_service.dart` (`isOnline` → false) |
| delete | `lib/core/sync/supabase_sync_service.dart` |
| new | `lib/core/sync/sync_tables.dart` |
| new | `lib/core/sync/sync_schema.dart` |
| new | `lib/core/sync/cloud_mapper.dart` |
| new | `lib/core/sync/sync_engine.dart` |
| new | `lib/core/sync/media_sync.dart` (Phase 7) |
| new | `lib/core/auth/auth_service.dart` |
| edit | `lib/core/database/app_database.dart` (v9, `SyncSchema.ensure`, safe `clearAllData`) |
| edit | `lib/main.dart` (start SyncEngine) |
| edit | `lib/shared/navigation/main_navigation_screen.dart` (sync on resume/pause) |
| new | `lib/features/auth/account_auth_screen.dart` |
| edit | `lib/features/onboarding/welcome_screen.dart` |
| edit | `lib/features/onboarding/gym_setup_screen.dart` |
| edit | `lib/features/onboarding/mpin_setup_screen.dart` (restore mode) |
| edit | `lib/features/onboarding/biometric_setup_screen.dart` (restore mode, `registerNewGym`) |
| edit (optional) | `lib/features/auth/login_screen.dart` (requestSync after unlock) |
| rewrite | `lib/features/settings/data_connection_screen.dart` (Cloud Account & Sync) |
| edit | `lib/features/settings/settings_screen.dart` (tile, reset → signOut) |
| new (optional) | `lib/shared/widgets/sync_status_badge.dart` + dashboard AppBar |
| edit | `lib/core/localization/app_translations.dart` |
| new | `mobile/supabase/migrations/001_offline_sync_schema.sql` |
| delete | `mobile/supabase_schema.sql`, `supabase_schema.sql` (root) |
| edit | `SUPABASE_SETUP.md` (root) |
| edit (small) | `client_app/lib/core/services/client_supabase_service.dart` (stream filtered by gym_id) |
| new | `test/sync/cloud_mapper_test.dart`, `test/sync/sync_schema_test.dart` |
| **unchanged** | all `lib/data/repositories/*.dart`, all models, all other feature screens |

## Known limitations (acceptable for v1)
- One gym per account (`gyms.owner_id` is unique). Multi-branch support would need a gym picker.
- Bill/receipt numbers are generated locally; if two phones are used **simultaneously** offline on the same account they could generate the same number. Single-admin usage is the assumption.
- Sync runs while the app is open (foreground + on resume/pause). True background sync (app closed) would need `workmanager` — can be added later by calling `SyncEngine.instance.syncNow()` from a periodic task.
- Device-local notification history (`notifications` table) is not backed up; reminders are regenerated by `ReminderScheduler`.
