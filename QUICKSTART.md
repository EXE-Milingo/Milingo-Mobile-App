# MiLingo Quick Start Guide

## ✅ Setup Complete!

Your MiLingo Flutter app boilerplate is ready! Here's what has been set up:

### 📁 Project Structure Created

```
milingo_flutter_2/
├── lib/
│   ├── main.dart                    ✅ App entry point with Riverpod
│   ├── core/                        ✅ Core infrastructure
│   │   ├── constants/              ✅ App constants
│   │   ├── theme/                  ✅ Material Design theme
│   │   ├── routing/                ✅ GoRouter navigation
│   │   ├── network/                ✅ Gemini AI + Dio HTTP client
│   │   └── providers/              ✅ Firebase providers
│   ├── features/                    ✅ Feature modules
│   │   ├── auth/                   ✅ Authentication (with user model)
│   │   ├── snap_and_learn/         ✅ AI image recognition (with vocabulary model)
│   │   ├── flashcards/             ✅ Spaced repetition
│   │   └── gamification/           ✅ Streaks & coins
│   └── shared/                      ✅ Shared widgets & utils
│       ├── widgets/                ✅ Common UI components
│       └── utils/                  ✅ Extensions & helpers
├── pubspec.yaml                     ✅ Dependencies configured
├── README.md                        ✅ Project documentation
├── ARCHITECTURE.md                  ✅ Architecture guide
├── .gitignore                       ✅ Git configuration
└── analysis_options.yaml            ✅ Linting rules
```

### 📦 Dependencies Installed

- ✅ **State Management**: flutter_riverpod + riverpod_annotation
- ✅ **Routing**: go_router
- ✅ **Firebase**: firebase_core, firebase_auth, cloud_firestore
- ✅ **Camera**: image_picker, image_cropper
- ✅ **AI**: google_generative_ai (Gemini)
- ✅ **Audio**: flutter_tts
- ✅ **Network**: dio
- ✅ **Code Generation**: build_runner, riverpod_generator

### 🔧 Core Components Created

1. **`main.dart`** - App initialization with Riverpod ProviderScope
2. **`GeminiApiService`** - AI-powered image analysis with structured vocabulary response
3. **`AppRouter`** - GoRouter configuration with placeholder screens
4. **`AppTheme`** - Material 3 theme with MiLingo branding
5. **`AppConstants`** - Centralized configuration
6. **Models** - UserModel, VocabularyItem with JSON serialization

---

## 🚀 Next Steps

### 1. Configure Firebase (Required before running)

**a. Create Firebase Project:**

- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project named "MiLingo"

**b. Add Flutter App:**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your Flutter app
flutterfire configure
```

**c. Enable Services:**

- Enable **Authentication** (Email/Password, Google Sign-In)
- Enable **Cloud Firestore**
- Create Firestore database in production mode

### 2. Add API Keys

**Edit `lib/core/constants/app_constants.dart`:**

```dart
// Get your Gemini API key from: https://makersuite.google.com/app/apikey
static const String geminiApiKey = 'YOUR_ACTUAL_GEMINI_KEY';

// PayOS credentials from: https://payos.vn
static const String payOSClientId = 'YOUR_PAYOS_CLIENT_ID';
static const String payOSApiKey = 'YOUR_PAYOS_API_KEY';
```

⚠️ **Security Note**: In production, use environment variables or Firebase Remote Config!

### 3. Test the App

```bash
# Check for any issues
flutter analyze

# Run on emulator/device
flutter run
```

### 4. Implement Features

Start building your features in this order:

#### Phase 1: Authentication (Week 1)

- [ ] Implement `auth/screens/login_screen.dart`
- [ ] Create `auth/controllers/auth_controller.dart`
- [ ] Build `auth/repositories/auth_repository.dart` (Firebase Auth)
- [ ] Add email/password and Google Sign-In

#### Phase 2: Snap & Learn (Week 2-3)

- [ ] Build camera UI in `snap_and_learn/screens/camera_screen.dart`
- [ ] Implement image capture and processing
- [ ] Integrate Gemini API for vocabulary extraction
- [ ] Create result display with pronunciation (TTS)
- [ ] Save vocabulary to Firestore

#### Phase 3: Flashcards (Week 4)

- [ ] Create flashcard UI components
- [ ] Implement spaced repetition algorithm
- [ ] Build review session flow
- [ ] Track mastery levels

#### Phase 4: Gamification (Week 5)

- [ ] Implement daily streak tracking
- [ ] Create coin reward system
- [ ] Build leaderboard with Firestore queries
- [ ] Add achievement badges

#### Phase 5: Polish (Week 6)

- [ ] Add animations and micro-interactions
- [ ] Implement proper error handling
- [ ] Add loading states everywhere
- [ ] Write unit and widget tests

---

## 📝 Common Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (after changing @riverpod files)
dart run build_runner build --delete-conflicting-outputs

# Watch for changes (auto-regenerate)
dart run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run

# Run tests
flutter test

# Check code quality
flutter analyze

# Format code
dart format lib/

# Clean and rebuild
flutter clean && flutter pub get
```

---

## 🏗️ Architecture Tips

### Using Riverpod Providers

**Example Controller:**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_controller.g.dart';

@riverpod
class MyController extends _$MyController {
  @override
  MyState build() {
    // Initialize state
    return MyState.initial();
  }

  void doSomething() {
    // Update state
    state = state.copyWith(newValue: true);
  }
}
```

**Using in UI:**

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myControllerProvider);

    return Scaffold(
      body: Text(state.value),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(myControllerProvider.notifier).doSomething();
        },
      ),
    );
  }
}
```

### Firebase Best Practices

1. **Use Firestore Security Rules** - Protect your data
2. **Index your queries** - Firebase will prompt you
3. **Use StreamProviders** - For real-time data
4. **Batch writes** - For multiple updates

### Navigation with GoRouter

```dart
// Navigate to a route
context.go(AppConstants.homeRoute);

// Push a route (with back button)
context.push(AppConstants.snapAndLearnRoute);

// Pop back
context.pop();
```

---

## 🆘 Troubleshooting

### Build Runner Issues

```bash
# Clear build cache and rebuild
flutter clean
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Firebase Issues

- Ensure `google-services.json` (Android) is in `android/app/`
- Ensure `GoogleService-Info.plist` (iOS) is in `ios/Runner/`
- Run `flutterfire configure` to regenerate config

### Gemini API Issues

- Verify API key is correct
- Check API quotas in Google Cloud Console
- Ensure image size is under 5MB

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [GoRouter Documentation](https://pub.dev/packages/go_router)
- [Gemini API Reference](https://ai.google.dev/docs)

---

## 🎯 Sprint Planning Template

### Sprint 1 Goals

- [ ] Setup Firebase fully
- [ ] Implement authentication
- [ ] Create home screen layout

### Sprint 2 Goals

- [ ] Build camera UI
- [ ] Integrate Gemini API
- [ ] Test image processing flow

_Continue planning your sprints in this format..._

---

**You're all set!** Start by configuring Firebase, then begin implementing your authentication feature. Good luck! 🚀

If you need help with any specific feature implementation, refer to `ARCHITECTURE.md` for guidance on project structure.
