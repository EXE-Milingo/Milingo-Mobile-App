# MiLingo Mobile App Agent Guide

AI-Powered Language Learning App. Keep agent work focused and cheap.

## Priorities

1. Correctness.
2. Small, maintainable changes.
3. Concise communication and low token usage.

## Folder Structure (lib/)

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
|   |   |-- screens/forgot_password_screen.dart
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
|   |   |-- screens/vocab_detail_screen.dart
|   |   |-- widgets/deck_list_item.dart
|   |   |-- widgets/exam_banner.dart
|   |   |-- widgets/quick_card.dart
|   |   `-- widgets/vocab_card.dart
|   |-- gamification/providers/user_stats_provider.dart
|   |-- home/screens/simple_home_screen.dart
|   |-- leaderboard/screens/leaderboard_screen.dart
|   |-- premium/
|   |   |-- providers/subscription_provider.dart
|   |   |-- screens/payment_method_screen.dart
|   |   |-- screens/payment_result_screen.dart
|   |   |-- screens/subscription_management_screen.dart
|   |   |-- screens/transaction_history_screen.dart
|   |   `-- widgets/
|   |       |-- payment_method_view.dart
|   |       `-- premium_upgrade_view.dart
|   |-- profile/
|   |   |-- providers/profile_provider.dart
|   |   |-- screens/language_settings_screen.dart
|   |   |-- screens/profile_screen.dart
|   |   `-- widgets/
|   |       |-- language_settings_components.dart
|   |       |-- profile_premium_card.dart
|   |       |-- profile_settings_section.dart
|   |       |-- profile_stats_section.dart
|   |       `-- profile_view_data.dart
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

## Workflow & Guidelines

- Inspect relevant code and tests before editing. Do not guess schemas or architecture.
- Prefer targeted searches and bounded reads. Skip generated output (`build/`, `.dart_tool/`, `node_modules/`, `bin/`, `obj/`, `.next/`, `dist/`).
- Make the smallest runnable diff. Avoid unrelated refactors.
- Preserve existing patterns (Riverpod state management, GoRouter routing, Dio-based networking) unless a change is justified.
- Add or update tests when behavior changes.
- On Windows, use PowerShell syntax.

## Navigation & Routing Rules

Routes live in `AppConstants` and are wired in `app_router.dart`.
Use `context.go(...)` for main tab navigation, and `context.push(...)` for drill-down routes (e.g. deck/vocabulary detail).

```text
/                         -> Splash check (FirebaseAuth state)
/auth                     -> Login Screen
/register                 -> Register Screen
/choose-language          -> Language Selection
/home                     -> Home Dashboard
/snap-and-learn           -> Snap & Learn (Full-screen, no bottom nav)
/flashcards               -> Vocabulary Decks Overview
/flashcards/deck          -> Deck detail screen
/flashcards/vocabulary    -> Vocabulary detail screen
/profile                  -> Profile Settings
/leaderboard              -> Progress Leaderboard
/payment/success          -> Checkout Success Screen
/payment/cancel           -> Checkout Cancel Screen
/subscription             -> Manage Subscription Screen
/payment-history          -> Payment History Screen
```

## State Management Rules

- Use Riverpod. Keep backend state mutations out of UI files.
- Prefer `AsyncNotifier` or `FutureProvider` for fetching/updating remote data (e.g., subscription details, decks, user stats).
- Use code generation (`build_runner`) when modifying files that use `@riverpod` annotations:
  ```powershell
  dart run build_runner build --delete-conflicting-outputs
  ```
- **State lifecycle and cleanup**: Always prefer using `.autoDispose` providers for screen-specific states (such as camera capture, search queries, or temporary forms). This ensures state is discarded and resources are cleaned up immediately when the user navigates away from the screen, preventing stale data leaks, residual caches, or out-of-sync states across different sessions.
- **Authentication-Scoped State & Preferences**: User-specific state providers (like `userProfileProvider` and `userStatsProvider`) must watch the global `authStateProvider` in their `build()` method. This automatically clears/refetches data upon logout/login. Additionally, `SharedPreferences` keys must be scoped by user ID (e.g., `profile.${uid}.local_avatar_path`) to avoid leaking cached profile data and settings across accounts on the same device.
- **Dead Code & Screen Redundancy**: Keep the codebase clean by removing redundant or deprecated screens and views (e.g., deleted `LanguageGoalScreen` and `LanguageGoalView` to centralize all native/target language configuration inside `LanguageSettingsScreen`).
- **Responsive Scrollable Layouts**: To prevent UI overlaps, text clipping, and layout overflows on varying screen heights (such as in analysis result screens), wrap detailed results and information blocks inside a vertical `SingleChildScrollView` instead of using fixed-height parents or unconstrained flex widgets.

## Backend and API Rules

- Communicate with the backend only via `MilingoApiService`.
- Attach Firebase ID tokens via the API service interceptor.
- Never write secrets directly into code or configuration files.

## Payment & PayOS Integration Rules

- **Redirection Bridge**: PayOS return and cancel URLs must route through the backend redirect endpoint (`/api/v1/payments/payos/redirect?status=success`). This endpoint serves an HTML bridge containing a JavaScript redirect targeting the custom app scheme (`milingo://payment/payment/success?orderCode=...`) to reopen the mobile app on checkout completion.
- **Verification Fallback**: When the app handles the deep-linked `/payment/success` path, it must capture the `orderCode` parameter and explicitly request direct verification via `verifyPayOSOrder(orderCode)` in `PaymentResultScreen`.
- **Self-Healing Sync**: The backend auto-synchronizes pending transactions when querying the user's premium status. The mobile app can query active premium tier info dynamically using `subscriptionOverviewProvider` to render active details and expiration dates on screens like [profile_screen.dart](file:///C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App/lib/features/profile/screens/profile_screen.dart).
- **Local Webhook Testing**: PayOS webhooks require a public URL. For local webhook delivery testing, a tunneling tool (like `ngrok` or VS Dev Tunnels) must be used.

## Gamification & Daily Streak Rules

- **Streak Logic**: Daily streaks are calculated using Vietnam Local Time (UTC+7) calendar boundaries to align with the primary user base.
- **Expiry Check**: Streaks are dynamically checked for expiration (older than yesterday) on GET reads (`/api/v1/users/stats`) so the UI displays 0 if the user missed a day.
- **Triggers**: Daily streaks are updated/incremented when a user performs a learning activity:
  1. Studying a flashcard deck (`/api/v1/users/record-study`).
  2. Snapping and analyzing an object (`/api/v1/snap/analyze-detected`).
- **Frontend Sync**: After a successful snap analysis, the frontend must refresh the `userStatsProvider` state via `ref.read(userStatsProvider.notifier).refresh()` to fetch the updated daily streak and coins from the backend.

## Verification

After code changes, run the relevant verify skill — see `.claude/skills/` or use `/verify-flutter` from your terminal:
```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
Report blocked checks honestly if a required toolchain is missing.

## Safety

- Ask before package installs, upgrades, new MCP servers, network-heavy commands, or destructive Git/workspace actions.
- Never expose secrets in files, logs, or chat.
- Verify changing facts such as APIs, versions, schemas, and deprecations with Context7 or official docs. Cite the URL.
