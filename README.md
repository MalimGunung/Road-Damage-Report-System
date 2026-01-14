# Road Damage Report System 🚧🛣️

**Road Damage Report System** is a Flutter mobile app for reporting and notifying users about road damage (potholes, cracks, etc.). The project includes client-side Flutter code and server-side notification helper logic (FCM via a Google service account).

---

##  Overview

- **Platform:** Flutter (cross-platform mobile)
- **Purpose:** Let users submit road damage reports and broadcast notifications to subscribed users via Firebase Cloud Messaging (FCM).
- **Repository layout:** top-level project folder is `flutter_661` (app code lives in this folder).

---

## Tech Stack & Environment

- Flutter (stable channel) and Dart
- Firebase services: FCM (Cloud Messaging) — optional: Firestore/Realtime Database for reports
- Development OS: Windows / macOS / Linux (Android and iOS toolchains supported)
- Tools:
  - Git & GitHub CLI (`gh`)
  - Android SDK / Xcode (for building to device/emulator)

Minimum checks:
```bash
flutter --version
git --version
gh --version
```

---

## Setup & Quick Start

1. Clone the repository and open the `flutter_661` folder:

```bash
git clone https://github.com/MalimGunung/Road-Damage-Report-System.git
cd Road-Damage-Report-System
cd flutter_661
```

2. Install dependencies:

```bash
flutter pub get
```

3. Configure Firebase (local only — DO NOT commit credentials):
   - Create a Firebase project and configure Android/iOS apps.
   - Download `google-services.json` and place it into `android/app/`.
   - Download `GoogleService-Info.plist` and place it into `ios/Runner/`.

4. Configure service account for server-side FCM sending (recommended):
   - Create a Google Cloud service account with `Firebase Cloud Messaging` permissions and download the JSON key.
   - Save the file as `service_account.json` at the project root (or a secure path) and add it to `.gitignore`.
   - Locally set the environment variable (example):

Windows (PowerShell):
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\path\to\service_account.json"
```

macOS / Linux:
```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service_account.json"
```

5. Run the app:

```bash
flutter run -d <device>
```

---

## Security & Secrets

**Important:** This repo uses push protection and secret scanning. Do not commit service account keys, `google-services.json`, or other credentials to the repository.

- Files to keep out of git (already added to `.gitignore`):
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `service_account.json`

If a secret is accidentally committed:
- Revoke/regenerate the secret immediately.
- Remove it from Git history (tools like `git filter-repo` or follow GitHub's guidance) and force-push the cleaned history.

Note: I already removed an embedded service-account secret from `lib/noti.dart` and updated `.gitignore` for `google-services.json` and `service_account.json`.

---

## Notifications & Server Setup

- Client notifications are handled by `lib/noti.dart`. The code previously contained an inlined service account — this was removed for security.
- Use a local `service_account.json` or GitHub Secrets + a CI/Cloud Function to obtain server tokens and send FCM messages.

---

## Development & CI suggestions

- Run static analysis and tests locally:
```bash
flutter analyze
flutter test
```

- Optional: Add a GitHub Actions workflow to run `flutter analyze` and `flutter test` on PRs.
- Use GitHub Secrets for CI to store `SERVICE_ACCOUNT_JSON` securely if you need automated notification tasks.

---

## 📄 License

This project does not include a license file by default. Consider adding an open source license (MIT, Apache-2.0, etc.) if you want to allow others to use your code.

