# MiLingo Agent Context

Read this file before making code changes. Update it whenever project structure, navigation, backend contracts, state models, or coding conventions change.

Last updated: 2026-05-14

## Project Summary

MiLingo is a Flutter mobile app for AI-assisted language learning.

Current frontend stack:

- Flutter
- Riverpod
- GoRouter
- Firebase Auth
- Dio-based Milingo backend API client
- Camera/image picker
- Flutter TTS
- Material 3 with the existing warm orange color scheme

Backend assumptions in the mobile app:

- Milingo backend base URL: `http://10.0.2.2:5098`
- Firebase Auth owns login/register.
- Backend requests use Firebase ID token via `MilingoApiService` interceptor.
- Snap analysis is backend-driven through `POST /api/v1/snap/analyze`.

## Current Project Structure

```text
lib/
|-- main.dart
|-- core/
|   |-- constants/app_constants.dart
|   |-- network/
|   |   |-- ai_provider.dart
|   |   |-- ai_response_parser.dart
|   |   |-- ai_service.dart
|   |   |-- dio_client.dart
|   |   |-- gemini_api_service.dart
|   |   |-- milingo_api_service.dart
|   |   |-- milingo_models.dart
|   |   `-- openai_api_service.dart
|   |-- providers/firebase_providers.dart
|   |-- routing/
|   |   |-- app_router.dart
|   |   `-- app_router.g.dart
|   `-- theme/app_theme.dart
|-- features/
|   |-- auth/
|   |   |-- models/user_model.dart
|   |   |-- providers/auth_provider.dart
|   |   |-- screens/choose_language_screen.dart
|   |   |-- screens/login_screen.dart
|   |   |-- screens/register_screen.dart
|   |   `-- widgets/social_buttons.dart
|   |-- flashcards/
|   |   |-- models/deck_arg.dart
|   |   |-- models/flashcard_models.dart
|   |   |-- providers/flashcard_provider.dart
|   |   |-- screens/all_categories_screen.dart
|   |   |-- screens/deck_screen.dart
|   |   |-- screens/exam_screen.dart
|   |   |-- screens/flashcards_screen.dart
|   |   |-- widgets/deck_list_item.dart
|   |   |-- widgets/exam_banner.dart
|   |   |-- widgets/quick_card.dart
|   |   `-- widgets/vocab_card.dart
|   |-- gamification/providers/user_stats_provider.dart
|   |-- home/screens/simple_home_screen.dart
|   |-- leaderboard/screens/leaderboard_screen.dart
|   |-- profile/
|   |   |-- providers/profile_provider.dart
|   |   `-- screens/profile_screen.dart
|   |-- snap_and_learn/
|   |   |-- models/milingo_result.dart
|   |   |-- models/vocabulary_item.dart
|   |   |-- providers/snap_provider.dart
|   |   |-- screens/snap_and_learn_screen.dart
|   |   |-- widgets/bottom_capture_bar.dart
|   |   |-- widgets/save_flashcard_sheet.dart
|   |   `-- widgets/vocab_bubble.dart
|   `-- splash/screens/splash_screen.dart
`-- shared/
    |-- utils/extensions.dart
    |-- utils/image_utils.dart
    |-- widgets/app_bottom_nav_bar.dart
    |-- widgets/common_widgets.dart
    `-- widgets/floating_nav_button.dart
```

## Recent Work Done

### Bottom Navigation Refactor

The app now uses a shared bottom navigation bar:

- New file: `lib/shared/widgets/app_bottom_nav_bar.dart`
- Home uses `AppBottomNavBar(currentIndex: 0)`.
- Flashcards/Learn uses `currentIndex: 1`.
- Snap & Learn uses `currentIndex: 2`.
- Profile uses `currentIndex: 3`.
- Leaderboard/Progress uses `currentIndex: 4`.

The centered Snap tab is intentional. New users and returning logged-in users should land on Snap & Learn first.

The previous top-right dropdown plus button was removed from active tab screens. `floating_nav_button.dart` is now legacy/unused unless a future design intentionally brings it back.

### Documentation Refresh

`ARCHITECTURE.md` was rewritten to match the current code structure. This file was also rewritten to be the quick-start context for future agents.

## Navigation Rules

Routes live in `AppConstants` and are wired in `app_router.dart`.

Main tab route mapping:

```text
0 Coach    -> AppConstants.homeRoute           -> /home
1 Learn    -> AppConstants.flashcardsRoute     -> /flashcards
2 Snap     -> AppConstants.snapAndLearnRoute   -> /snap-and-learn
3 Profile  -> AppConstants.profileRoute        -> /profile
4 Progress -> AppConstants.leaderboardRoute    -> /leaderboard
```

Use:

- `context.go(...)` for main-tab navigation.
- `context.push(...)` for detail/drill-in screens where back navigation matters.

Auth/navigation behavior:

- Splash waits, checks `FirebaseAuth.instance.currentUser`, then goes to Snap if logged in or Auth if not.
- Login calls `signInWithEmailAndPassword` and then goes to Snap.
- Register/choose-language flow ends at Snap.
- Router protects non-public routes by redirecting unauthenticated users to `/auth`.

## State Management Rules

Use Riverpod. Keep API and mutation logic out of screens unless it is truly local UI state.

Current provider map:

```text
appRouterProvider
authServiceProvider
supportedLanguagesProvider
snapControllerProvider
flashcardProvider
flashcardStateProvider
userStatsProvider
userStatsValueProvider
```

Patterns to follow:

- Use `AsyncNotifier` for state that loads from backend.
- Use `StateNotifier` for local feature flow state.
- Use sync shim providers only when the UI can tolerate default/fallback values.
- Do not add `setState` for global/backend state; `setState` is fine for local visual state such as toggles, tab controllers, and form loading flags.

## Backend and API Rules

Use `MilingoApiService` for backend calls. Do not call Dio directly from screens.

Important backend-related files:

- `core/network/milingo_api_service.dart`
- `core/network/milingo_models.dart`
- `core/constants/app_constants.dart`

Important current API methods used by the app:

- `getSupportedLanguages()`
- `initProfile(...)`
- `analyzeSnap(file)`
- `getDecks()`
- `createDeck(...)`
- `updateDeck(...)`
- `deleteDeck(...)`
- `getCards(deckId)`
- `addCard(...)`
- `deleteCard(...)`
- `getUserStats()`
- `recordFlashcardStudy()`

Rules:

- Firebase ID token attachment belongs in the service/interceptor.
- Keep backend DTOs in `milingo_models.dart`.
- Keep UI-facing feature models inside their feature folders.
- Do not break `MilingoResult`; Snap UI depends on that shape.
- Do not reintroduce direct Gemini/OpenAI Snap calls unless explicitly requested.

## Feature Status

### Auth

Current:

- Login uses Firebase email/password.
- Register uses Firebase account creation.
- Choose Language fetches backend supported languages and calls profile initialization.

Known gaps:

- Forgot password is not implemented.
- Social login buttons are mostly visual unless individually wired.

### Snap & Learn

Current:

- Embedded camera preview.
- Gallery picker.
- Backend snap analysis through `MilingoApiService`.
- Vocabulary overlay/result flow.
- Save to flashcard sheet.
- Optimistic user stats update from `coinsAwarded`.
- Shared bottom nav with Snap centered.

Follow:

- Keep capture UI in `snap_and_learn_screen.dart` and small reusable pieces under `snap_and_learn/widgets/`.
- Keep analysis state in `snap_provider.dart`.
- Keep camera/gallery utility logic in `shared/utils/image_utils.dart`.

### Flashcards / Learn

Current:

- `flashcardProvider` loads decks from backend.
- Supports optimistic add/update/delete for decks and cards.
- `flashcards_screen.dart` reads provider state for counts/recent cards.

Known risk:

- Some deeper flashcard screens can still have fallback/sample vocabulary. Inspect before assuming backend data is complete.

### Gamification

Current:

- `userStatsProvider` fetches stats from backend.
- `recordStudy()` can update streak/stats.
- `addCoinsOptimistic()` updates coins/points after Snap.
- Home/profile consume stats through provider shims.

### Home / Coach

Current:

- `simple_home_screen.dart` is the Coach/Home dashboard.
- Uses `userStatsValueProvider`.
- Uses shared bottom nav.

### Profile

Current:

- `profile_screen.dart` contains profile UI, tabs, stats, language settings, premium modal, and logout.
- `profile_provider.dart` owns profile data/fallback behavior.
- Uses shared bottom nav.

### Leaderboard / Progress

Current:

- Placeholder only.
- Uses shared bottom nav.

## Structure and Coding Conventions

Use the current structure:

- Feature screens: `lib/features/<feature>/screens/`
- Feature providers: `lib/features/<feature>/providers/`
- Feature models: `lib/features/<feature>/models/`
- Feature-only widgets: `lib/features/<feature>/widgets/`
- App-wide widgets: `lib/shared/widgets/`
- App-wide utilities: `lib/shared/utils/`
- App-wide constants/theme/routing/network: `lib/core/`

Naming:

- Files: `snake_case.dart`
- Classes/widgets: `PascalCase`
- Methods/variables: `camelCase`
- Private members: `_leadingUnderscore`

Implementation preferences:

- Match the existing design language and `AppTheme` colors.
- Prefer small feature widgets over giant reusable abstractions.
- Keep API DTO conversion near the provider/service that needs it.
- Use `const` constructors when straightforward.
- Use `context.go` for bottom tab navigation.
- Avoid deleting legacy files unless the user asks or the deletion is clearly safe.
- If a file has unrelated dirty changes, work around them and do not revert them.

## Markdown File Audit

Root documentation currently overlaps. Treat these as current:

- `ARCHITECTURE.md` - current project structure and architecture.
- `AGENT_CONTEXT.md` - current agent handoff and coding conventions.
- `MODULE_ANALYSIS.md` - useful module/status notes, but some sections can become stale and should be verified against code.

Likely stale or overlapping:

- `README.md` - still useful as public overview, but setup/next steps mention older direct Gemini/API-key flow and placeholder implementation.
- `QUICKSTART.md` - old boilerplate setup guide; many "next steps" are already done or no longer match the current code.
- `PROJECT_SUMMARY.md` - old setup-complete snapshot; overlaps heavily with README/QUICKSTART and is not current.
- `DEVELOPMENT_CHECKLIST.md` - old phase checklist; still useful as historical roadmap, but much of the current status is inaccurate.
- `SNAP_AND_LEARN_GUIDE.md` - old Snap implementation guide; describes `controllers/snap_controller.dart` and direct Gemini flow that do not match current `providers/snap_provider.dart` backend flow.
- `DEBUG_GUIDE.md` - old debugging note for image picker/SnapController; references files and patterns that have changed.
- `IMAGE_PICKER_FIX.md` - narrow historical fix note; keep only if the team wants old troubleshooting notes.
- `CONCLUSION.md` - gamification/backend summary; useful historical note, but the "remaining work" section is partly outdated because user stats are now wired into home/profile.

Recommended cleanup:

- Keep `README.md`, `ARCHITECTURE.md`, `AGENT_CONTEXT.md`, and `MODULE_ANALYSIS.md`.
- Move old snapshot/debug docs into a `docs/archive/` folder or delete them after confirming they are no longer needed.
- If keeping old docs, add a "stale snapshot" banner at the top so future agents do not treat them as current.

## Known Verification Notes

Recent analyzer context:

- `flutter analyze lib/shared/widgets/app_bottom_nav_bar.dart` passes.
- Full `flutter analyze` has existing project issues, including `test/widget_test.dart` referencing `MyApp` instead of current `MiLingoApp`.
- There are many existing lint/info warnings such as deprecated `withOpacity`, `prefer_const_constructors`, and ordering rules.

Do not claim the whole project is analyzer-clean until the existing issues are fixed.
