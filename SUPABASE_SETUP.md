# Supabase Setup & Production Architecture Guide

This document provides complete instructions for setting up, configuring, and operating the **Supabase** backend for the **Elite Fitness Gym** ecosystem:
- **Mobile Admin App** (`mobile/`)
- **Client Notifications App** (`client_app/`)

---

## 🏗️ 1. Architecture Overview

The system uses a **True Offline-First + SQLite Triggered Cloud Synchronization** architecture:

```text
                     ┌─────────────────────────────────────────────────────────┐
                     │               Supabase Cloud (PostgreSQL)               │
                     │  - Supabase Auth (Email + Password)                     │
                     │  - 18 Relational Tables (Composite PK: gym_id + id)     │
                     │  - Server clock triggers (server_updated_at)            │
                     │  - Soft-deletes (is_deleted = true)                     │
                     │  - Storage Bucket: gym-media (sb://gym-media/...)       │
                     │  - Realtime WebSockets for announcements                │
                     └───────────────▲─────────────────────────▲───────────────┘
                                     │                         │
                   SyncEngine (Push & Pull)                    │ Realtime Stream
                   Automatic Change Sync                       │ (Broadcast Feed)
                                     │                         │
     ┌───────────────────────────────▼───┐                 ┌───┴────────────────────────┐
     │       ADMIN APP (Flutter)         │                 │    CLIENT APP (Flutter)    │
     │  - Local SQLite (Single Truth)    │                 │  - Supabase Realtime Feed  │
     │  - Zero Latency Offline UI        │                 │  - Announcement Banners    │
     │  - SQLite Triggers (`sync_outbox`)│                 │  - Offline Cache Fallback  │
     │  - Automatic Media Sync           │                 │  - Read State Tracking     │
     │  - 1-Tap Cloud Restore            │                 └────────────────────────────┘
     └───────────────────────────────────┘
```

### Why this design?
1. **Zero UI Latency & 100% Offline Resilience**: All business operations (member registration, plan changes, payment processing, invoice and QR receipts) write directly to local SQLite. Repositories in `lib/data/repositories/` do not require an active internet connection.
2. **Transparent Change Capture**: SQLite triggers automatically capture every local `INSERT`, `UPDATE`, and `DELETE` into a local `sync_outbox` table. No manual sync bookkeeping inside repository code.
3. **Muted Remote Pulls**: When syncing down updates from the cloud, SQLite triggers are muted inside the transaction, avoiding circular sync feedback loops.
4. **Clean Multi-Device Restore**: A gym owner signing into a new device or fresh install retrieves their entire database from Supabase Cloud in a single atomic restore operation.

---

## ⚡ 2. Step-by-Step Supabase Project Setup

### Step 2.1: Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and log in or create an account.
2. Click **New Project**.
3. Fill in:
   - **Name**: `Elite Fitness Gym` (or your gym's name)
   - **Database Password**: Choose a strong password and save it securely.
   - **Region**: Choose the region closest to your gym (e.g. `ap-south-1` Mumbai for India).
4. Click **Create new project** and wait for provisioning to complete.

---

### Step 2.2: Execute the Database Migration
1. In your Supabase dashboard, click the **SQL Editor** tab from the left navigation bar (icon `>_`).
2. Click **New query**.
3. Open the file [`mobile/supabase/migrations/001_offline_sync_schema.sql`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/supabase/migrations/001_offline_sync_schema.sql).
4. Copy the entire file content and paste it into the Supabase SQL Editor.
5. Click **Run** (or press `Ctrl + Enter` / `Cmd + Enter`).

> [!TIP]
> The migration script is completely idempotent:
> - Creates **18 tables** with composite primary keys `(gym_id, id)`.
> - Adds server-side `server_updated_at` clock triggers.
> - Adds soft-delete support (`is_deleted BOOLEAN NOT NULL DEFAULT false`).
> - Creates the `gym-media` storage bucket with authenticated upload and public read policies.
> - Configures Row-Level Security (RLS) policies linking records to the authenticated gym owner (`auth.uid()`).

---

### Step 2.3: Retrieve API URL & Anon Key
1. In your Supabase project dashboard, navigate to **Project Settings** (gear icon) > **API**.
2. Find the following values:
   - **Project URL**: e.g., `https://abcdefghijklm.supabase.co`
   - **Project API Keys** -> `anon` / `public`: e.g., `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

## 📱 3. Configuring the Apps

### Step 3.1: Mobile Admin App Configuration
Create your environment config file:
1. In the `mobile/env/` folder, create a file named `supabase.json` (you can copy `mobile/env/supabase.example.json`):
```json
{
  "SUPABASE_URL": "https://your-project-id.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-public-key"
}
```
*(Note: `mobile/env/supabase.json` is gitignored to keep your production keys safe).*

2. Run or build the Flutter app using `--dart-define-from-file`:
```powershell
# Run in debug mode
flutter run --dart-define-from-file=env/supabase.json

# Build Release APK
flutter build apk --release --dart-define-from-file=env/supabase.json
```

---

### Step 3.2: Client Notifications App Configuration
In [`client_app/lib/core/config/client_supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/config/client_supabase_config.dart), ensure the URL and anon key match your Supabase project:
```dart
class ClientSupabaseConfig {
  static const String defaultUrl = 'https://your-project-id.supabase.co';
  static const String defaultAnonKey = 'your-anon-public-key';
  // ...
}
```

---

## 🔐 4. Authentication & Account Management

### Account Creation & Sign In
- Gym owners sign up or sign in using their **Email and Password** via `AccountAuthScreen`.
- When an owner creates an account and sets up their gym, `AuthService.instance.registerNewGym()` creates the cloud gym record with `owner_user_id = auth.uid()`.
- If an admin forgets their password, they can reset it using a 6-digit OTP code sent directly to their registered email.

### Multi-Device Restore
When installing the app on a new device or after reinstalling:
1. Launch app -> Tap **Sign In (Restore)**.
2. Enter email and password.
3. The app finds the owner's cloud gym ID, downloads all 18 tables into local SQLite, and prompts for local MPIN / biometric authentication.
4. The admin is immediately ready to operate offline.

---

## 🔄 5. How the Sync Engine Works

1. **Local Writes**: When the app creates, modifies, or deletes any record (members, bills, payments, announcements), SQLite triggers instantly add an entry to the `sync_outbox` table.
2. **Debounced Sync**: `SyncEngine` waits 1.5 seconds after local changes to batch operations together before uploading.
3. **Periodic & Lifecycle Sync**:
   - Every 3 minutes while running.
   - Immediately when network connectivity is restored.
   - When the app is resumed from background.
4. **Media Handling**:
   - Photos (member photos, gym logos, payment receipts) are saved locally in the device's storage.
   - During sync, `MediaSync` uploads them to the `gym-media` Supabase bucket under `sb://gym-media/<gym_id>/...`.
   - On device restore, `MediaSync` downloads remote images into the local storage cache.
5. **Conflict Resolution**: Unpushed local changes always take precedence over incoming remote changes during synchronization.

---

## 🗄️ 6. Database Schema Reference (18 Mirrored Tables)

| # | Table Name | Purpose | Primary Key | Soft Delete |
|---|---|---|---|---|
| 1 | `gyms` | Gym business profiles | `(id)` | Yes |
| 2 | `admins` | Admin credentials & biometric prefs | `(gym_id, id)` | Yes |
| 3 | `membership_packages` | Membership packages | `(gym_id, id)` | Yes |
| 4 | `membership_plans` | Plans with durations & default rates | `(gym_id, id)` | Yes |
| 5 | `trainers` | Gym trainers & coaches | `(gym_id, id)` | Yes |
| 6 | `trainer_payouts` | Commission payout ledger | `(gym_id, id)` | Yes |
| 7 | `members` | Member profiles | `(gym_id, id)` | Yes |
| 8 | `memberships` | Active & historical memberships | `(gym_id, id)` | Yes |
| 9 | `membership_change_logs` | Plan and fee audit trails | `(gym_id, id)` | Yes |
| 10 | `trainer_change_logs` | Trainer assignment logs | `(gym_id, id)` | Yes |
| 11 | `bills` | Membership invoice records | `(gym_id, id)` | Yes |
| 12 | `payments` | Transactions collected from members | `(gym_id, id)` | Yes |
| 13 | `receipts` | Digital receipts with QR codes | `(gym_id, id)` | Yes |
| 14 | `expenses` | Gym operational expenses | `(gym_id, id)` | Yes |
| 15 | `events` | Gym competitions and calendar alerts | `(gym_id, id)` | Yes |
| 16 | `announcements` | Gym broadcasts sent to client app | `(gym_id, id)` | Yes |
| 17 | `member_device_tokens`| Push tokens for member devices | `(gym_id, id)` | Yes |
| 18 | `app_settings` | App customization & color themes | `(gym_id, id)` | Yes |

---

## 🛠️ 7. Key Code Locations

| Component | File Path |
|---|---|
| PostgreSQL Migration | [`mobile/supabase/migrations/001_offline_sync_schema.sql`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/supabase/migrations/001_offline_sync_schema.sql) |
| Supabase Configuration | [`mobile/lib/core/config/supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/config/supabase_config.dart) |
| SQLite Sync Tables & Order | [`mobile/lib/core/sync/sync_tables.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/sync_tables.dart) |
| SQLite Triggers & Outbox Schema | [`mobile/lib/core/sync/sync_schema.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/sync_schema.dart) |
| Offline-First Sync Engine | [`mobile/lib/core/sync/sync_engine.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/sync_engine.dart) |
| Cloud Media Storage Manager | [`mobile/lib/core/sync/media_sync.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/media_sync.dart) |
| Cloud Column Mapper | [`mobile/lib/core/sync/cloud_mapper.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/cloud_mapper.dart) |
| Supabase Auth Service | [`mobile/lib/core/auth/auth_service.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/auth/auth_service.dart) |
| Account Auth & Reset Screen | [`mobile/lib/features/auth/account_auth_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/auth/account_auth_screen.dart) |
| Cloud Sync Settings Screen | [`mobile/lib/features/settings/data_connection_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/settings/data_connection_screen.dart) |
| Sync Status Dashboard Badge | [`mobile/lib/shared/widgets/sync_status_badge.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/shared/widgets/sync_status_badge.dart) |
