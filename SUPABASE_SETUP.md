# Supabase Setup & Architecture Guide

This document provides complete instructions for setting up, configuring, and maintaining the **Supabase** backend for the **Elite Fitness Gym** ecosystem:
- **Mobile Admin App** (`mobile/`)
- **Client Notifications App** (`client_app/`)
- **Web Platform** (`app/`)

---

## 🏗️ 1. Architecture Overview

The system uses a **Hybrid Offline-First + Cloud Synchronization** architecture:

```text
                     ┌──────────────────────────────────────────────┐
                     │          Supabase Cloud (PostgreSQL)         │
                     │  - 18 Relational Tables                     │
                     │  - Realtime WebSockets                       │
                     │  - Storage Buckets: gym-assets, announcements│
                     └───────────────▲──────────────▲───────────────┘
                                     │              │
                   Bidirectional Sync│              │Realtime Broadcasts
                     & Cloud Restore │              │(Push Notifications)
                                     │              │
    ┌────────────────────────────────▼───┐      ┌───┴────────────────────────────────┐
    │          ADMIN APP (Flutter)       │      │      CLIENT APP (Flutter)          │
    │  - Local SQLite (Zero Latency)     │      │  - Supabase Realtime Listener      │
    │  - Offline-first Operations        │      │  - Instant Push Notifications      │
    │  - Auto-Discovery by Phone/Email   │      │  - Offline Cache Fallback          │
    │  - 1-Tap Cloud Backup & Restore    │      │  - Read/Unread State Tracking      │
    └────────────────────────────────────┘      └────────────────────────────────────┘
```

### Why this design?
1. **Zero Latency & 100% Offline Capability**: The front desk admin can register members, take payments, generate QR bills, and print PDF receipts without an active internet connection.
2. **Cloud Redundancy & Multi-Device Restore**: All local SQLite tables are backed up to Supabase. If the gym owner loses or switches their device, typing their mobile number or email restores all data in seconds.
3. **Realtime Broadcasts**: Announcements posted in the Admin App stream directly to member devices in real time.

---

## ⚡ 2. Step-by-Step Supabase Project Setup

### Step 2.1: Create a Supabase Project
1. Go to [https://supabase.com](https://supabase.com) and log in or create a free account.
2. Click **New Project**.
3. Fill in:
   - **Name**: `Elite Fitness Gym` (or your gym's name)
   - **Database Password**: Choose a strong password and save it securely.
   - **Region**: Choose the region closest to your gym (e.g. `ap-south-1` Mumbai for India).
4. Click **Create new project** and wait 1–2 minutes for provisioning.

---

### Step 2.2: Execute the Database Schema
1. In your Supabase dashboard, click the **SQL Editor** tab from the left navigation bar (icon `>_`).
2. Click **New query**.
3. Open the file [`supabase_schema.sql`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/supabase_schema.sql) located at the root of this project.
4. Copy the entire file content and paste it into the Supabase SQL Editor.
5. Click **Run** (or press `Ctrl + Enter` / `Cmd + Enter`).

> [!TIP]
> The SQL script is idempotent (`CREATE TABLE IF NOT EXISTS`). It automatically creates:
> - **18 tables** with primary keys, foreign keys, and cascading deletes.
> - **Indexes** on `gym_id`, `mobile`, `email`, and `created_at`.
> - **Row-Level Security (RLS)** policies for secure multi-tenant isolation.
> - **Storage Buckets** (`gym-assets` and `announcements`) with public read access.

---

### Step 2.3: Retrieve API URL & Anon Key
1. In your Supabase project dashboard, navigate to **Project Settings** (gear icon) > **API**.
2. Find the following values:
   - **Project URL**: e.g., `https://abcdefghijklm.supabase.co`
   - **Project API Keys** -> `anon` / `public`: e.g., `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

## 📱 3. Configuring the Apps

You can supply your credentials in **two ways**:

### Option A: Static Configuration in Code (Recommended for Production APKs)

#### 1. In the Mobile Admin App:
Open [`mobile/lib/core/config/supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/config/supabase_config.dart) and replace the placeholders:
```dart
class SupabaseConfig {
  /// Paste your Supabase Project URL
  static const String defaultUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Paste your Supabase Public Anon Key
  static const String defaultAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

#### 2. In the Client Notifications App:
Open [`client_app/lib/core/config/client_supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/config/client_supabase_config.dart) and replace the placeholders:
```dart
class ClientSupabaseConfig {
  /// Paste your Supabase Project URL
  static const String defaultUrl = 'https://YOUR_PROJECT_ID.supabase.co';

  /// Paste your Supabase Public Anon Key
  static const String defaultAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

---

### Option B: Runtime Configuration via In-App UI (No Recompilation Required)

You can configure or switch Supabase projects directly inside the running Mobile Admin app:

1. Open the Admin App and log in.
2. Tap the bottom navigation tab **Settings** (or swipe down from Quick Actions).
3. Select **Data & Backup** > **Supabase Cloud Sync** ([`data_connection_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/settings/data_connection_screen.dart)).
4. Enter your **Supabase URL** and **Anon Key**.
5. Tap **Test Ping**:
   - Displays a green badge `Connected (Active)` upon success.
6. Tap **Save Credentials & Connect**.
7. Tap **Push All Local Data to Cloud** to upload existing SQLite data to Supabase.

---

## 🔄 4. Automated Account Discovery & Data Restoration

A key requirement of this platform is that **if a gym owner sets up their gym with the same email or mobile number, they immediately recover all their previous data**.

### How it Works:

```text
[Owner enters Mobile or Email during Onboarding]
                     │
                     ▼
  SupabaseSyncService.findGymByEmailOrPhone()
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
    [Gym Found]            [Not Found]
         │                       │
         ▼                       ▼
Interactive Dialog:         Normal First-Time
"Existing Gym Found!        Setup Flow Continues
Restore all records?"
    ┌────┴────┐
    ▼         ▼
[Restore]  [Start Fresh]
    │
    ▼
SupabaseSyncService.restoreAllGymData()
- Downloads all 18 tables
- Atomically populates local SQLite
- Marks setup as complete
- Directly navigates to Dashboard
```

### Recovery Methods Available to Gym Owners:

#### Method 1: Automatic Detection in Gym Setup ([`gym_setup_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/onboarding/gym_setup_screen.dart))
- When the owner reaches Step 1 of onboarding and enters their gym phone or email, the app queries Supabase in real time.
- If an existing account matches, a recovery modal opens:
  > **Existing Gym Found!**
  > *"We found an existing cloud account for [Gym Name]. Would you like to restore your members, plans, payments, and history?"*
- Tapping **Restore All Data** downloads everything into local SQLite.

#### Method 2: One-Tap Recovery from Welcome Screen ([`welcome_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/onboarding/welcome_screen.dart))
- On a fresh install, beneath the **Get Started** button, there is a dedicated button:
  > **Already have an account? Restore from Cloud**
- The owner enters their registered phone number or email and taps **Search Account**.
- The app confirms the gym name, shows the record count, and restores the complete database in one click.

#### Method 3: On-Demand Restore from Settings Screen ([`data_connection_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/settings/data_connection_screen.dart))
- At any time, the admin can go to Settings > **Supabase Cloud Sync** and tap **Restore from Cloud**.

---

## 📣 5. Client App Realtime Announcement Architecture

```text
ADMIN APP: Create & Broadcast Announcement
              │
              ▼
    1. Saved to Local SQLite
    2. Uploaded to Supabase `announcements` Table
              │
              ▼ (Postgres Realtime WebSocket Stream)
CLIENT APP: ClientAnnouncementService
              │
              ▼
    ┌─────────┴─────────┐
    ▼                   ▼
Show Notification   Update Feed Screen
(Banner & Sound)    (Unread Dot & Badges)
```

### Features Built into Client App:
1. **Supabase Realtime Stream**: [`ClientAnnouncementService`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/services/client_announcement_service.dart) subscribes to table changes using `stream(primaryKey: ['id'])`.
2. **Offline Fallback**: If internet is down or Supabase is not configured yet, the app falls back seamlessly to the local JSON broadcast file (`elite_fitness_broadcasts.json`) or pre-bundled gym seeds.
3. **Notification Deduplication**: Announcements track notified and read states in `SharedPreferences` so users are never spammed with repeat notification alerts.
4. **Category Visuals**: Announcements automatically display custom badges and icons for classes, equipment, gym hours, events, and maintenance alerts.

---

## 🗄️ 6. Database Schema Reference (18 Tables)

| # | Table Name | Purpose | Key Columns |
|---|---|---|---|
| 1 | `gyms` | Gym business profiles | `id`, `name`, `phone`, `email`, `address`, `logo_url` |
| 2 | `admins` | Admin accounts & credentials | `id`, `gym_id`, `name`, `email`, `phone`, `mpin_hash` |
| 3 | `membership_packages` | Membership packages (General, Personal Training, etc.) | `id`, `gym_id`, `name`, `description` |
| 4 | `membership_plans` | Plans with durations & default rates | `id`, `gym_id`, `package_id`, `name`, `duration_months`, `price` |
| 5 | `trainers` | Gym trainers & personal coaches | `id`, `gym_id`, `name`, `phone`, `specialization`, `commission_rate` |
| 6 | `trainer_payouts` | Commission payout ledger for trainers | `id`, `gym_id`, `trainer_id`, `amount`, `payment_method`, `date` |
| 7 | `members` | Member profiles | `id`, `gym_id`, `name`, `phone`, `email`, `status`, `photo_url` |
| 8 | `memberships` | Active & past memberships with custom pricing | `id`, `gym_id`, `member_id`, `plan_id`, `custom_plan_price`, `start_date`, `end_date` |
| 9 | `membership_change_logs` | Audit trail for upgrades, renewals, custom plan price changes | `id`, `gym_id`, `membership_id`, `change_type`, `old_value`, `new_value` |
| 10 | `trainer_change_logs` | Audit trail for personal trainer assignments & fees | `id`, `gym_id`, `member_id`, `trainer_id`, `monthly_fee`, `changed_at` |
| 11 | `bills` | Invoice records generated for memberships | `id`, `gym_id`, `member_id`, `amount`, `due_date`, `status` |
| 12 | `payments` | Transactions collected from members | `id`, `gym_id`, `bill_id`, `member_id`, `amount`, `payment_mode` |
| 13 | `receipts` | Official digital & PDF receipts with QR verification | `id`, `gym_id`, `payment_id`, `receipt_number`, `pdf_url` |
| 14 | `expenses` | Gym operational expenditures (Rent, Utilities, Maintenance) | `id`, `gym_id`, `category`, `amount`, `date`, `notes` |
| 15 | `events` | Competitions, fitness challenges, and schedule alerts | `id`, `gym_id`, `title`, `description`, `event_date`, `is_active` |
| 16 | `announcements` | Gym-wide broadcast announcements | `id`, `gym_id`, `title`, `message`, `category`, `image_url`, `is_pinned` |
| 17 | `member_device_tokens` | FCM & APNs push tokens for client devices | `id`, `gym_id`, `member_id`, `device_token`, `platform` |
| 18 | `app_settings` | Gym branding, theme colors, language, and backup metadata | `id`, `gym_id`, `theme_color`, `language`, `last_sync_at` |

---

## 🛠️ 7. Key Code Locations

| Component | File Path |
|---|---|
| Complete SQL Schema | [`supabase_schema.sql`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/supabase_schema.sql) |
| Admin Supabase Config | [`mobile/lib/core/config/supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/config/supabase_config.dart) |
| Admin Supabase Service | [`mobile/lib/core/sync/supabase_service.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/supabase_service.dart) |
| Sync & Restore Engine | [`mobile/lib/core/sync/supabase_sync_service.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/supabase_sync_service.dart) |
| Onboarding Recovery Dialog | [`mobile/lib/features/onboarding/gym_setup_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/onboarding/gym_setup_screen.dart) |
| Welcome Screen Restore Sheet | [`mobile/lib/features/onboarding/welcome_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/onboarding/welcome_screen.dart) |
| In-App Cloud Sync Screen | [`mobile/lib/features/settings/data_connection_screen.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/features/settings/data_connection_screen.dart) |
| Client Supabase Config | [`client_app/lib/core/config/client_supabase_config.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/config/client_supabase_config.dart) |
| Client Realtime Service | [`client_app/lib/core/services/client_supabase_service.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/services/client_supabase_service.dart) |
| Client Announcement Feed | [`client_app/lib/core/services/client_announcement_service.dart`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/client_app/lib/core/services/client_announcement_service.dart) |

---

## ❓ 8. Frequently Asked Questions (FAQ)

### What happens if the internet goes down?
The app functions without interruption. Local SQLite processes all actions (new members, fee payments, plan changes). When internet connectivity returns, the admin can tap **Push Local Data** in Settings or let background sync push the updates to Supabase.

### Can a gym owner restore data onto multiple phones or tablets?
Yes. Any device running the Admin App can restore the gym's database by providing the owner's registered phone or email during onboarding.

### How are column naming differences handled?
SQLite models use Dart standard `camelCase` (`customPlanPrice`, `feeAmount`), while PostgreSQL uses `snake_case` (`custom_plan_price`, `fee_amount`). The built-in mapper in [`SupabaseSyncService`](file:///e:/ProjectsFromDevFoxxLabs/MobileApps/club-100-gym/mobile/lib/core/sync/supabase_sync_service.dart) automatically converts keys in both directions without losing fidelity.
