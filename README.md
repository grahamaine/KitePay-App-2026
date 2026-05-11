# KitePay

> **Fly further with every payment.**

KitePay is a modern, cross-platform fintech app built with Flutter, powered by [Turnkey](https://turnkey.com) embedded wallets and [WalletConnect](https://walletconnect.com) (Reown AppKit). It combines institutional-grade key management with a polished, dark-first UI designed for the next generation of crypto payments.

---

## Features

| Feature                        | Description                                                              |
| ------------------------------ | ------------------------------------------------------------------------ |
| 🔐 Biometric Authentication    | Face ID / Fingerprint unlock on supported devices                        |
| 📱 Onboarding Flow             | Animated 3-page first-launch walkthrough                                 |
| 🔗 WalletConnect               | Connect MetaMask, Trust Wallet, Coinbase Wallet and 300+ others          |
| 💳 Wallet Dashboard            | View balance, send, receive, and track recent activity                   |
| 🌗 Theme Switcher              | Dark / Light / System theme, persisted across sessions                   |
| 🌐 Localization                | English, French, Spanish, Arabic, Chinese                                |
| 📊 Analytics                   | Firebase Analytics for screen views and key events                       |
| 🛡️ Crash Reporting             | Firebase Crashlytics for production error tracking                       |
| ☁️ Web Deployment              | Fully deployed to Vercel as a Flutter web app                            |

---

## Tech Stack

| Layer                | Technology                                      |
| -------------------- | ----------------------------------------------- |
| Framework            | Flutter 3.41 (Dart 3.3)                         |
| Wallet Key Mgmt      | Turnkey SDK (`turnkey_sdk_flutter`)             |
| WalletConnect        | Reown AppKit (`reown_appkit`)                   |
| EVM Support          | `web3dart`                                      |
| State Management     | `provider`                                      |
| Biometric Auth       | `local_auth`                                    |
| Persistent Storage   | `shared_preferences`                            |
| Analytics & Crashes  | Firebase Analytics + Firebase Crashlytics       |
| Localization         | `flutter_localizations`                         |
| Deployment           | Vercel (web) · Android APK/AAB ready            |

---

## Project Structure

```text
lib/
├── main.dart                  # App entry, providers, theme, auth gate
├── screens/
│   ├── home_screen.dart       # Dashboard + bottom nav shell
│   ├── wallet_screen.dart     # WalletConnect UI (connect, send, receive)
│   └── login_screen.dart      # Turnkey auth
└── services/
    └── agent_service.dart     # Turnkey wallet agent
```

---

## Getting Started

### Prerequisites

- Flutter 3.41+
- Dart 3.3+
- Android Studio (for Android builds)
- A [Turnkey](https://turnkey.com) organization ID
- A [Reown / WalletConnect](https://cloud.reown.com) project ID
- Firebase project (for Analytics + Crashlytics on mobile)

### Installation

```bash
# Clone the repo
git clone https://github.com/your-username/kitepay.git
cd kitepay

# Install dependencies
flutter pub get

# Run on device or emulator
flutter run \
  --dart-define=TURNKEY_ORG_ID=your_org_id \
  --dart-define=WALLETCONNECT_PROJECT_ID=your_project_id
```

### Web Build & Deploy

```bash
# Build for web
flutter build web --release

# Deploy to Vercel
vercel deploy build/web --prod
```

### Environment Variables

| Variable                    | Description                              |
| --------------------------- | ---------------------------------------- |
| `TURNKEY_ORG_ID`            | Your Turnkey organization ID             |
| `WALLETCONNECT_PROJECT_ID`  | Your Reown / WalletConnect project ID    |

Pass via `--dart-define` at build time or set in your CI/CD pipeline.

### Firebase Setup (mobile only)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
Firebase is automatically skipped on web builds.

---

## Supported Platforms

| Platform  | Status           |
| --------- | ---------------- |
| Web       | Deployed         |
| Android   | Ready to build   |
| iOS       | Ready to build   |
| Windows   | Ready to build   |

---

## License

MIT © 2026 KitePay

---

## 🚀 Live App

**[https://kitepay.vercel.app](https://kitepay.vercel.app)**
