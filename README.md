# Club 100 The Gym — Web Application & Offline-First Mobile App

Official codebase for **Club 100 The Gym** (TP Nagar, Transport Nagar, Prayagraj).

This repository contains two main projects:
1. **Next.js Web App & Admin Portal** (`app/`, `models/`, `lib/`) — Single-page landing site and MongoDB-backed Admin Content Management System.
2. **Offline-First Flutter Mobile App** (`mobile/`) — Standalone Android/iOS app for gym member management, payments, sequential PDF receipts, offline QR verification, and local reminders.

---

## 📚 Developer Documentation

For complete architecture, database schemas, security designs, and API specifications, please refer to:
👉 **[DEVELOPER_DOCS.md](file:///d:/scratch/club-100-gym/DEVELOPER_DOCS.md)**

---

## ⚡ Quick Start Guide

### Running Web Application (Next.js)
```bash
# Install dependencies
pnpm install

# Start dev server
pnpm dev
```
Open [http://localhost:3000](http://localhost:3000) to view the landing page.
Admin Login portal is located at `/admin/login`.

### Running Mobile Application (Flutter)
```bash
cd mobile

# Fetch pub packages
flutter pub get

# Run static analysis
flutter analyze

# Build Android Debug APK
flutter build apk --debug
```

---

## 🎨 Design & Credits
- **Theme**: Dark Neon (`#0B0C10` background, `#13151B` cards, `#B5F63D` neon accent)
- **Developer Credit**: Designed and Developed by [DevFoxx Labs](http://devfoxxlabs.com)
