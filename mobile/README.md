# Club 100 The Gym — Offline-First Flutter Mobile App

An offline-first Flutter mobile application for Android and iOS designed for **Club 100 The Gym**.

---

## 🛠️ Key Features

- **100% Offline-First**: Uses local SQLite database (`sqflite`) for all operational member, payment, and membership data.
- **Security & Biometrics**: 4-6 digit MPIN hashed with SHA-256 and stored in `flutter_secure_storage`. Supports device fingerprint/face login via `local_auth`.
- **Dashboard**: Interactive summary cards (*Total Members*, *Active*, *Due Soon*, *Due Today*, *Overdue*, *Expiring Soon*).
- **Sequential PDF Receipts & QR Verification**: Generates sequential receipt numbers (`GYM-YYYY-00001`), printable/shareable PDF receipts, and SHA-256 tamper-resistant QR codes for offline verification scanning.
- **Direct SMS Launcher**: Trigger client SMS reminders with pre-filled templates via native device SMS composer.
- **Encrypted Backups**: Export and import encrypted `.gymbackup` files.

---

## 📖 Complete Developer Documentation

For full architecture details, model schemas, and design guidelines, see:
👉 **[DEVELOPER_DOCS.md](../DEVELOPER_DOCS.md)**

---

## 🚀 Build Instructions

```bash
# Get dependencies
flutter pub get

# Static code analysis
flutter analyze

# Build Android APK
flutter build apk --debug
```
