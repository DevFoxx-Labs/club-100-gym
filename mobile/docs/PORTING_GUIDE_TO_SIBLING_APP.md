# Porting Guide — Supabase Offline-First Sync, Partial Payments, MPIN Hardening & Release Setup

**Purpose:** reproduce in a sibling Flutter app (built from the same codebase) every change made to
`club-100-gym/mobile` between commits **`dbcbab8`** (before) and **`380a9e2`** (after).

**Written for:** an AI coding agent (Antigravity) working inside the **target app**, with read access to
the source repo on the same machine.

| | Path | Notes |
|---|---|---|
| **SRC** (reference, already done) | `E:\ProjectsFromDevFoxxLabs\MobileApps\club-100-gym\mobile` | git repo root is the parent folder; files live under `mobile/` |
| **DST** (to change) | `E:\ProjectsFromDevFoxxLabs\MobileApps\GymYard\GymYardHQ` | Dart package name `gymyardhq` |

---

## 0. How to work (read first)

1. **Every change has an exact reference.** To see what changed in a file, run from the SRC repo root:
   ```powershell
   git -C E:\ProjectsFromDevFoxxLabs\MobileApps\club-100-gym diff dbcbab8 380a9e2 -- mobile/<path>
   ```
   and to read the final version:
   ```powershell
   git -C E:\ProjectsFromDevFoxxLabs\MobileApps\club-100-gym show 380a9e2:mobile/<path>
   ```
2. Files are in three groups (section 2). **Group A/B: copy. Group C: apply the diff by hand** — DST has
   diverged slightly (more `tr()` localization, a different reminder system, app branding). Never paste a
   whole SRC file over a Group C file.
3. Keep DST's own branding (`GymYardHQ`), its existing `tr('...')` keys, its reminder engine
   (`reminder_engine.dart`, `reminder_planner.dart`, `background_reminders.dart`) and its extra DB tables.
4. Follow DST's `CLAUDE.md` / project rules (safe-area padding, `Expanded` in rows, `.withValues(alpha:)`).
5. Work phase by phase (section 4). After each phase: `flutter analyze` must report **0 issues** and
   `flutter test` must pass.
6. Do **not** modify DST repositories other than `bill_repository.dart` / `payment_repository.dart`.
   Cloud sync is captured by SQLite triggers, so other repositories need no changes.

---

## 1. What the feature set does (so the result can be verified)

1. **Account & cloud backup (Supabase).** Admin signs up / signs in with email + password during
   onboarding. Each account owns one gym in Supabase, protected by row-level security (an owner only
   sees their own gym).
2. **Offline-first sync.** Every write goes to SQLite first. SQLite triggers record each change in a
   `sync_outbox` table; `SyncEngine` pushes it to Supabase within ~5 s when online, retries with backoff
   when offline, and pulls remote changes by a per-table `server_updated_at` cursor. Reads always come
   from SQLite.
3. **Restore after reinstall / new phone.** Sign in → all data downloads → set MPIN → dashboard.
4. **Safe sign-out / reset.** Uploads pending changes first, warns if some would be lost, wipes only the
   phone (cloud kept).
5. **Partial payments (installments).** A bill can be paid in parts; balance shows on payment screen,
   bill detail (with installment list), bills list, member profile ("total balance due"), receipt
   ("PART PAID", bill total, balance due), bill PDF and UPI QR (asks only for the balance). All payment
   writes are one SQLite transaction.
6. **MPIN.** Exactly 4 digits (legacy 5/6-digit MPINs unlock once, then must be changed); lockout after 5
   wrong attempts (30 s, doubling, max 15 min, survives app restart); **Forgot MPIN** via account
   password, fingerprint, or sign-out-and-reset.
7. **Release.** Signed builds via `scripts/build_release.ps1` (DST ships an AAB to the Play Store — §7.7).
8. **DST only — multi-tenant SaaS requirements:** see §7 (mandatory account, email verification,
   in-app account deletion, tenant isolation on shared phones, RLS performance, member-app isolation).

---

## 2. File inventory

### Group A — NEW files: copy from SRC `380a9e2`, then apply the listed edits

| File (relative to app root) | Edits needed in DST |
|---|---|
| `lib/core/config/supabase_config.dart` | none |
| `lib/core/sync/supabase_service.dart` | none |
| `lib/core/sync/sync_tables.dart` | none (see §3.3 — `reminder_ledger` must NOT be added) |
| `lib/core/sync/sync_schema.dart` | none |
| `lib/core/sync/cloud_mapper.dart` | none |
| `lib/core/sync/sync_engine.dart` | none |
| `lib/core/sync/media_sync.dart` | none |
| `lib/core/auth/auth_service.dart` | none |
| `lib/features/auth/account_auth_screen.dart` | none (uses `tr()` keys added in Phase 8) |
| `lib/features/auth/forgot_mpin_screen.dart` | none |
| `lib/features/settings/sign_out_flow.dart` | none |
| `lib/shared/widgets/sync_status_badge.dart` | none |
| `supabase/migrations/001_offline_sync_schema.sql` | **add 4 columns** to `notification_settings` — see §3.2 |
| `supabase/migrations/002_harden_device_tokens.sql` | none |
| `supabase/migrations/003_receipt_balance_snapshot.sql` | none |
| `env/supabase.example.json` | none. Also create `env/supabase.json` (gitignored) with real values |
| `android/key.properties.example` | none |
| `scripts/build_release.ps1` | replace `EliteFitness` with `GymYardHQ` (4 places) |
| `RELEASE.md` | replace "Elite Fitness" with "GymYardHQ", keystore name `gymyardhq-upload.jks` |
| `test/localization_keys_test.dart` | `package:the_elite_fitness/` → `package:gymyardhq/` |
| `test/payments/partial_payment_test.dart` | same package rename |
| `test/security/mpin_lockout_test.dart` | same package rename |
| `test/sync/cloud_mapper_test.dart` | same package rename |
| `test/sync/sync_schema_test.dart` | same package rename |

### Group B — EXISTING files that are identical in DST and SRC-before: replace with SRC `380a9e2` version

These DST files are byte-for-byte equal to SRC at `dbcbab8`, so the final SRC file can be copied over
them unchanged:

```
lib/core/billing/bill_pdf_service.dart
lib/core/receipt/receipt_pdf_service.dart
lib/core/security/security_service.dart      (keep the 'club100gym' salt string — changing it breaks existing MPINs)
lib/core/sync/data_mode_service.dart
lib/data/models/bill_model.dart
lib/data/models/payment_model.dart
lib/data/models/receipt_model.dart
lib/data/repositories/bill_repository.dart
lib/data/repositories/payment_repository.dart
lib/features/bills/bills_list_screen.dart
lib/shared/widgets/status_badge.dart
.gitignore                                    (adds env/supabase.json and /dist/)
```

Before copying, confirm each is still identical:
```powershell
git -C E:\ProjectsFromDevFoxxLabs\MobileApps\club-100-gym show dbcbab8:mobile/<path> > $env:TEMP\base.dart
fc.exe /W $env:TEMP\base.dart E:\ProjectsFromDevFoxxLabs\MobileApps\GymYard\GymYardHQ\<path>
```
If `fc` reports differences, treat the file as Group C instead.

### Group C — EXISTING files that diverged: apply the SRC diff by hand

Get the diff with the command in §0.1. Specific notes per file are in section 4.

```
pubspec.yaml
android/app/build.gradle
android/app/src/main/AndroidManifest.xml
lib/main.dart
lib/core/database/app_database.dart
lib/core/database/db_tables.dart
lib/core/backup/backup_service.dart
lib/core/localization/app_translations.dart
lib/core/notifications/reminder_scheduler.dart   (+ DST-only reminder_engine.dart — see 4.6)
lib/core/utils/form_validators.dart
lib/features/auth/login_screen.dart
lib/features/bills/bill_detail_screen.dart
lib/features/dashboard/dashboard_screen.dart
lib/features/members/member_profile_screen.dart
lib/features/notifications/notifications_screen.dart
lib/features/onboarding/welcome_screen.dart
lib/features/onboarding/gym_setup_screen.dart
lib/features/onboarding/mpin_setup_screen.dart
lib/features/onboarding/biometric_setup_screen.dart
lib/features/payments/add_payment_screen.dart
lib/features/receipts/receipt_preview_screen.dart
lib/features/settings/change_mpin_screen.dart
lib/features/settings/data_connection_screen.dart (replaced entirely — see 4.7)
lib/features/settings/settings_screen.dart
lib/shared/navigation/main_navigation_screen.dart
test/models_and_features_test.dart
```

No change needed: `client_app/` (SRC-only companion app). If DST has its own client app, see §5.

---

## 3. DST-specific differences you MUST handle

### 3.1 Database version
DST's `app_database.dart` is already at `version: 9` (its `oldVersion < 9` block creates
`reminder_ledger` and event-reminder columns). SRC bumped 8 → 9. **In DST bump 9 → 10.**
The new columns/tables in this port are added with idempotent `try { ALTER TABLE … }` blocks inside
`_initDB` (same pattern as SRC), so they need no `onUpgrade` branch, but the version must still increase.

### 3.2 Cloud schema: extra `notification_settings` columns
DST's `notification_settings` has 4 extra columns. The sync engine pushes **every** local column, and
Supabase rejects unknown columns, so without these the push fails for that table. In DST's copy of
`001_offline_sync_schema.sql`, change the `notification_settings` table to:

```sql
create table if not exists notification_settings (
  gym_id text not null references gyms(id) on delete cascade, id text not null,
  fee_reminder7_days integer, fee_reminder3_days integer, fee_reminder1_day integer,
  fee_reminder_due_today integer, fee_reminder_overdue integer,
  membership_reminder7_days integer, membership_reminder3_days integer, membership_reminder1_day integer,
  event_reminders integer, event_reminder30_min integer, event_reminder15_min integer, event_reminder_at_start integer,
  is_deleted boolean not null default false, server_updated_at timestamptz not null default now(),
  primary key (gym_id, id)
);
```
(Column names are produced by `CloudMapper.camelToSnake`: `eventReminder30Min` → `event_reminder30_min`.)
Also change the header comment "Elite Fitness" → "GymYardHQ".

**Rule for the future:** whenever a column is added to a synced SQLite table in DST, add the snake_case
column to the cloud table too (new migration `00N_….sql` with `alter table … add column if not exists`).

Run this check after porting to catch any other mismatch: for each table in `SyncTables.all`, every
`PRAGMA table_info(<table>)` column of the DST SQLite DB must exist (snake_case) in the SQL file.

### 3.3 Device-local tables are not synced
`reminder_ledger`, `notifications`, `dismissed_notifications`, `notification_fire_markers` stay out of
`SyncTables.all`. `clearAllData()` (§4.2) must also clear DST's `reminder_ledger`.

### 3.4 Reminder system
SRC keeps all reminder logic in `ReminderScheduler.runDailyScan()`. DST moved the fee/expiry reminder
planning into `ReminderEngine._buildPlan()` + `ReminderPlanner`. Port the partial-payment reminder
logic there (see §4.6). DST's `background_reminders.dart` runs in a background isolate: its SQLite writes
(e.g. auto-generated renewal bills) are captured by the triggers and uploaded the next time the app is
in the foreground — no change needed there.

### 3.5 Package name and branding
`package:the_elite_fitness/` → `package:gymyardhq/` in all copied tests. Keep DST's app name strings.
Keep DST's DB file name as it is (`club_100_gym.db`).

---

## 4. Phases (in order)

### Phase 1 — Dependencies, Android, keys

**`pubspec.yaml`** (diff it). Add:
```yaml
dependencies:
  supabase_flutter: ^2.17.2
  connectivity_plus: ^6.1.0
dependency_overrides:
  sqlite3: 2.4.6        # needed by sqflite_common_ffi in tests; keep DST's existing overrides
dev_dependencies:
  sqflite_common_ffi: ^2.3.4
```
Run `flutter pub get`.

**`android/app/src/main/AndroidManifest.xml`:**
- add `<uses-permission android:name="android.permission.INTERNET" />` and
  `<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />`
- on `<application>` add `android:allowBackup="false"` and `android:fullBackupContent="false"`
  (Android Auto Backup restores the secure-storage file without its Keystore key and breaks the MPIN).

**`android/app/build.gradle`:** copy SRC's `keystoreProperties` block (top of file) and the
`signingConfigs { release … }` + `buildTypes.release` change: use `signingConfigs.release` when
`android/key.properties` exists, otherwise warn and fall back to debug. Keep DST's `namespace` and
`applicationId` (`com.devfoxxlabs.gymyardhq`).

**`.gitignore`:** Group B (adds `env/supabase.json`, `/dist/`).

Copy `env/supabase.example.json`, `android/key.properties.example`, `scripts/build_release.ps1`,
`RELEASE.md` (Group A edits).

### Phase 2 — Local sync infrastructure

Copy Group A: `supabase_config.dart`, `supabase_service.dart`, `sync_tables.dart`, `sync_schema.dart`,
`cloud_mapper.dart`, `media_sync.dart`, `sync_engine.dart`.

**`lib/core/sync/data_mode_service.dart`** (Group B): `isOnline` now always returns `false` — the Mongo
"Online" mode is retired, every repository takes its SQLite branch.

**`lib/core/database/db_tables.dart`:** in the `receipts` table add `billTotal REAL, balanceDue REAL`
after `createdAt`. **Also** (from the partial-payment base, which DST does not have yet) add to
`payments`: `billId TEXT` (after `membershipId`), and to `bills`: `paidAmount REAL NOT NULL DEFAULT 0`
(after `status`). Check the SRC final file for exact placement.

**`lib/core/database/app_database.dart`:**
1. `import '../sync/sync_schema.dart';`
2. `version: 9` → **`version: 10`** (§3.1).
3. In `_initDB`, alongside the existing idempotent `ALTER TABLE` blocks, add (each in its own `try/catch`):
   ```dart
   ALTER TABLE bills ADD COLUMN paidAmount REAL NOT NULL DEFAULT 0;
   ALTER TABLE payments ADD COLUMN billId TEXT;
   UPDATE bills SET paidAmount = amount WHERE status = 'Paid' AND paidAmount = 0;   // backfill
   ALTER TABLE receipts ADD COLUMN billTotal REAL;
   ALTER TABLE receipts ADD COLUMN balanceDue REAL;
   ```
4. As the **last statement before `return db;`** (after every other self-heal block, so seeded default
   packages/plans are not queued on their own):
   ```dart
   await SyncSchema.ensure(db);
   ```
5. Replace `clearAllData()` with:
   ```dart
   Future<void> clearAllData() async {
     final db = await instance.database;
     await SyncSchema.wipeLocalData(db);          // never generates cloud deletes
     await db.delete('notifications');
     await db.delete('dismissed_notifications');
     await db.delete('notification_fire_markers');
     await db.delete('reminder_ledger');          // DST-only table
   }
   ```
   ⚠️ **Critical:** the old `clearAllData()` deletes rows one table at a time; with the triggers in place
   that would queue a cloud delete for every row and wipe the user's backup.

**`lib/core/backup/backup_service.dart`:** add only the doc comment from the SRC diff (local-file restore
is now mirrored to the cloud). No code change.

Copy tests `test/sync/sync_schema_test.dart`, `test/sync/cloud_mapper_test.dart` (package rename).

### Phase 3 — Supabase project (manual, by the developer)

Follow DST's `RELEASE.md` §1: run `001` (with §3.2 edit, and §7.5 policies), then `004` (§7.3); set Auth → Email enabled, "Confirm email" **ON** (multi-tenant — §7.2),
Reset Password template containing `{{ .Token }}`, **custom SMTP** (otherwise reset codes never reach real
users), copy Project URL + anon/publishable key into `env/supabase.json`. **Use a separate Supabase
project for DST**; all DST tenants share that one project (see §7).

### Phase 4 — Auth service & app wiring

Copy `lib/core/auth/auth_service.dart`.

**`lib/main.dart`** (DST differs: it initializes `ReminderEngine` / `BackgroundReminders`; keep those):
- `import 'dart:async';`, `import 'core/sync/supabase_service.dart';`, `import 'core/sync/sync_engine.dart';`
- Early in `main()` (before notifications), non-fatal:
  ```dart
  try {
    await SupabaseService.instance.init();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }
  ```
- Right before `runApp(...)`: `unawaited(SyncEngine.instance.start());`

**`lib/shared/navigation/main_navigation_screen.dart`:** import `sync_engine.dart`; in
`didChangeAppLifecycleState`: on `resumed` call `SyncEngine.instance.requestSync(immediate: true);`
(first line), and add `else if (state == AppLifecycleState.paused) { SyncEngine.instance.requestSync(immediate: true); }`.
Keep DST's existing resume logic and `tr('nav_…')` labels.

**`lib/features/dashboard/dashboard_screen.dart`:** add `const SyncStatusBadge()` to the AppBar
`actions` (see SRC diff, 2 lines) and its import.

### Phase 5 — Onboarding: sign up / sign in / restore

Copy `lib/features/auth/account_auth_screen.dart`.

**`welcome_screen.dart`:** remove any phone/email "restore" bottom sheet if present. Primary button →
`AccountAuthScreen(initialMode: AccountAuthMode.signUp)`; text button "Already have an account? Sign
in & restore" → `AccountAuthScreen(initialMode: AccountAuthMode.signIn)`; small "Continue offline without
account" → `GymSetupScreen()`. When `!AuthService.instance.isAvailable` (no keys in the build) show only
the old "Get Started" → `GymSetupScreen()`. Keep DST's `tr()` labels for existing strings.

**`gym_setup_screen.dart`:** add optional `final String? prefillEmail;` constructor param and set
`_emailController.text = widget.prefillEmail ?? ''` in `initState`. Remove any cloud lookup by
phone/email (security hole: anyone could restore someone else's gym). Keep DST's `tr()` strings.

**`mpin_setup_screen.dart`:**
- gym/admin fields nullable; add `final bool restoreMode;` and the named constructor
  `MpinSetupScreen.restore({required gymName, required adminName})` (see SRC).
- pass `restoreMode` to `BiometricSetupScreen`; restore-mode AppBar title `tr('restore_step_mpin')`.
- **4-digit MPIN:** max length `SecurityService.mpinLength`; auto-advance when 4 digits entered; error
  `tr('mpin_must_be_4')`; hint `tr('mpin_setup_hint')`; 4 indicator dots; button enabled only at 4.

**`biometric_setup_screen.dart`:** nullable fields + `restoreMode`. In `_finishSetup`:
- restore mode: load admin, save it with the chosen `isBiometricEnabled`, `setSetupComplete(true)`, go to
  `MainNavigationScreen`; do not create gym/admin from widget fields.
- normal mode: after saving gym + admin add
  ```dart
  if (AuthService.instance.isSignedIn) {
    await AuthService.instance.registerNewGym();
  }
  ```

### Phase 6 — Settings: cloud screen, sign-out, reset

Copy `lib/features/settings/sign_out_flow.dart`.

**`data_connection_screen.dart`:** DST's version is the old MongoDB screen. **Replace the whole file**
with SRC `380a9e2` (Cloud Account & Sync: account card, link-existing-data flow, sync status, Sync Now,
Re-download, Sign Out). DST's Mongo-specific `tr()` keys become unused — leave them in the translations.

**`settings_screen.dart`:** remove `DataMode` / `DataModeService` usage; the Data & Sync tile shows
`AuthService` email or `tr('settings_cloud_sync_off')` and opens `DataConnectionScreen`;
`_resetData()` becomes:
```dart
Future<void> _resetData() async {
  await runSignOutFlow(
    context,
    title: tr('settings_reset_title'),
    message: tr('settings_reset_message'),
    confirmLabel: tr('settings_reset_confirm'),
  );
}
```
and import `sign_out_flow.dart`; drop now-unused imports.

### Phase 7 — Partial payments

DST does **not** have the partial-payment base (SRC commit `e37ebe7`: `bills.paidAmount`,
`payments.billId`, `applyPaymentToBill`, "Partially Paid" status). The diff `dbcbab8..380a9e2` contains
both the base and the hardening — apply all of it.

1. **Models / repositories (Group B — copy):** `bill_model.dart` (`paidAmount`, `remainingBalance`,
   `isPartiallyPaid`, `isDue` incl. Partially Paid, `displayAmount`, `BillModel.money()`),
   `payment_model.dart` (`billId`), `receipt_model.dart` (`billTotal`, `balanceDue`, `isInstallment`,
   `leavesBalance`), `bill_repository.dart` (`applyPaymentToBill`, `applyPaymentInTxn`,
   `getOldestDueBillForMembership` incl. Partially Paid, `getOutstandingForMembership`,
   `getOutstandingForMember`, `getPartiallyPaidBills`; `markBillPaid` is gone),
   `payment_repository.dart` (`getPaymentsByBill`, atomic `recordPayment`, `PaymentRejected`).
   After copying, `grep -r markBillPaid lib` must return nothing.
2. **`status_badge.dart`, `bills_list_screen.dart`, `bill_pdf_service.dart`, `receipt_pdf_service.dart`**
   (Group B — copy).
3. **`add_payment_screen.dart`** (Group C, 23 lines diverged — likely `tr()` strings). Port from the SRC
   final file:
   - state: `_resolvedBill`, `_membershipFee`, helpers `_fmt`, `_enteredAmount`, `_owedBefore`,
     `_balanceAfter`, `_isPartial`, `_setAmount`; `_resolveOutstandingBill()` when no bill passed;
     `_resolveBasePlanFee()` must not overwrite a bill's balance.
   - UI: bill/cycle summary card (total / already paid / balance), amount validator capped at the bill
     balance, "Full ₹X" / "Half ₹Y" chips, live "balance after this payment" box with partial notes.
   - save: regenerate receipt number at save time; if no open bill and amount < cycle fee, create a
     full-fee bill (`newBill`); keep the membership's full `personalTrainingFee`; call
     `_paymentRepo.recordPayment(...)` (one transaction); handle `PaymentRejected` and generic errors with
     a snackbar (never fail silently).
4. **`bill_detail_screen.dart`:** installment list (`getPaymentsByBill`, tap → `ReceiptPreviewScreen`),
   UPI QR amount = remaining balance, amounts via `_money`, overdue-balance warning, button
   "Collect Balance ₹X" after a part payment, cancel only for Pending/Overdue.
5. **`member_profile_screen.dart`:** `_totalOutstanding` getter + red "TOTAL BALANCE DUE" banner; each
   bill row shows `BillModel.money(bill.displayAmount)` and "Paid ₹X of ₹Y" when partially paid.
6. **`receipt_preview_screen.dart`:** "PART PAID" badge when `leavesBalance`; hide PT split for
   installments; Bill Total + Balance Due rows. Keep DST's `tr()` labels.
7. **`notifications_screen.dart`:** add the `p.type == 'BALANCE_DUE'` branch (amber, wallet icon,
   badge "BALANCE DUE") before the `DUE_TODAY` branch. DST's file differs by 103 lines — insert only
   this branch.

Copy `test/payments/partial_payment_test.dart` (package rename). It opens the real `AppDatabase` through
`sqflite_common_ffi`, so it also verifies the DB migrations and triggers.

### Phase 8 — Reminders for balances (DST-specific)

**`reminder_engine.dart` → `_buildPlan()`:** replace
```dart
final paid = await paymentRepo.getTotalPaidForMembership(membership.id);
… amountDue: membership.feeAmount - paid,
```
with a bill-based amount (payments from earlier cycles must not make a new cycle look paid):
```dart
final outstanding = await BillRepository().getOutstandingForMembership(membership.id);
final double amountDue;
if (outstanding != null) {
  amountDue = outstanding;
} else {
  // Memberships created before billing existed: fall back to payments.
  final paid = await paymentRepo.getTotalPaidForMembership(membership.id);
  amountDue = membership.feeAmount - paid;
}
… amountDue: amountDue,
```
In `reminder_planner.dart`, format money with `BillModel.money(input.amountDue)` instead of
`toStringAsFixed(0)` so paise balances read correctly.

**Optional — weekly "Balance Pending" reminder** (SRC `reminder_scheduler.dart`, rule `BALANCE_DUE`): for
each bill from `BillRepository.getPartiallyPaidBills()` whose due date is ≥7 days ago and
`daysSinceDue % 7 == 0`, notify "X still owes ₹Y on bill N (paid ₹A of ₹B)". In DST implement it as a
planner milestone with ledger key `balance:<billId>:<yyyy-MM-dd>` so the ledger guarantees one push.

`reminder_scheduler.dart` in DST: no other change needed (renewal bills + overdue refresh stay as they are).

### Phase 9 — MPIN: 4 digits, lockout, Forgot MPIN

1. **`security_service.dart`** (Group B — copy): `mpinLength = 4`, `legacyMaxLength = 6`,
   `isLegacyMpin()`, stores the length on `setMPIN`, lockout API (`registerFailedAttempt`,
   `getLockRemaining`, `remainingFreeAttempts`, `clearFailedAttempts`).
2. **`login_screen.dart`** (77 lines diverged: DST uses `tr('login_…')` keys — keep them):
   - fields `_lockLeft`, `_lockTimer`, `_legacyMpin`, `_maxLen`; `_startLockCountdown`; `dispose` cancels the timer.
   - `_onKeyPress` blocks while locked and caps at `_maxLen`; auto-verify at `_maxLen`.
   - `_verifyMpin`: on success `clearFailedAttempts()`; on failure `registerFailedAttempt()`, show
     `tr('mpin_incorrect_attempts', {'count': …})`, start countdown when locked.
   - biometric success also clears failed attempts.
   - `_navigateToDashboard`: if `_legacyMpin` → snackbar `tr('mpin_upgrade_to_4')` and push
     `ChangeMpinScreen(resetMode: true)`.
   - indicator dots: `List.generate(_maxLen, …)`.
   - **Remove** `_showNeedHelpModal` / `_buildHelpItem` and the gym phone/email/owner fields; both
     "Need Help?" and "Forgot MPIN?" call `_openForgotMpin()` → `ForgotMpinScreen`.
3. **`change_mpin_screen.dart`:** `resetMode` param (skips current MPIN, goes to dashboard after save),
   new **confirm** step, auto-advance at full length, `_legacyMpin` lets step 0 accept 6 digits, new
   MPIN always 4 digits.
4. Copy `lib/features/auth/forgot_mpin_screen.dart` (account password / fingerprint / sign-out-and-reset).
5. **`form_validators.dart`:** `validateMpin` accepts exactly 4 digits (`^\d{4}$`, message
   "MPIN must be exactly 4 digits"). DST's file diverged by 74 lines — change only this function.
6. **`test/models_and_features_test.dart`:** `validateMpin('123456')` and `validateMpin('12345')` now
   expect `isNotNull`. Copy `test/security/mpin_lockout_test.dart` (package rename).

### Phase 10 — Translations

DST's `app_translations.dart` diverged heavily (676 lines) — **do not copy the file**. Instead copy these
SRC sections (EN + HI) to the end of DST's map, skipping any key DST already has:

- `// ===== AUTH & CLOUD SYNC =====` (`auth_*`, `welcome_*`, `restore_step_*`, `settings_cloud_sync*`, `sync_*`)
- `// ===== AUTH SCREEN =====` (`auth*` camelCase keys)
- `// ===== CLOUD ACCOUNT & SYNC SCREEN =====` (`cloud_*`, `signout_*`)
- `// ===== SYNC STATUS =====`
- `// ===== PARTIAL PAYMENTS / INSTALLMENTS =====`
- the partial-payment base keys: `bill_status_partially paid`, `bill_detail_bill_amount`,
  `bill_detail_balance_remaining`, `add_payment_bill_total`, `add_payment_already_paid`,
  `add_payment_balance_remaining`, `add_payment_amount_exceeds_balance`
- `// ===== MEMBERS LIST / GENERATE BILL (previously missing) =====` — only keys DST doesn't already define
- `// ===== FORGOT / RESET MPIN =====`
- `// ===== 4-DIGIT MPIN =====`
- updated texts: `settings_change_mpin_sub` ("4-digit"), `settings_reset_message` (cloud backup kept),
  the help-center onboarding text ("4-digit PIN") and `help_topic_login_mpin_body` (new Forgot MPIN flow)

Then copy `test/localization_keys_test.dart` (package rename) and run it — it lists every `tr('…')` key
used in `lib/` that is missing or lacks EN/HI. Repeat until it passes.

---

## 5. Optional: companion member app

SRC's `client_app` reads announcements anonymously. If DST has a similar member app, port the
`client_app/lib/core/services/client_supabase_service.dart` change: the realtime stream uses
`primaryKey: ['gym_id', 'id']` and filters `.eq('gym_id', gymId)`. RLS policy
`announcements_public_read` in `001` allows exactly that.

---

## 6. Acceptance checklist

Automated (must all pass):
- `flutter analyze` → **No issues found**
- `flutter test` → all green, including the 5 copied test files
- `grep -r "markBillPaid\|_showNeedHelpModal\|findGymByEmailOrPhone" lib` → no results
- `grep -rn "List.generate(6" lib/features/auth lib/features/onboarding lib/features/settings` → no results

On a real Android phone with a release build (`.\scripts\build_release.ps1`), run DST `RELEASE.md` §4
tests 1–18. The most important ones:
1. Signup → data appears in Supabase within ~5 s.
2. Airplane mode → add/edit/delete → back online → pending count drops to 0 automatically.
3. Uninstall → reinstall → Sign in → everything restored, no duplicate default packages.
4. ₹2000 bill → pay ₹1200 → receipt "PART PAID, balance ₹800", UPI QR asks ₹800 → pay ₹800 → bill Paid.
5. 5 wrong MPINs → 30 s lock survives app restart; Forgot MPIN via password and via fingerprint.
6. Settings → Reset while offline with pending changes → warning shows how many would be lost.
7. Two phones, same account, both offline: each records a receipt and a ₹500 installment on the same
   ₹2000 bill → both go online → both phones show both receipts (numbers `…A…` and `…B…`, none missing)
   and the bill shows ₹1000 paid, ₹1000 balance.
8. Add a second branch → switch between branches offline → each shows only its own members; reminders
   arrive for both branches.
9. Notification settings toggles (incl. DST's event-reminder toggles) sync without errors
   (Cloud Sync screen shows no red error) — this verifies §3.2.

---

## 7. GymYardHQ is a MULTI-TENANT SaaS — extra production requirements

SRC is a single-client app. **DST is one app published on the Play Store where many independent gym
owners each create an account and manage their own gym.** The sync design already isolates tenants
(each auth user owns its `gyms` rows — one per branch; every table is keyed by `gym_id`; RLS lets an owner touch only their
own gym — one Supabase project serves all tenants). The items below are what a multi-tenant Play Store
release needs **on top of** sections 1–6. Implement 7.1–7.7 and 7.10–7.11 as part of the port; 7.8 records the confirmed product
decisions.

### 7.1 Account is mandatory (no offline-only mode)

Every gym must belong to an account (data recovery, support, deletion, future billing).
- `welcome_screen.dart`: remove the "Continue offline without account" button and the
  `!AuthService.instance.isAvailable` fallback (a store build always has keys — `build_release.ps1`
  enforces it). Buttons: "Create Account" and "Sign in & restore".
- `account_auth_screen.dart`: remove the `authOfflineContinue` button.
- `biometric_setup_screen.dart`: `registerNewGym()` must always run (no `isSignedIn` condition); if there
  is no session, return to `AccountAuthScreen` instead of finishing setup.
- `data_connection_screen.dart`: the "not linked → Link Cloud Account" card is unreachable for new
  installs; keep it (harmless) or remove it.

### 7.2 Email confirmation ON + custom SMTP

Unlike SRC (OFF for one known client), a public app must verify emails: otherwise typo'd or fake emails
create accounts that can never reset their password.
- Supabase → Authentication → "Confirm email": **ON**. The app already handles it
  (`needsEmailConfirmation` → dialog → switches to Sign In).
- Custom SMTP is **mandatory** (built-in mailer: team addresses only, ~2 emails/hour).
- Edit the "Confirm signup" template so it reads well in the app's language; the link opens the
  browser, which is fine — the user then signs in from the app.
- Optional: Authentication → Attack Protection → enable CAPTCHA (Turnstile/hCaptcha) against
  bulk fake signups.

### 7.3 In-app account deletion (Google Play policy — REQUIRED)

Play requires apps with account creation to offer account + data deletion **inside the app** and via a
**web link** (entered in Play Console → Data safety).

**SQL — new migration `supabase/migrations/004_delete_account.sql`:**
```sql
-- Deletes the caller's gym (cascades to every gym table and member_device_tokens)
-- and the auth user itself. Storage files must be removed by the app first:
-- Supabase blocks direct SQL deletes on storage.objects.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  delete from public.gyms where owner_id = uid;
  delete from auth.users where id = uid;
end $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
```

**`AuthService.deleteAccount(String password)`:**
1. `verifyPassword(password)` (fresh proof of identity).
2. Delete media: list `gym-media/<gymId>/<table>/` for `gym`, `members`, `trainers`, `announcements`
   via `client.storage.from('gym-media').list(path: …)` and `remove([...paths])` in chunks of 100.
3. `await client.rpc('delete_my_account');`
4. `SupabaseConfig.clearBinding()`, `AppDatabase.instance.clearAllData()`,
   `SecurityService().clearSecurityData()`, `client.auth.signOut()` (ignore errors — user is gone).
Requires internet; show a clear message when offline.

**UI — `data_connection_screen.dart`:** below Sign Out, a red "Delete Account & All Data" card →
dialog explaining that every member, payment, bill and photo of this gym is deleted permanently from the
cloud and this phone → password field + type `DELETE` to enable the button → progress → Welcome screen.
Add EN/HI keys (`account_delete_*`).

**Web link:** a simple page (or Google Form) where an owner can request deletion by email; the platform
owner then runs `delete from gyms where owner_id = '<uid>'; delete from auth.users where id = '<uid>';`
in the SQL editor. Put that URL in Play Console.

### 7.4 Never mix two tenants' data on one phone

RLS already prevents tenant A's rows from being written into tenant B's gym (the push would fail), but
the phone must also never *show* or *queue* another tenant's data.
- `SupabaseConfig`: store the owner's user id when binding (`setActiveGymId(gymId, ownerUid: …)` →
  key `supabase_owner_uid`); clear it in `clearBinding()`.
- `AuthService.registerNewGym()` / `linkToExistingGym()` / `SyncEngine.restoreFromCloud()`: save the uid.
- `SyncEngine.syncNow()`: if `currentUser.id != stored owner uid` → do not push or pull; emit
  `SyncPhase.error` with "Signed in as a different account — sign out and reset this phone".
- `AccountAuthScreen._handlePostSignIn()` (not link mode): if this phone already has a binding for a
  **different** owner uid, run `SyncSchema.wipeLocalData` before restoring (restoreFromCloud already wipes
  synced tables; also clear `notifications`/`reminder_ledger` via `clearAllData()`).

### 7.5 RLS performance at scale

With thousands of tenants, a per-row function call in policies gets slow. Replace the child-table policy
in `001` (and for existing projects, in a migration `005_rls_perf.sql`) with the sub-select form, which
Postgres evaluates once per query:
```sql
-- inside the DO loop that creates <tbl>_owner_all:
create policy %1$s_owner_all on %1$I for all to authenticated
  using (gym_id in (select g.id from public.gyms g where g.owner_id = (select auth.uid())))
  with check (gym_id in (select g.id from public.gyms g where g.owner_id = (select auth.uid())));
```
and for `gyms`: `using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()))`.
`gyms.owner_id` is already indexed (unique). Keep `owns_gym()` for the storage policy.

### 7.6 Member (client) app isolation

`announcements_public_read` lets anyone with the anon key read **every** gym's sent announcements — fine
for one gym, a cross-tenant leak for a SaaS. If DST has a member app:
- add `gyms.join_code text unique` (short random code shown in the owner app's Settings → "Member app
  code"), and an RPC `get_gym_announcements(p_join_code text)` (security definer) returning only that
  gym's sent announcements; drop `announcements_public_read`;
- or require members to sign in (anonymous sign-in + a `gym_memberships` table) — larger change.
If there is no member app yet, simply **drop** `announcements_public_read`.

### 7.7 Supabase project & legal setup for a SaaS

- **Separate Supabase project for GymYardHQ** (never shared with club-100-gym), region Mumbai
  (`ap-south-1`).
- **Pro plan before launch:** Free projects pause after 7 days of inactivity (all tenants offline) and
  have no automatic backups. Pro gives daily backups; consider PITR once there are paying tenants.
- **Platform admin:** use the Supabase dashboard (or a separate web admin) for support. The
  `service_role` / secret key must never be in the app or the repo.
- **Privacy policy + Data safety form:** owners store their members' personal data (name, phone, email,
  DOB, photos). Declare: data collected (account email; gym and member records; photos), encrypted in
  transit, stored with Supabase, deletion available (7.3). The platform acts as a data processor for
  gym owners (India DPDP Act 2023) — the privacy policy should say so.
- Build an **AAB** for Play Store (`flutter build appbundle --release --dart-define-from-file=env/supabase.json`);
  add an `-AppBundle` switch to `build_release.ps1` or a second script. Upload key + Play App Signing as
  in DST's `docs/PLAY_STORE_PUBLISHING_GUIDE.md`.

### 7.8 Confirmed product decisions (v1 of GymYardHQ)

| Decision | Answer | Section |
|---|---|---|
| Staff / receptionist logins | **No** — only the gym owner (admin) has an account | 7.9 |
| One owner, several branches under one login | **Yes** | 7.10 |
| Same account on two (or more) phones at the same time, same data everywhere | **Yes** | 7.11 |
| Paid plans / trial | **Not now** — everything free in this version; add later | 7.12 |

### 7.9 Staff logins — not in v1

Keep the owner-only model. Do not build `gym_users`/roles. Several people at the front desk can still
work at the same time by signing in to the owner's account on their phones (7.11).

### 7.10 Multiple branches under one login

**Model:** each branch is one row in `gyms` (its own members, plans, bills, receipt numbering, logo,
UPI). An owner can have any number of branches. One phone shows **one active branch at a time** and can
switch instantly, offline.

**Cloud (new migration `005_multi_branch.sql`, also fold into 001 for fresh projects):**
```sql
alter table gyms drop constraint if exists gyms_owner_id_key;   -- allow many gyms per owner
create index if not exists idx_gyms_owner on gyms(owner_id);
```
RLS needs no change (policies already check `owner_id = auth.uid()` per gym). `delete_my_account()`
(7.3) already deletes every gym of the owner.

**Local storage — one SQLite file per branch** (do NOT add a `gym_id` column to every local table: that
would mean changing every repository query):
- `AppDatabase` opens the file of the active branch: `gym_<gymId>.db`. A phone that already has data in
  the legacy file `club_100_gym.db` keeps using it for the branch it gets bound to first (store the
  mapping `branch_db_file:<gymId>` in `SupabaseConfig`).
- New API: `AppDatabase.instance.switchTo(String gymId)` → closes the current DB, opens the branch's
  file (creating it with `_createDB` + `SyncSchema.ensure` if new), then `AppStateService.notifyAll()`.
- Each branch file has its own `sync_outbox`, `sync_meta` (pull cursors), `notifications`,
  `reminder_ledger`.
- `SupabaseConfig`: keep `activeGymId`; add `knownBranches` (JSON list of `{id, name}` cached for offline
  switching) and the owner uid (7.4).

**Sync:** `SyncEngine.syncNow()` pushes + pulls the active branch, then pushes the pending outbox of every
other branch file on this phone (open → `_push` → close). Pulls for inactive branches happen when the
owner switches to them.

**UI:**
- Dashboard AppBar / app drawer header: active branch name with a ▼ → bottom sheet listing branches
  (`select id, name, city from gyms where owner_id = auth.uid()`, falling back to the cached list
  offline) + **"Add new branch"**.
- Switching to a branch not yet on this phone: needs internet → progress "Downloading <branch>…" →
  `switchTo(gymId)` + `restoreFromCloud(gymId)`.
- "Add new branch" → `GymSetupScreen(newBranch: true)` (gym details only — no admin/MPIN/biometric
  steps) → create a new branch DB (default packages/plans seeded) → `registerNewGym()` → switch to it.
- After sign-in on a new phone: 0 branches → gym setup; 1 → restore it; 2+ → "Which branch do you want
  to open on this phone?" picker → restore that one.
- Every screen header that shows the gym name already reads it from the active DB, so receipts, bills,
  PDFs and SMS automatically use the active branch's details.

**Reminders & notifications:** `ReminderEngine` / `ReminderScheduler` / `background_reminders.dart`
must run for **every** branch file on the phone (loop: open → scan → close), and every notification id
and `reminder_ledger` key must include the gym id (e.g. prefix the ledger key with `<gymId>:` and derive
the int notification id from that full key) so two branches never overwrite each other's alerts. The
notification text should include the branch name. Tapping a notification of another branch switches to
it first.

### 7.11 Same account on several phones at the same time

Already works with the sync design (each phone signs in → restores → syncs). To make it production-safe
when two phones write **at the same time and offline**, these four changes are required:

> **(a), (b) and (c) are already implemented in SRC** (commit after `380a9e2`) — copy instead of writing
> them from scratch, then adapt to multi-branch (codes are already stored per gym id):
> - new: `lib/core/sync/document_numbering.dart`, `lib/core/sync/device_code_service.dart`,
>   `supabase/migrations/004_multi_device_safety.sql`, `test/sync/multi_device_test.dart`
> - changed: `generateNextReceiptNumber()` (`payment_repository.dart`), `generateNextBillNumber()`
>   (`bill_repository.dart`), `generate_bill_screen.dart` (number re-generated at save),
>   `sync_engine.dart` (`_pullOverlap`, `reconcileBillTotals`, `ensureRegistered` after push and restore),
>   `bill_detail_screen.dart` ("Overpaid" row), `001` (`clock_timestamp()`, `gym_devices`, `register_device`).
> - SRC stores the device code in secure storage (`sync_device_code:<gymId>`), not in `app_settings` —
>   follow SRC; ignore the `app_settings` instruction in (a) below.
> - Test files that open the real `AppDatabase` must call `databaseFactory.setDatabasesPath(<own temp dir>)`
>   in `setUpAll`, because `flutter test` runs files in parallel.

**(a) Unique bill / receipt numbers per phone — REQUIRED, prevents data loss.**
Both phones currently generate `GYM-2026-00012` from their own local max. `receipts.receiptNumber` and
`bills.billNumber` are `UNIQUE` in SQLite, so when phone B pulls phone A's receipt with the same number,
`INSERT OR REPLACE` **silently deletes phone B's own receipt**. Fix with a per-phone code inside the
number:
- Cloud migration:
  ```sql
  create table if not exists gym_devices (
    gym_id text not null references gyms(id) on delete cascade,
    device_id text not null,            -- random UUID generated once per install
    code text not null,                 -- 'A', 'B', … 'Z', 'AA', …
    created_at timestamptz not null default now(),
    primary key (gym_id, device_id),
    unique (gym_id, code)
  );
  alter table gym_devices enable row level security;
  create policy gym_devices_owner on gym_devices for all to authenticated
    using (gym_id in (select g.id from gyms g where g.owner_id = (select auth.uid())))
    with check (gym_id in (select g.id from gyms g where g.owner_id = (select auth.uid())));

  -- Returns this phone's code for the gym, assigning the next free one on first call.
  create or replace function public.register_device(p_gym_id text, p_device_id text)
  returns text language plpgsql security definer set search_path = public as $$
  declare
    v_code text;
    v_n int;
  begin
    if not exists (select 1 from gyms where id = p_gym_id and owner_id = auth.uid()) then
      raise exception 'not your gym';
    end if;
    select code into v_code from gym_devices where gym_id = p_gym_id and device_id = p_device_id;
    if v_code is not null then return v_code; end if;
    perform pg_advisory_xact_lock(hashtext(p_gym_id));
    select count(*) into v_n from gym_devices where gym_id = p_gym_id;
    v_code := case when v_n < 26 then chr(65 + v_n) else chr(65 + v_n / 26 - 1) || chr(65 + v_n % 26) end;
    insert into gym_devices (gym_id, device_id, code) values (p_gym_id, p_device_id, v_code);
    return v_code;
  end $$;
  grant execute on function public.register_device(text, text) to authenticated;
  ```
- App: generate a `device_id` UUID once (secure storage). Whenever a branch is bound to the phone
  (`registerNewGym`, `linkToExistingGym`, `restoreFromCloud`, add/switch branch — all online moments)
  call `client.rpc('register_device', params: {...})` and store the code per branch in that branch DB's
  `app_settings` under key `device_code` — **exclude this key from sync** (skip `app_settings` rows with
  key `device_code` in `_push`, and never overwrite it on pull).
- `PaymentRepository.generateNextReceiptNumber()` → `GYM-<year>-<code><5-digit seq>`
  (e.g. `GYM-2026-A00012`, `GYM-2026-B00003`), the sequence being the max of **this phone's prefix only**.
  Same for `BillRepository.generateNextBillNumber()` → `BILL-2026-A00012`. Old numbers without a code stay
  valid. If no code is stored (should not happen), refuse to save the payment with a clear message
  rather than risk a duplicate.

**(b) Recompute bill totals after every pull — REQUIRED.**
`bills.paidAmount` / `status` are cached sums. If phone A and phone B both record an installment on the
same bill offline, each pushes its own `paidAmount` and the last one wins (the bill shows ₹1200 paid
instead of ₹2000). Payments themselves are separate rows and are never lost, so after applying pulled
`payments` or `bills` rows, `SyncEngine` must re-derive the affected bills **as a normal local write**
(so the corrected value is pushed and all phones converge):
```sql
UPDATE bills SET
  paidAmount = (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payments.billId = bills.id),
  status = CASE
    WHEN status = 'Cancelled' THEN status
    WHEN (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payments.billId = bills.id) >= amount - 0.01 THEN 'Paid'
    WHEN (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payments.billId = bills.id) > 0 THEN 'Partially Paid'
    ELSE status END,
  updatedAt = ?
WHERE id IN (<bill ids touched by this pull>)
  AND paidAmount <> (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE payments.billId = bills.id);
```
Run it outside `SyncSchema.muted` (it must be queued for push) and only when the value actually changes
(the `AND paidAmount <> …` guard prevents an endless push/pull loop). If the sum exceeds the bill
amount (both phones collected the full balance offline), show "Overpaid ₹X" on the bill detail instead
of a negative balance.

**(c) Pull overlap window — REQUIRED.**
`server_updated_at` is set when a row is written; a write from phone A that commits slightly later than
one from phone B can carry an *earlier* timestamp than B's, and a phone that already pulled past B's
timestamp would never see A's row. Fixes:
- In `001`'s `touch_server_updated_at()` use `clock_timestamp()` instead of `now()`.
- In `SyncEngine._pull()`, query `server_updated_at > (cursor − 2 minutes)` instead of `> cursor`.
  Re-applying already-seen rows is harmless (idempotent upserts, and rows with pending local edits are
  skipped).

**(d) Near-real-time updates between phones — recommended.**
Polling (3 min + on app resume) means phone B sees phone A's new member up to 3 min later. Make it a few
seconds with one tiny Realtime channel per branch instead of subscribing to all 18 tables:
```sql
create table if not exists gym_sync_signals (
  gym_id text primary key references gyms(id) on delete cascade,
  changed_at timestamptz not null default clock_timestamp()
);
alter table gym_sync_signals enable row level security;
create policy gym_sync_signals_owner on gym_sync_signals for select to authenticated
  using (gym_id in (select g.id from gyms g where g.owner_id = (select auth.uid())));
-- statement-level trigger on every synced child table bumps the branch's signal row:
--   insert into gym_sync_signals (gym_id) values (<gym_id>) on conflict (gym_id) do update set changed_at = clock_timestamp();
alter publication supabase_realtime add table gym_sync_signals;
```
App: while in the foreground, `SyncEngine` subscribes to `postgres_changes` on `gym_sync_signals`
filtered by `gym_id=eq.<active gym>` and calls `requestSync()` on every event (debounced). Unsubscribe on
pause, branch switch and sign-out. Polling stays as the fallback.

**Other multi-phone notes**
- Simultaneous edits of the **same** member/plan on two phones: last write wins per row (acceptable).
- MPIN, biometric and lockout are per phone (by design). Changing the MPIN on one phone does not change
  it on another.
- Sign-out / reset on one phone affects only that phone.
- Forgot MPIN via account password works on every phone.

### 7.12 Subscription / trial — later version

Ship v1 completely free. Do **not** add plan checks to RLS or UI now. Keep these in mind so adding it
later is easy:
- Future migration adds `gyms.plan`, `trial_ends_at`, `subscription_ends_at` (per owner or per branch —
  decide then) and a write-blocking policy that still allows reads, so an expired owner never loses access
  to their data.
- The app must then treat an RLS rejection on push as "subscription expired" (banner + keep the outbox),
  not as a generic sync error.
- Payment method: Google Play's Payments policy generally requires Google Play Billing for subscriptions
  sold inside the app — decide the payment route before building it.

---

## 8. Reference documents in SRC

- `mobile/docs/SUPABASE_OFFLINE_FIRST_PLAN.md` — original architecture plan (sync design, SQL rationale)
- `mobile/docs/PARTIAL_PAYMENTS_FLOW.md` — partial payment behaviour, section 6 = hardening
- `mobile/RELEASE.md` — Supabase setup, signing, APK build, device test checklist
