# 💰 Family Ledger

<p align="center">
  <strong>A shared family expense tracker built with Flutter & Firebase</strong><br/>
  Track contributions, expenses, budgets, and your family's shared financial pool — all in one place.
</p>

---

## ✨ Features

### 🔐 Authentication & Security
- **Google Sign-In** — secure one-tap authentication
- **Biometric Lock** — fingerprint / face unlock to protect your data
- **Private Transactions** — mark any transaction as private; only you can see it

### 💸 Transaction Management
- Add **Income** or **Expense** entries in seconds
- Assign **custom categories** (Groceries, Rent, Food, Transport, etc.)
- **Shared vs Private** visibility control per transaction
- Swipe to **edit or delete** transactions with smooth animations
- Filter and search across all transactions

### 👨‍👩‍👧‍👦 Family & Collaboration
- **Create** a new family group or **Join** an existing one via invite code
- Real-time sync — all members see changes instantly via Firestore
- View each member's **contribution %** and **spending breakdown**
- Family shared pool (total income vs total expenses)

### 📊 Statistics & Analytics
- **Animated Donut Chart** — category-wise expense breakdown with interactive legend
- **Bar Chart** — monthly income vs expense trends
- **Budget Tracking** — set monthly budgets per category with progress indicators and overspend alerts
- **Member Stats** — top contributors and top spenders leaderboard

### 🗂️ Tracking Tabs
- Create **custom tabs** (e.g., Vacation Fund, Home Renovation) to track separate pools
- Each tab has its own transactions isolated from the main ledger

### 🎨 UI & Experience
- **Light / Dark / System** theme with smooth toggle
- Animated transitions and micro-interactions via `flutter_animate`
- Fully **Material 3** design with a premium teal colour scheme
- Optimised for **INR (₹)** currency formatting

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3 (Dart) |
| Database | Firebase Cloud Firestore |
| Authentication | Google Sign-In + Firebase Auth |
| State Management | Provider |
| Charts | fl_chart |
| Animations | flutter_animate |
| Local Auth | local_auth (biometrics) |
| Formatting | intl |
| Offline Detection | connectivity_plus |
| Persistence | shared_preferences |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry point
├── auth_wrapper.dart           # Auth state router
├── firebase_options.dart       # Firebase config (auto-generated)
├── models/                     # Data models
│   ├── transaction_model.dart
│   ├── family_model.dart
│   ├── user_model.dart
│   ├── budget_model.dart
│   ├── category_model.dart
│   ├── tracking_tab_model.dart
│   └── filter_model.dart
├── providers/
│   └── theme_provider.dart     # Theme state (light/dark/system)
├── screens/                    # App screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── add_transaction_screen.dart
│   ├── stats_screen.dart
│   ├── settings_screen.dart
│   ├── family_setup_screen.dart
│   └── category_management_screen.dart
├── services/                   # Business logic & Firebase
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── biometric_service.dart
├── widgets/                    # Reusable UI components
│   ├── animated_pie_chart.dart
│   ├── animated_bar_chart.dart
│   └── app_bar_action_button.dart
└── utils/                      # Helpers & utilities
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.0.0 or higher**
- [Firebase CLI](https://firebase.google.com/docs/cli) installed and authenticated
- A Firebase project with **Firestore** and **Authentication (Google)** enabled
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) for config generation

---

### 1. Clone the Repository

```bash
git clone <repository-url>
cd family_ledger
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

Generate the `firebase_options.dart` file using FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This creates `lib/firebase_options.dart` linked to your Firebase project.

> **Google Sign-In on Web:** Add your local dev URL (e.g., `http://localhost:5000`) as an **Authorized JavaScript Origin** in [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/).

### 4. Environment File

Place your environment variables inside `assets/env` (the app reads this via `flutter_dotenv`). Consult the project maintainer for required keys.

### 5. Firestore Security Rules

Deploy the included rules to your Firebase project:

```bash
firebase deploy --only firestore:rules
```

---

## ▶️ Running the App

### Android (Physical Device or Emulator)

```bash
# List available devices
flutter devices

# Run on a connected Android device / emulator
flutter run -d <device-id>

# Or simply (picks the first available device)
flutter run
```

### Web (Chrome)

```bash
# Run with a fixed port (required for Google Sign-In redirect)
flutter run -d web-server --web-port 5000
```

Then open **http://localhost:5000** in Chrome.

### iOS (Mac only)

```bash
flutter run -d ios
```

---

## 📦 Building the APK (Android)

### Debug APK (for testing)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

---

### Release APK (for distribution / install on device)

#### Step 1 — Create a Keystore (first time only)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

#### Step 2 — Configure Signing in Flutter

Create the file `android/key.properties`:

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<full-path-to>/upload-keystore.jks
```

Update `android/app/build.gradle` to reference the keystore (see [Flutter signing docs](https://docs.flutter.dev/deployment/android#signing-the-app)).

#### Step 3 — Build the Release APK

```bash
flutter build apk --release --no-tree-shake-icons
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Step 4 — Install on Device

```bash
# Via ADB (USB debugging enabled)
adb install build/app/outputs/flutter-apk/app-release.apk

# Or copy the APK to your device manually
```

---

### App Bundle (for Google Play Store)

```bash
flutter build appbundle --release --no-tree-shake-icons
```

Output: `build/app/outputs/bundle/release/app-release.aab`

Upload the `.aab` file to the [Google Play Console](https://play.google.com/console).

---

## 🌐 Building for Web (Production)

```bash
flutter build web --release --no-tree-shake-icons
```

Output: `build/web/` — deploy this folder to Firebase Hosting, Vercel, or any static host.

```bash
# Deploy to Firebase Hosting
firebase deploy --only hosting
```

---

## 🔒 Firestore Security Rules Summary

| Collection | Read | Write |
|---|---|---|
| `users` | Any signed-in user | Own document only |
| `families` | Any signed-in user | Members or joining user |
| `families/categories` | Family members only | Family members only |
| `families/budgets` | Family members only | Family members only |
| `transactions` | Owner or family member | Owner only (update/delete) |
| `tracking_tabs` | Same-family members | Same-family members |

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push and open a Pull Request

---

## 📄 License

This project is private. All rights reserved.
