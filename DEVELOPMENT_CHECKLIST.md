# ✅ MiLingo Setup Checklist

Use this checklist to track your progress from boilerplate to production app.

## 📋 Phase 0: Initial Setup (COMPLETED ✅)

- [x] Create project structure
- [x] Configure pubspec.yaml with all dependencies
- [x] Install dependencies (`flutter pub get`)
- [x] Run code generation (`build_runner`)
- [x] Set up core infrastructure (routing, theme, networking)
- [x] Create folder structure for all features
- [x] Add documentation (README, ARCHITECTURE, QUICKSTART)
- [x] Configure VS Code tasks and launch configs
- [x] Run `flutter analyze` (no critical errors)

## 📋 Phase 1: Firebase Setup

- [ ] Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
- [ ] Run `flutterfire configure` and select project
- [ ] Verify `google-services.json` in `android/app/`
- [ ] Verify `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Uncomment Firebase providers in `lib/core/providers/firebase_providers.dart`
- [ ] Enable Firebase Authentication in Firebase Console
- [ ] Enable Cloud Firestore in Firebase Console
- [ ] Set up Firestore security rules
- [ ] Test Firebase connection

## 📋 Phase 2: API Configuration

- [ ] Get Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
- [ ] Update `geminiApiKey` in `lib/core/constants/app_constants.dart`
- [ ] Test Gemini API with sample image
- [ ] Get PayOS credentials (if implementing payments)
- [ ] Update PayOS config in `app_constants.dart`
- [ ] Consider moving API keys to environment variables

## 📋 Phase 3: Authentication Feature

### Repository Layer

- [ ] Create `lib/features/auth/repositories/auth_repository.dart`
- [ ] Implement Firebase Auth email/password methods
- [ ] Implement Firebase Auth Google Sign-In
- [ ] Implement user profile CRUD in Firestore
- [ ] Add error handling and exceptions

### Controller Layer

- [ ] Create `lib/features/auth/controllers/auth_controller.dart`
- [ ] Implement sign-in state management
- [ ] Implement sign-up state management
- [ ] Implement sign-out logic
- [ ] Handle loading and error states
- [ ] Add auth state persistence

### Screen Layer

- [ ] Create `lib/features/auth/screens/login_screen.dart`
- [ ] Create `lib/features/auth/screens/signup_screen.dart`
- [ ] Create `lib/features/auth/screens/forgot_password_screen.dart`
- [ ] Create `lib/features/auth/screens/profile_screen.dart`
- [ ] Add form validation
- [ ] Add loading indicators
- [ ] Add error messages

### Testing

- [ ] Write unit tests for AuthRepository
- [ ] Write unit tests for AuthController
- [ ] Write widget tests for login screen
- [ ] Write widget tests for signup screen

## 📋 Phase 4: Snap & Learn Feature

### Repository Layer

- [ ] Create `lib/features/snap_and_learn/repositories/vocabulary_repository.dart`
- [ ] Implement Firestore CRUD for vocabulary items
- [ ] Implement image upload to Firebase Storage
- [ ] Add offline caching with SharedPreferences

### Controller Layer

- [ ] Create `lib/features/snap_and_learn/controllers/camera_controller.dart`
- [ ] Create `lib/features/snap_and_learn/controllers/vocabulary_controller.dart`
- [ ] Implement image capture logic
- [ ] Implement Gemini API integration
- [ ] Handle AI response parsing
- [ ] Add retry logic for failed requests

### Screen Layer

- [ ] Create `lib/features/snap_and_learn/screens/camera_screen.dart`
- [ ] Create `lib/features/snap_and_learn/screens/result_screen.dart`
- [ ] Create `lib/features/snap_and_learn/screens/vocabulary_list_screen.dart`
- [ ] Implement camera UI with image picker
- [ ] Implement image cropping
- [ ] Display vocabulary results with pronunciation
- [ ] Add Text-to-Speech for pronunciation
- [ ] Add save to flashcards button

### Testing

- [ ] Write unit tests for VocabularyRepository
- [ ] Write unit tests for GeminiApiService
- [ ] Write widget tests for camera screen
- [ ] Test image processing flow end-to-end

## 📋 Phase 5: Flashcards Feature

### Models

- [ ] Create `lib/features/flashcards/models/flashcard.dart`
- [ ] Create `lib/features/flashcards/models/review_session.dart`
- [ ] Add spaced repetition algorithm data

### Repository Layer

- [ ] Create `lib/features/flashcards/repositories/flashcard_repository.dart`
- [ ] Implement Firestore CRUD for flashcards
- [ ] Implement query for due flashcards
- [ ] Track review statistics

### Controller Layer

- [ ] Create `lib/features/flashcards/controllers/flashcard_controller.dart`
- [ ] Implement SRS (Spaced Repetition System) algorithm
- [ ] Calculate next review date
- [ ] Update mastery levels
- [ ] Track review statistics

### Screen Layer

- [ ] Create `lib/features/flashcards/screens/flashcard_deck_screen.dart`
- [ ] Create `lib/features/flashcards/screens/flashcard_review_screen.dart`
- [ ] Create `lib/features/flashcards/screens/statistics_screen.dart`
- [ ] Implement card flip animation
- [ ] Add swipe gestures for review
- [ ] Display progress tracking

### Testing

- [ ] Write unit tests for SRS algorithm
- [ ] Write unit tests for FlashcardRepository
- [ ] Write widget tests for review screen

## 📋 Phase 6: Gamification Feature

### Models

- [ ] Create `lib/features/gamification/models/streak.dart`
- [ ] Create `lib/features/gamification/models/achievement.dart`
- [ ] Create `lib/features/gamification/models/leaderboard_entry.dart`

### Repository Layer

- [ ] Create `lib/features/gamification/repositories/gamification_repository.dart`
- [ ] Implement daily streak tracking
- [ ] Implement coin transactions
- [ ] Implement leaderboard queries
- [ ] Track achievements

### Controller Layer

- [ ] Create `lib/features/gamification/controllers/streak_controller.dart`
- [ ] Create `lib/features/gamification/controllers/leaderboard_controller.dart`
- [ ] Implement daily check-in logic
- [ ] Calculate coin rewards
- [ ] Update leaderboard rankings

### Screen Layer

- [ ] Create `lib/features/gamification/screens/leaderboard_screen.dart`
- [ ] Create `lib/features/gamification/screens/achievements_screen.dart`
- [ ] Create `lib/features/gamification/screens/rewards_screen.dart`
- [ ] Display streak counter on home screen
- [ ] Show coin balance
- [ ] Animate rewards

### Testing

- [ ] Write unit tests for streak logic
- [ ] Write unit tests for coin system
- [ ] Write unit tests for leaderboard

## 📋 Phase 7: Home & Navigation

### Home Screen

- [ ] Create `lib/features/home/screens/home_screen.dart`
- [ ] Display user stats (streak, coins, progress)
- [ ] Show featured content
- [ ] Quick access to Snap & Learn
- [ ] Navigation to all features

### Navigation

- [ ] Implement bottom navigation bar
- [ ] Add app drawer (optional)
- [ ] Configure deep linking
- [ ] Add auth guards to routes
- [ ] Test navigation flows

## 📋 Phase 8: Polish & UX

### UI/UX Improvements

- [ ] Add smooth animations between screens
- [ ] Implement shimmer loading effects
- [ ] Add haptic feedback
- [ ] Create custom app icons
- [ ] Design splash screen
- [ ] Add onboarding flow for new users

### Error Handling

- [ ] Implement global error handling
- [ ] Add user-friendly error messages
- [ ] Create offline mode messaging
- [ ] Add retry mechanisms
- [ ] Log errors to Firebase Crashlytics

### Performance

- [ ] Optimize image loading
- [ ] Implement pagination for lists
- [ ] Add caching strategies
- [ ] Reduce build size
- [ ] Profile app performance

## 📋 Phase 9: Testing

### Unit Tests

- [ ] Test all models
- [ ] Test all repositories
- [ ] Test all controllers
- [ ] Test utility functions
- [ ] Aim for >80% code coverage

### Widget Tests

- [ ] Test all screens
- [ ] Test all custom widgets
- [ ] Test user interactions
- [ ] Test form validation

### Integration Tests

- [ ] Test authentication flow
- [ ] Test Snap & Learn flow
- [ ] Test flashcard review flow
- [ ] Test payment flow (if implemented)

## 📋 Phase 10: Deployment Preparation

### App Store Setup

- [ ] Create app icon (1024x1024)
- [ ] Design screenshots for stores
- [ ] Write app description
- [ ] Prepare privacy policy
- [ ] Prepare terms of service

### Android Deployment

- [ ] Generate keystore for signing
- [ ] Configure `android/app/build.gradle`
- [ ] Update app name and package
- [ ] Test release build
- [ ] Prepare store listing

### iOS Deployment

- [ ] Set up Apple Developer account
- [ ] Configure provisioning profiles
- [ ] Update `ios/Runner/Info.plist`
- [ ] Test release build
- [ ] Prepare store listing

### Final Checks

- [ ] Test on multiple devices
- [ ] Test on different screen sizes
- [ ] Test offline functionality
- [ ] Check app performance
- [ ] Verify all API keys are secured

## 📋 Phase 11: Launch

- [ ] Submit to Google Play Store
- [ ] Submit to Apple App Store
- [ ] Set up Firebase Analytics
- [ ] Configure Firebase Crashlytics
- [ ] Monitor user feedback
- [ ] Plan updates and new features

---

## 📊 Progress Tracking

**Current Phase:** Phase 0 ✅ (Initial Setup Complete)

**Next Steps:**

1. Configure Firebase
2. Add API keys
3. Start implementing Authentication

**Estimated Timeline:**

- Phase 1-2: 1-2 days
- Phase 3: 1 week
- Phase 4: 2-3 weeks
- Phase 5: 1-2 weeks
- Phase 6: 1 week
- Phase 7-8: 1 week
- Phase 9: 1 week
- Phase 10-11: 1 week

**Total Estimated Time:** 8-12 weeks for complete app

---

**Keep this file updated as you progress through development!** ✅
