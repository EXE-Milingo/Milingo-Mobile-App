# MiLingo - AI-Powered Language Learning App

MiLingo is a Flutter-based mobile application that helps users learn vocabulary in multiple languages through AI-powered image recognition (Snap & Learn), flashcards, and gamification.

## 🚀 Features

- **Snap & Learn**: Take photos of objects and instantly learn vocabulary in your target language using Gemini AI
- **Flashcards**: Spaced repetition system for vocabulary revision
- **Gamification**: Daily streaks, MiLingo coins, and leaderboards
- **Multi-language Support**: Learn in English, Vietnamese, Japanese, Korean, Chinese, Spanish, French, German
- **Firebase Backend**: Secure authentication and cloud storage
- **PayOS Integration**: In-app purchases and premium features

## 🏗️ Architecture

This project follows **Feature-First Architecture** with Clean Architecture principles:

```
lib/
├── core/                    # Core application infrastructure
│   ├── constants/          # App-wide constants
│   ├── theme/              # Theme configuration
│   ├── routing/            # Navigation with GoRouter
│   ├── network/            # API clients (Gemini, PayOS)
│   └── providers/          # Global Riverpod providers
├── features/               # Feature modules (bounded contexts)
│   ├── auth/              # Authentication
│   ├── snap_and_learn/    # AI image recognition
│   ├── flashcards/        # Vocabulary revision
│   └── gamification/      # Streaks, coins, leaderboard
└── shared/                # Shared utilities and widgets
    ├── widgets/           # Reusable UI components
    └── utils/             # Helper functions
```

## 📦 Tech Stack

- **Framework**: Flutter 3.3+
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Firebase (Auth, Firestore)
- **AI**: Google Gemini API
- **Camera**: image_picker, image_cropper
- **Audio**: flutter_tts
- **HTTP Client**: Dio
- **Code Generation**: build_runner, riverpod_generator

## 🛠️ Setup

### Prerequisites

- Flutter SDK 3.3.0 or higher
- Dart SDK 3.0.0 or higher
- Firebase account
- Google Gemini API key
- PayOS merchant account (for payments)

### Installation

1. **Clone the repository**

   ```bash
   git clone <your-repo-url>
   cd milingo_flutter_2
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure API Keys**

   Update `lib/core/constants/app_constants.dart`:

   ```dart
   static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   static const String payOSClientId = 'YOUR_PAYOS_CLIENT_ID';
   static const String payOSApiKey = 'YOUR_PAYOS_API_KEY';
   ```

4. **Setup Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
   - Enable Firebase Authentication and Cloud Firestore

5. **Run code generation**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Development

### Code Generation

This project uses code generation for Riverpod providers. After modifying files with `@riverpod` annotations, run:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

This watches for changes and automatically generates the required `.g.dart` files.

### Linting

Run the linter to check code quality:

```bash
flutter analyze
```

### Testing

Run unit and widget tests:

```bash
flutter test
```

## 📝 Next Steps

1. **Implement Feature Screens**
   - Move placeholder screens from `app_router.dart` to their respective feature folders
   - Implement UI for Auth, Home, Snap & Learn, Flashcards, Profile, Leaderboard

2. **Complete Firebase Integration**
   - Uncomment Firebase providers in `firebase_providers.dart`
   - Implement auth repository and controllers
   - Set up Firestore data models and repositories

3. **Enhance Gemini Service**
   - Add proper JSON parsing in `gemini_api_service.dart`
   - Implement error handling and retry logic
   - Add image validation

4. **Build PayOS Integration**
   - Create payment repository
   - Implement payment flow for premium features

5. **Implement Gamification**
   - Daily streak tracking
   - Coin reward system
   - Leaderboard with Firestore queries

## 📄 License

[Add your license here]

## 👥 Contributors

[Add contributors here]

---

**Happy Coding!** 🎉

---

## 🤖 Claude Code Agent Setup

This repository contains optimization settings and rules to enable smooth AI-assisted coding using **Claude Code**.

### Team Onboarding & Environment Check

1. **Verify your local environment**:
   Run the setup script to check project prerequisites (Flutter, Dart, Git, Claude Code):
   ```powershell
   pwsh -NoProfile -File scripts/setup-claude.ps1
   ```

2. **Run setup-team skill**:
   Execute the `/setup-team` command in Claude Code to configure project MCP settings and review optional integrations (e.g. Sentry, Firebase, or vexp context engine).

3. **Verify changes before submitting**:
   After modifying code, run `/verify-flutter` to format, analyze, and test your changes:
   ```powershell
   dart format --output=none --set-exit-if-changed lib test
   flutter analyze
   flutter test
   ```

All agent workflows, priorities, and folder structure guidelines are documented in [AGENTS.md](file:///C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App/AGENTS.md). Quick agent rules are defined in [CLAUDE.md](file:///C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App/CLAUDE.md).
