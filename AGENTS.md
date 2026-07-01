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
|   |-- ai_tutor/
|   |   |-- models/chat_message_model.dart
|   |   |-- providers/chat_provider.dart
|   |   |-- screens/ai_tutor_screen.dart
|   |   `-- widgets/
|   |       |-- chat_bubble.dart
|   |       |-- chat_input_bar.dart
|   |       `-- suggestion_chips.dart
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
|   |-- leaderboard/
|   |   |-- providers/leaderboard_provider.dart
|   |   |-- screens/exam_screen.dart
|   |   `-- screens/leaderboard_screen.dart
|   |-- premium/
|   |   |-- providers/subscription_provider.dart
|   |   |-- screens/payment_method_screen.dart
|   |   |-- screens/payment_result_screen.dart
|   |   |-- screens/premium_limit_screen.dart
|   |   |-- screens/premium_screen.dart
|   |   |-- screens/subscription_management_screen.dart
|   |   |-- screens/transaction_history_screen.dart
|   |   `-- widgets/
|   |       |-- payment_method_view.dart
|   |       `-- premium_upgrade_view.dart
|   |-- profile/
|   |   |-- providers/profile_provider.dart
|   |   |-- screens/language_settings_screen.dart
|   |   |-- screens/profile_screen.dart
|   |   |-- screens/support_screen.dart
|   |   `-- widgets/
|   |       |-- language_settings_components.dart
|   |       |-- profile_premium_card.dart
|   |       |-- profile_settings_section.dart
|   |       |-- profile_stats_section.dart
|   |       |-- profile_view_data.dart
|   |       `-- support_screen_components.dart
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
- **UI & Asset Guidelines**: Ensure vector assets (like ranking SVGs in `assets/svg/ranking/`) intended to overlay other widgets (like user avatars in a `Stack`) use `fill="none"` inside their main circle paths. This ensures the background layer (e.g. user images, initials) is visible under the ring frame.

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
/premium/limit            -> Premium Daily Limit Screen
/profile                  -> Profile Settings
/profile/support          -> Help & FAQ Support Screen
/leaderboard              -> Progress Leaderboard
/payment/success          -> Checkout Success Screen
/payment/cancel           -> Checkout Cancel Screen
/subscription             -> Manage Subscription Screen
/payment-history          -> Payment History Screen
```

## State Management Rules

- Use Riverpod. Keep backend state mutations out of UI files.
- Prefer `AsyncNotifier` or `FutureProvider` for fetching/updating remote data (e.g., subscription details, decks, user stats).
- **Leaderboard Integration in Profile**: The leaderboard ranking on the profile screen (inside `ProfileStatsSection`'s `_RankCard`) dynamically watches `leaderboardNotifierProvider` to retrieve the current user's actual rank and points, calculating the progress towards the next level milestone using the points modulo 1000, consistent with the main leaderboard page.
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
- **Frontend Sync**: After a successful snap analysis or when exiting a study/review session, the frontend must refresh `userStatsProvider` (and `flashcardProvider` to clear reviewed cards from due counts) via their respective `.notifier.refresh()` methods to keep dashboard metrics in sync.
- **SRS Review Rescheduling**: Incorrect review answers (quality < 3 or wrong MCQ) schedule cards for immediate review on the backend (due date set to `DateTime.UtcNow`). This ensures they remain in the user's daily due queue until answered correctly.

## AI Tutor Integration Rules

- **Access Policy**: AI Tutor is a premium feature. Free tier users are capped at 20 free daily messages (calculated using Vietnam Local Time UTC+7 calendar boundaries). Premium users have unlimited messages.
- **Session-Only History**: Chat history is kept in memory only (`Option A`). The state provider (`chatProvider`) uses `.autoDispose` to ensure that when the user leaves the screen, the history is deleted completely, and resources are freed.
- **Backend Routing**: For security and API key protection, the mobile application does not invoke OpenAI directly. It must call the backend `Milingo` endpoints (`/api/v1/ai-tutor/chat` and `/api/v1/ai-tutor/quota`).
- **Quota Exceeded (HTTP 402)**: When the 20 daily free message limit is exceeded, the backend returns a `402 Payment Required` status code. The frontend handles this by disabling the text field and send button, displaying a message in the input bar, and showing a Premium Upgrade dialog directing the user to `/premium`.

## Security & Authentication

- **Đổi mật khẩu (Password Reset)**: The "Đổi mật khẩu" option in the account settings screen allows users to trigger a password reset email using Firebase Auth (`FirebaseAuth.instance.sendPasswordResetEmail`). It requires a confirmation dialog to verify the destination email and uses a visual loading overlay to indicate progression, ensuring no redundant/duplicate email triggers occur.
- **Đổi tên hiển thị (Change Username/Display Name)**: The "Tên hiển thị" field in the account settings screen displays an edit icon. Tapping it opens a dialog allowing the user to update their display name. It checks validation (not empty, max 50 characters), uses a visual loading indicator while calling `userProfileProvider.notifier.updateDisplayName`, and propagates updates both locally (using Riverpod) and to the Firebase Auth and backend endpoints (`PATCH /api/v1/users/me`).

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
