# Club 100 The Gym — Master Developer Documentation & Architecture Guide

This repository contains the complete software suite for **Club 100 The Gym** (Transport Nagar, Prayagraj):
1. **Web Platform & MongoDB Admin Portal** (`app/`, `models/`, `lib/`) — Next.js 16 (Turbopack), Tailwind CSS v4, Framer Motion, and Mongoose API endpoints.
2. **Offline-First Mobile Application** (`mobile/`) — Flutter 3.24.4, SQLite (`sqflite`), Secure Storage, PDF receipt engine, offline QR signature verifier, and biometric authentication for Android & iOS.

---

## 🏋️ System Overview & Architecture

```text
                               ┌──────────────────────────────────────────┐
                               │            CLUB 100 THE GYM              │
                               └────────────────────┬─────────────────────┘
                                                    │
                   ┌────────────────────────────────┴────────────────────────────────┐
                   │                                                                 │
        ┌──────────▼──────────┐                                           ┌──────────▼──────────┐
        │  Web & Admin Portal │                                           │ Flutter Mobile App  │
        │      (Next.js)      │                                           │  (Android & iOS)    │
        └──────────┬──────────┘                                           └──────────▼──────────┘
                   │                                                      │  100% Offline-First
      ┌────────────┴────────────┐                                         │  SQLite Database
      │                         │                                         │  Encrypted .gymbackup
┌─────▼───────┐          ┌──────▼──────┐                                  │  Salted SHA-256 MPIN
│ Landing UI  │          │ MongoDB API │                                  │  Biometrics (local_auth)
└─────────────┘          └─────────────┘                                  │  PDF & QR Receipts
```

---

## 🌐 1. Web Application & Admin Portal (`/`)

### Stack
- **Framework**: Next.js 16.3.5 (Turbopack) / React 19 / TypeScript
- **Styling**: Tailwind CSS v4, Dark Neon Theme (`#0b0c10` background, `#13151b` surface, `#b5f63d` neon accent)
- **Database**: MongoDB via Mongoose 9.10.1
- **Icons**: Lucide React 1.47.0 + Custom Inline Brand SVGs

### Structure
- [`app/page.tsx`](file:///d:/scratch/club-100-gym/app/page.tsx): Main landing page assembling single-page sections (Hero, Features, About, 7 Services, Dynamic Membership Plans, Expert Trainers, 4.8★ Google Reviews, BMI Calculator, FAQ, Maps, Footer).
- [`app/admin/login/page.tsx`](file:///d:/scratch/club-100-gym/app/admin/login/page.tsx): Admin portal authentication page (Demo credentials hint: `admin` / `admin@club100.com` / `admin123`).
- [`app/admin/dashboard/page.tsx`](file:///d:/scratch/club-100-gym/app/admin/dashboard/page.tsx): Multi-tab Admin Management Dashboard:
  - 📋 **Pass Inquiries**: Monitor trial pass requests.
  - 💳 **Membership Plans**: Add, edit prices (monthly & yearly), features, or delete.
  - 🏋️ **Trainers**: Manage names, roles, bios, and custom image URLs (with live preview & preset pickers).
  - ⚡ **Services**: Manage service titles, categories, descriptions, and custom image URLs (with live preview & preset pickers).
  - 📍 **Contact & Social Media Links**: Manage helpline (`070843 06574`), address, hours, rating, review count, and social links (📷 Instagram, 📘 Facebook, ▶️ YouTube, 💬 WhatsApp).

### Database Models (`models/`)
- [`Plan.ts`](file:///d:/scratch/club-100-gym/models/Plan.ts): Schema for membership plans.
- [`Trainer.ts`](file:///d:/scratch/club-100-gym/models/Trainer.ts): Schema for expert trainers.
- [`Service.ts`](file:///d:/scratch/club-100-gym/models/Service.ts): Schema for offered services.
- [`GymInfo.ts`](file:///d:/scratch/club-100-gym/models/GymInfo.ts): Schema for contact details, rating, and social media URLs.
- [`Inquiry.ts`](file:///d:/scratch/club-100-gym/models/Inquiry.ts): Schema for free pass submissions.

---

## 📱 2. Offline-First Flutter Mobile App (`mobile/`)

### Stack
- **Framework**: Flutter 3.24.4 / Dart 3.5.4
- **Supported OS**: Android (Min SDK 23, Compile SDK 35) & iOS
- **Local Persistence**: `sqflite` (SQLite) + `path_provider`
- **Security**: `flutter_secure_storage` (salted SHA-256 MPIN hash), `local_auth` (Biometrics)
- **PDF & QR Receipts**: `pdf`, `printing`, `qr_flutter`, `mobile_scanner`
- **Notifications & SMS**: `flutter_local_notifications`, `url_launcher` (`sms:?body=...`)
- **Backup**: Encrypted `.gymbackup` AES-based export/import serialization

### Project Architecture (`mobile/lib/`)
```text
mobile/lib/
├── main.dart                          # App Entry Point & Setup Routing
├── core/
│   ├── theme/app_theme.dart            # Dark Neon Theme Spec (#0B0C10, #B5F63D)
│   ├── database/
│   │   ├── app_database.dart          # SQLite Helper & Migrations
│   │   └── db_tables.dart            # SQL Schema Definitions (10 Tables)
│   ├── security/
│   │   ├── security_service.dart      # MPIN Hashing & Secure Storage
│   │   └── biometric_service.dart     # Fingerprint & Face ID Handler
│   ├── notifications/
│   │   └── notification_service.dart  # Local Notification Engine
│   ├── backup/
│   │   └── backup_service.dart        # Encrypted .gymbackup Export/Import
│   ├── receipt/
│   │   ├── receipt_pdf_service.dart   # High-Res PDF Generator & Printer
│   │   └── qr_service.dart            # Tamper-Resistant QR Signature Engine
│   └── utils/
│       └── sms_launcher.dart          # Pre-filled Device SMS Trigger
├── data/
│   ├── models/                        # Domain Entities (Gym, Member, Plan, Payment, Receipt, etc.)
│   └── repositories/                  # Repositories for SQLite Persistence
├── features/
│   ├── onboarding/                    # 5-Step Setup Wizard Screens
│   ├── auth/login_screen.dart         # MPIN Keypad & Biometric Auth
│   ├── dashboard/dashboard_screen.dart# 6 Dynamic Metric Summary Cards
│   ├── members/                       # Members List, Search, Profile, Add/Edit
│   ├── payments/                      # Payment Transactions & Entry Form
│   ├── receipts/                      # PDF Receipt Preview & Offline QR Scanner
│   ├── notifications/                 # Reminder Alerts History
│   └── settings/                      # Gym Settings, Plans CRUD, Backup & Reset
└── shared/
    ├── navigation/main_navigation_screen.dart # 5-Tab Bottom Navigation Bar
    └── widgets/                        # Reusable Neon Buttons, Fields & Badges
```

### Key Mobile Workflows
1. **First-Time Setup**:
   - Welcome -> Gym Setup -> Admin Setup -> MPIN Setup (4-6 digits) -> Biometric Activation.
2. **Dashboard & Member Tracking**:
   - 6 dynamic summary cards (*Total Members*, *Active*, *Due Soon*, *Due Today*, *Overdue*, *Expiring Soon*). Tapping navigates to filtered list.
3. **Sequential Receipts & Offline QR Verification**:
   - Generates sequential receipt numbers (`GYM-YYYY-00001`).
   - Creates high-res printable/shareable PDF receipts.
   - Embeds a SHA-256 tamper-resistant signature QR payload. Scanner screen verifies authenticity offline without network connectivity.
4. **Encrypted Backup & Reset**:
   - Export encrypted `.gymbackup` files or restore from backup.
   - Danger zone application data reset with double confirmation.

---

## 🚀 Commands & Development Scripts

### Web App
```bash
# Install dependencies
pnpm install

# Run development server
pnpm dev

# Production build
pnpm build
```

### Flutter Mobile App
```bash
# Navigate to mobile workspace
cd mobile

# Install Flutter dependencies
flutter pub get

# Static code analysis
flutter analyze

# Build Android Debug APK
flutter build apk --debug
```

---

## 🛡️ License & Credits
- **Designed and Developed by**: [DevFoxx Labs](http://devfoxxlabs.com)
- **Copyright**: © 2026 Club 100 The Gym. All rights reserved.

