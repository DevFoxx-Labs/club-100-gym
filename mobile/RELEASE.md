# Release Checklist — Elite Fitness Admin App

Follow these steps in order before handing a build to the client.

## 1. Supabase project (one time)

1. Create a project at https://supabase.com (region close to the client, e.g. Mumbai).
2. **SQL Editor → New query**: paste and run `supabase/migrations/001_offline_sync_schema.sql`.
   If 001 was already run on this project before, also run `002_harden_device_tokens.sql` and
   **`003_receipt_balance_snapshot.sql`** (without 003, receipts stop syncing) and
   **`004_multi_device_safety.sql`** (needed for per-phone bill/receipt numbers).
3. **Authentication → Sign In / Providers → Email**: enabled.
   - "Confirm email": turn **OFF** for the smoothest signup. If you keep it ON, the app tells the
     admin to confirm their email and then sign in — that works too.
4. **Authentication → Email Templates → Reset Password**: replace the body so it contains the
   6-digit code — the app asks for a code, not a link:
   ```html
   <h2>Reset your Elite Fitness password</h2>
   <p>Your code is: <strong>{{ .Token }}</strong></p>
   <p>Enter this code in the app. It expires in 1 hour.</p>
   ```
5. **Custom SMTP (required for real users)** — **Project Settings → Authentication → SMTP Settings**.
   Supabase's built-in mailer only delivers to your own team's email addresses and only a few
   emails per hour, so without this the client will **never receive** the password-reset code.
   Any SMTP provider works (Brevo / Resend free tier, or Gmail with an App Password:
   host `smtp.gmail.com`, port `465`, user = your Gmail, password = the 16-character App Password).
   Then test "Forgot password?" in the app with the client's real email.
6. **Connect** button (top of the dashboard) or **Project Settings → Data API / API Keys**: copy the Project URL and the `anon` (legacy) or publishable key — never the secret / service_role key — into
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
`flutter analyze` + `flutter test`, and puts the APKs in `mobile/dist/`:

- `EliteFitness-v1.0.0-build1.apk` — give this one (modern phones, ~30 MB)
- `EliteFitness-v1.0.0-build1-old-phones.apk` — only if the first one says "App not installed" on a very old phone

`.\scripts\build_release.ps1 -Universal` builds a single ~90 MB APK that runs on every phone instead.

For day-to-day development: `flutter run --dart-define-from-file=env/supabase.json`.

### Shipping an update

1. Increase `version:` in `pubspec.yaml` — the number after `+` **must go up** every time
   (`1.0.0+1` → `1.0.1+2` → `1.0.2+3`), otherwise Android refuses to install over the old app.
2. Build with the **same keystore**. A different key = "App not installed"; the client would have
   to uninstall first (local data is gone, but signing in restores it from the cloud).
3. Send the new APK; the client just installs it over the old one — data stays.

### Installing on the client's phone

1. Send the APK via WhatsApp (as a document), Google Drive, or USB cable.
2. Open it → Android asks to allow "Install unknown apps" for that app (WhatsApp/Files/Chrome) → Allow.
3. Play Protect may show "App scanned / unknown developer" → **More details → Install anyway**.
   This is normal for apps not from the Play Store.

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
| 11 | Bill of ₹2000 → Record Payment ₹1200 | Receipt shows "PART PAID", Bill Total ₹2000, Balance Due ₹800; bill is "Partially Paid"; member profile shows Total Balance Due ₹800 |
| 12 | Same bill → bill detail | Button reads "Collect Balance ₹800", UPI QR asks for ₹800 (not ₹2000), installment #1 listed |
| 13 | Pay ₹800 | Bill becomes Paid, both installments listed, receipt shows "bill fully paid" |
| 14 | Member with no open bill → Add Payment, enter less than the fee | Note says a bill will be created; after saving the balance shows in Bills & Dues |
| 15 | Lock screen: enter wrong MPIN 5 times | "attempts left" countdown, then 30 s lock; closing/reopening the app keeps the lock |
| 16 | Forgot MPIN? → account password | New MPIN + confirm → dashboard opens; old MPIN no longer works |
| 17 | Forgot MPIN? in airplane mode, fingerprint enabled | Fingerprint option works offline |
| 18 | Sign-in screen → Forgot password? with the client's real email | 6-digit code arrives (custom SMTP), new password works |
| 19 | Same account on 2 phones, both offline: each takes a payment, then both go online | Receipt numbers differ (`GYM-2026-A…` / `GYM-2026-B…`), both receipts visible on both phones, none missing |
| 20 | Both phones offline, ₹500 installment each on the same ₹2000 bill, then online | Within a few minutes both phones show the bill with ₹1000 paid, ₹1000 balance |

## 5. Known limits (tell the client)

- One gym per account. Using the **same account on two phones at the same time** works for
  sync, but bill/receipt numbers are generated per phone and could repeat.
- Sync runs while the app is open (and immediately when it is reopened); it does not run while
  the app is fully closed.
- Notification history is per phone and is not restored (reminders are regenerated automatically).
