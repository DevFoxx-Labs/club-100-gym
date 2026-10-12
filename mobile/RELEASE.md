# Release Checklist — Elite Fitness Admin App

Follow these steps in order before handing a build to the client.

## 1. Supabase project (one time)

1. Create a project at https://supabase.com (region close to the client, e.g. Mumbai).
2. **SQL Editor → New query**: paste and run `supabase/migrations/001_offline_sync_schema.sql`.
   If 001 was already run on this project before, also run `002_harden_device_tokens.sql`.
3. **Authentication → Sign In / Providers → Email**: enabled.
   - "Confirm email": turn **OFF** for the smoothest signup. If you keep it ON, the app tells the
     admin to confirm their email and then sign in — that works too.
4. **Authentication → Email Templates → Reset Password**: make sure the template contains
   `{{ .Token }}` (the app's "Forgot password" flow uses the 6-digit code).
5. **Project Settings → API**: copy the Project URL and the `anon` public key into
   `env/supabase.json` (copy from `env/supabase.example.json`). This file is gitignored.

> The anon key is safe inside the app: every table is protected by row-level security, so a
> signed-in owner can only ever see their own gym.

## 2. Release signing key (one time — keep it safe forever)

```powershell
keytool -genkey -v -keystore C:\keys\elite-fitness-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Copy `android/key.properties.example` to `android/key.properties` and fill in the passwords and
the path to the `.jks`. **Back up the `.jks` and passwords** — without them you can never ship an
update to the same app.

## 3. Build

```powershell
cd mobile
.\scripts\build_release.ps1
```

The script refuses to build if Supabase keys or the signing key are missing, runs
`flutter analyze` + `flutter test`, and produces:

- `build/app/outputs/bundle/release/app-release.aab` — upload to Play Store
- `build/app/outputs/flutter-apk/app-release.apk` — direct install

For day-to-day development: `flutter run --dart-define-from-file=env/supabase.json`.

## 4. Device acceptance test (real Android phone, release APK)

| # | Test | Expected |
|---|------|----------|
| 1 | Fresh install → Create Account → gym setup → MPIN | Supabase Table Editor shows a `gyms` row, `admins`, packages, plans |
| 2 | With internet: add a member, payment, bill, expense | Rows appear in Supabase within ~5 seconds; dashboard cloud icon shows synced |
| 3 | Airplane mode: add 2 members, 1 payment, delete an expense | App works normally; Cloud Account & Sync shows pending changes |
| 4 | Turn internet back on (keep app open) | Pending goes to 0 automatically; cloud has the rows, deleted expense has `is_deleted = true` |
| 5 | Airplane mode, add a member, close the app fully, turn internet on, open app | Change uploads on open |
| 6 | Uninstall → reinstall → Sign In with same email | "Restoring…" → set MPIN → all data back, no duplicate packages, photos back |
| 7 | Settings → Reset with pending changes while offline | Warning shows how many changes would be lost |
| 8 | Old offline install (no account) → Settings → Cloud Account & Sync → Link | Existing data uploads; if the account already has a gym, app asks Upload vs Use Cloud |
| 9 | Second test account | Cannot see the first account's gym |
| 10 | Switch language to Hindi | No raw keys (like `authTitleSignIn`) visible anywhere |

## 5. Known limits (tell the client)

- One gym per account. Using the **same account on two phones at the same time** works for
  sync, but bill/receipt numbers are generated per phone and could repeat.
- Sync runs while the app is open (and immediately when it is reopened); it does not run while
  the app is fully closed.
- Notification history is per phone and is not restored (reminders are regenerated automatically).
