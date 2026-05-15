# MiLingo Architecture

Last updated: 2026-05-14

This file records the current Flutter project structure and the conventions to follow when adding or refactoring code.

## Overview

MiLingo is a Flutter mobile app for AI-assisted language learning. The primary user flow is:

1. Splash checks Firebase session.
2. Unauthenticated users go to login/register.
3. Authenticated users go directly to Snap & Learn.
4. Main feature tabs are accessed through the shared bottom navigation bar.

The app currently uses:

- Flutter + Material 3
- Riverpod for app state
- GoRouter for routing
- Firebase Auth and Firebase initialization
- Dio-based Milingo backend API client
- Camera/image picker and Flutter TTS
- Feature-first folder organization

## Architecture Style

The project is feature-first with shared core infrastructure.

- `core/` contains app-wide infrastructure: constants, routing, theme, backend/API clients, and global providers.
- `features/` contains bounded product areas such as auth, Snap & Learn, flashcards, profile, and gamification.
- `shared/` contains reusable UI widgets and utility helpers that are not owned by one feature.

The current codebase does not consistently use separate `controllers/` or `repositories/` folders. State is mostly in `providers/`, screens are in `screens/`, data classes are in `models/`, and feature-specific UI pieces are in `widgets/`.

## Current Folder Structure

```text
lib/
|-- main.dart
|-- core/
|   |-- constants/
|   |   `-- app_constants.dart
|   |-- network/
|   |   |-- ai_provider.dart
|   |   |-- ai_response_parser.dart
|   |   |-- ai_service.dart
|   |   |-- dio_client.dart
|   |   |-- gemini_api_service.dart
|   |   |-- milingo_api_service.dart
|   |   |-- milingo_models.dart
|   |   `-- openai_api_service.dart
|   |-- providers/
|   |   `-- firebase_providers.dart
|   |-- routing/
|   |   |-- app_router.dart
|   |   `-- app_router.g.dart
|   `-- theme/
|       `-- app_theme.dart
|-- features/
|   |-- auth/
|   |   |-- models/
|   |   |   `-- user_model.dart
|   |   |-- providers/
|   |   |   `-- auth_provider.dart
|   |   |-- screens/
|   |   |   |-- choose_language_screen.dart
|   |   |   |-- login_screen.dart
|   |   |   `-- register_screen.dart
|   |   `-- widgets/
|   |       `-- social_buttons.dart
|   |-- flashcards/
|   |   |-- models/
|   |   |   |-- deck_arg.dart
|   |   |   `-- flashcard_models.dart
|   |   |-- providers/
|   |   |   `-- flashcard_provider.dart
|   |   |-- screens/
|   |   |   |-- all_categories_screen.dart
|   |   |   |-- deck_screen.dart
|   |   |   |-- exam_screen.dart
|   |   |   `-- flashcards_screen.dart
|   |   `-- widgets/
|   |       |-- deck_list_item.dart
|   |       |-- exam_banner.dart
|   |       |-- quick_card.dart
|   |       `-- vocab_card.dart
|   |-- gamification/
|   |   `-- providers/
|   |       `-- user_stats_provider.dart
|   |-- home/
|   |   `-- screens/
|   |       `-- simple_home_screen.dart
|   |-- leaderboard/
|   |   `-- screens/
|   |       `-- leaderboard_screen.dart
|   |-- profile/
|   |   |-- providers/
|   |   |   `-- profile_provider.dart
|   |   `-- screens/
|   |       `-- profile_screen.dart
|   |-- snap_and_learn/
|   |   |-- models/
|   |   |   |-- milingo_result.dart
|   |   |   `-- vocabulary_item.dart
|   |   |-- providers/
|   |   |   `-- snap_provider.dart
|   |   |-- screens/
|   |   |   `-- snap_and_learn_screen.dart
|   |   `-- widgets/
|   |       |-- bottom_capture_bar.dart
|   |       |-- save_flashcard_sheet.dart
|   |       `-- vocab_bubble.dart
|   `-- splash/
|       `-- screens/
|           `-- splash_screen.dart
`-- shared/
    |-- utils/
    |   |-- extensions.dart
    |   `-- image_utils.dart
    `-- widgets/
        |-- app_bottom_nav_bar.dart
        |-- common_widgets.dart
        `-- floating_nav_button.dart
```

## Routing

Routes are centralized in `lib/core/routing/app_router.dart`.

Current route constants live in `AppConstants`:

```text
/                         splash
/auth                     login
/register                 register
/choose-language          post-registration language choice
/home                     home/coach dashboard
/snap-and-learn           camera-first Snap & Learn flow
/flashcards               Learn/flashcards overview
/flashcards/all-categories
/flashcards/deck
/flashcards/exam
/profile
/leaderboard
```

The router currently has an auth guard:

- Public routes: `/`, `/auth`, `/register`
- Protected routes redirect to `/auth` when `FirebaseAuth.instance.currentUser` is null.
- Splash routes logged-in users directly to `/snap-and-learn`.
- Login routes successful users directly to `/snap-and-learn`.

## Main Navigation

Main tabs use `lib/shared/widgets/app_bottom_nav_bar.dart`.

Tab mapping:

```text
0 - Home       -> /home
1 - Vocabulary -> /flashcards
2 - Snap       -> /snap-and-learn
3 - Progress   -> /leaderboard
4 - Profile    -> /profile
```

Snap is intentionally centered and selected when users first enter the app after login/session restore.

`floating_nav_button.dart` is now legacy UI from the previous top-right dropdown navigation. It remains in the repo but is not referenced by the current main tab screens.

## Core Network Layer

Use `MilingoApiService` for backend calls. Do not create raw Dio clients in widgets or feature providers.

Important files:

- `milingo_api_service.dart` - Dio client, Firebase token interceptor, backend methods.
- `milingo_models.dart` - backend response models.
- `dio_client.dart` - kept for PayOS-related HTTP work.
- `ai_service.dart`, `gemini_api_service.dart`, `openai_api_service.dart`, `ai_provider.dart` - older/direct AI paths kept for compatibility and experiments. New Snap & Learn flow should go through the backend API.

Backend base URL is currently:

```dart
AppConstants.milingoBaseUrl = 'http://10.0.2.2:5098';
```

This is correct for Android emulator. Use a LAN IP for a physical Android device and `localhost` for iOS simulator when needed.

## State Management

Use Riverpod consistently.

Current provider patterns:

- `appRouterProvider` generated by `riverpod_annotation`.
- `snapControllerProvider` is a `StateNotifierProvider<SnapController, SnapState>`.
- `flashcardProvider` is an `AsyncNotifierProvider<FlashcardNotifier, FlashcardState>`.
- `flashcardStateProvider` is a sync shim for widgets that do not need loading state.
- `userStatsProvider` is an `AsyncNotifierProvider<UserStatsNotifier, UserStatsResponse>`.
- `userStatsValueProvider` is a sync shim with default zero values.
- `supportedLanguagesProvider` is a `FutureProvider<List<SupportedLanguage>>`.
- `authServiceProvider` wraps backend profile initialization.

When state has async initialization or server refreshes, prefer `AsyncNotifier`. For simple screen flow state, `StateNotifier` is acceptable.

## Feature Notes

### Auth

Files:

- `login_screen.dart`
- `register_screen.dart`
- `choose_language_screen.dart`
- `auth_provider.dart`

Current behavior:

- Login uses `FirebaseAuth.instance.signInWithEmailAndPassword`.
- Register uses Firebase account creation.
- Choose Language fetches supported languages from backend and calls `initProfile`.
- After successful login or startup session restore, the app goes to Snap & Learn.

Remaining gaps:

- Forgot-password action is still empty.
- Social buttons are UI only unless individually wired.

### Snap & Learn

Files:

- `snap_and_learn_screen.dart`
- `snap_provider.dart`
- `bottom_capture_bar.dart`
- `save_flashcard_sheet.dart`
- `vocab_bubble.dart`

Current behavior:

- Uses embedded camera preview plus gallery picker.
- Analyzes images through `MilingoApiService.analyzeSnap`.
- Maps backend `SnapVocabItem` to UI-facing `MilingoResult`.
- Keeps `MilingoResult` shape stable for UI widgets.
- Updates user stats optimistically with `coinsAwarded`.
- Can save vocabulary into flashcard decks.
- Snap is a full-screen camera route and does not show the shared bottom tab bar.

### Flashcards / Vocabulary

Files:

- `flashcard_provider.dart`
- `flashcard_models.dart`
- `flashcards_screen.dart`
- `all_categories_screen.dart`
- `deck_screen.dart`
- `exam_screen.dart`

Current behavior:

- `flashcardProvider` loads decks from backend and supports optimistic deck/card mutations.
- `flashcards_screen.dart` currently reads real provider state for decks/cards counts and recent cards.
- Some deeper screens may still contain sample/fallback vocabulary and should be checked before assuming they are fully backend-driven.

### Gamification

Files:

- `user_stats_provider.dart`

Current behavior:

- Fetches user stats from backend.
- Can record flashcard study.
- Can optimistically add snap coins and total points.
- Home/profile use stats through provider shims.

### Home

File:

- `simple_home_screen.dart`

Current behavior:

- Dashboard-style screen with stats, streak row, upgrade banner, feature cards.
- Uses `userStatsValueProvider`.
- Uses shared bottom navigation with Home selected.

### Profile

Files:

- `profile_screen.dart`
- `profile_provider.dart`

Current behavior:

- Profile UI has tabs, account/settings/premium UI, language settings, stats, and logout.
- Uses bottom navigation with Profile selected.

### Leaderboard / Progress

File:

- `leaderboard_screen.dart`

Current behavior:

- Placeholder screen with bottom navigation.
- Needs actual leaderboard implementation and backend endpoint.

## Assets

Important asset folders:

```text
assets/images/
assets/svg/
```

The app uses `flutter_svg` for SVG assets such as navigation icons and the logo. Keep new assets registered under the existing asset directories in `pubspec.yaml`.

## Code Generation

`app_router.dart` uses a generated part:

```dart
part 'app_router.g.dart';
```

Run generation when editing Riverpod annotation files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Most current feature providers are manually declared and do not require generated files.

## Coding Conventions

- Use `snake_case.dart` filenames.
- Use `PascalCase` for classes and widgets.
- Use `camelCase` for variables, fields, and methods.
- Keep feature-specific UI under that feature's `widgets/` folder.
- Put app-wide reusable widgets under `shared/widgets/`.
- Put backend DTOs in `core/network/milingo_models.dart`.
- Put feature UI state/data models under the feature's `models/`.
- Keep API calls out of widgets; route through providers/services.
- Use `context.go` for switching main tabs and `context.push` for drill-in flows.
- Preserve the current color scheme in `AppTheme` unless doing an intentional design pass.
- Avoid introducing new folder types unless the feature actually needs them.

## Documentation Status

The root markdown files overlap heavily. `AGENT_CONTEXT.md` and this file should be treated as the current source of truth for structure and coding conventions.

See `AGENT_CONTEXT.md` for a short audit of stale or overlapping documentation.
