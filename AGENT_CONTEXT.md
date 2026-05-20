# MiLingo Agent Context

Read this file before making code changes. Update it whenever project structure, navigation, backend contracts, state models, or coding conventions change.

Last updated: 2026-05-17

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
|   |   |-- screens/vocab_detail_screen.dart
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

### Snap & Learn Detect-Confirm-Analyze Flow

Snap & Learn now separates YOLO detection from AI vocabulary analysis.

Backend changes in `C:\FPTU\SP26\EXE\milingo_be\Milingo.Backend`:

- `POST /api/v1/snap/detect`
  - Calls the YOLO segmentation service only.
  - Returns detected objects with `label`, `confidence`, `bounding_box`,
    optional `segmentation`, and `cropped_image_base64`.
- `POST /api/v1/snap/analyze-detected`
  - Accepts the user-approved detected object crops.
  - Calls Gemini without re-running YOLO.
  - Saves vocabularies, detection metadata, idempotency cache, and coins through
    the existing Firestore snap flow.

Frontend changes:

- `MilingoApiService` now has `detectSnap(...)` and
  `analyzeDetectedSnap(...)`.
- `SnapController.analyzeFile(...)` is now detect-only for camera/gallery/crop.
- `SnapController.confirmDetectionAndAnalyze()` runs the confirmed AI analysis.
- The review phase shows the captured image with blurred background and a sharp
  subject clipped by the YOLO segmentation path.
- The post-analysis phase shows a full-screen result view inspired by the second
  mockup. The "Xem câu ví dụ" action displays `example_sentence` from the
  returned JSON.

### Snap & Learn Review Confirmation Flow

After backend YOLO/Gemini analysis succeeds, Snap & Learn now pauses on a
full-screen object review step instead of immediately opening vocabulary
bubbles/cards.

Frontend changes:

- `lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`
  - Removed the automatic `showVocab()` call when `result` first arrives.
  - Shows the captured image with YOLO segmentation/bounding-box overlay and a
    bottom review bar inspired by the provided mockup:
    - X resets the Snap flow so the user can retake.
    - Check calls `showVocab()` and continues to the vocabulary result view.
    - Crop opens `image_cropper`, then re-analyzes the cropped image through the
      existing backend `analyzeFile(...)` flow.
  - Review bar styling was adjusted to match the MiLingo warm orange theme:
    - Outer panel uses a warm cream surface with a subtle primary-color top
      border and shadow.
    - Main check button uses `AppTheme.primaryColor`.
    - X and crop buttons use light surfaces with muted/primary icon colors.
    - The earlier peach/orange inner pill background around the buttons was
      removed per design feedback.
- `lib/features/snap_and_learn/providers/snap_provider.dart`
  - `analyzeFile(...)` starts from a fresh loading state for the new image so
    crop/re-analysis does not briefly keep the old mask/result.
  - Background cropped-image upload now updates state only if that analysis is
    still current.
- `android/app/src/main/AndroidManifest.xml`
  - Added `com.yalantis.ucrop.UCropActivity`, required by `image_cropper` on
    Android.

Verification:

- `dart format` ran on the modified Snap files.
- `flutter analyze lib/features/snap_and_learn/screens/snap_and_learn_screen.dart lib/features/snap_and_learn/providers/snap_provider.dart`
  still reports existing warnings/infos in `snap_and_learn_screen.dart`
  (`_kBg`, `_lang`, deprecated `withOpacity`, and `prefer_const_constructors`),
  but no new errors.
- `flutter build apk --debug --no-pub` passed and produced
  `build/app/outputs/flutter-apk/app-debug.apk`.

### Snap & Learn YOLO Segmentation Upgrade

Snap & Learn now supports YOLOv8 segmentation outlines in addition to the
existing bounding-box fallback.

YOLO service changes in `C:\FPTU\SP26\EXE\milingo_be\milingo_yolo_service`:

- `app/detector.py`
  - Uses `yolov8n-seg.pt` instead of `yolov8n.pt`.
  - Reads YOLO mask contours from `result.masks.xy`.
  - Returns compact `segmentation.points` in original-image pixels, capped at
    90 contour points per object.
  - Keeps `boundingBox` and `croppedImageBase64` so existing crop/Gemini flow
    still works.
- `app/main.py`
  - `/detect` response objects now include nullable:

```json
"segmentation": {
  "points": [{ "x": 123, "y": 456 }]
}
```

- `Dockerfile`
  - Pre-downloads `yolov8n-seg.pt`.

Backend contract changes in `C:\FPTU\SP26\EXE\milingo_be\Milingo.Backend`:

- `Models/Yolo/DetectedObject.cs`
  - Added `YoloSegmentation` / `YoloSegmentationPoint`.
- `Models/SnapAnalysisResponse.cs`
  - `SnapVocabItem` now serializes nullable `segmentation`.
  - Added `SnapSegmentation` / `SnapSegmentationPoint`.
- `Controller/SnapController.cs`
  - Copies YOLO segmentation points into each returned `SnapVocabItem`.
- `Services/FirestoreService.cs`
  - Includes segmentation in stored detection details and cached snap response.

Frontend changes:

- `lib/core/network/milingo_models.dart`
  - Added `SnapSegmentation` / `SnapSegmentationPoint`.
  - `SnapVocabItem` parses `segmentation`.
- `lib/features/snap_and_learn/models/milingo_result.dart`
  - Added `ObjectSegmentation` / `ObjectSegmentationPoint`.
  - `MilingoResult` carries optional `segmentation`.
- `lib/features/snap_and_learn/providers/snap_provider.dart`
  - Maps backend segmentation into UI models.
- `lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`
  - `_DetectedObjectPainter` draws the segmentation path with orange glow/fill.
  - If segmentation is unavailable, it falls back to the old bounding-box
    rectangle.

Verification run:

- `python -m py_compile app\detector.py app\main.py` in the YOLO service passed.
- `dotnet build -o C:\tmp\milingo-backend-build-check /p:UseAppHost=false` in
  `Milingo.Backend` passed.
- `dart format` ran on the modified Flutter files.
- `flutter analyze --no-fatal-infos --no-fatal-warnings ...` on the modified
  Flutter files completed, but still reports existing Snap screen warnings/info
  such as unused `_kBg`, unused `_lang`, deprecated `withOpacity`, and
  `prefer_const_constructors`.

### Snap & Learn YOLO Detection Fixes

Recent issue investigated: Snap & Learn sometimes recognized the vocabulary word correctly but did not draw a border around the object, or selected a large background object such as `sofa` instead of the intended foreground object such as `cup`.

Root causes found:

- The YOLO service already returned `boundingBox`, but the ASP.NET backend did not expose it in `/api/v1/snap/analyze`.
- Flutter parsed only `cropped_image_base64`, `detection_label`, and `detection_confidence`, so it had no original-image bbox to draw.
- The YOLO service sorted detections by raw area, which favored large background objects.
- YOLOv8n COCO can miss stylized/toy/paper objects, e.g. a paper cat model. Gemini can still label the full image, but without YOLO bbox Flutter cannot draw the object border.

Frontend changes:

- `lib/core/network/milingo_models.dart`
  - Added `SnapBoundingBox`.
  - `SnapVocabItem` now parses `bounding_box` or `boundingBox`.
- `lib/features/snap_and_learn/models/milingo_result.dart`
  - Added `ObjectBoundingBox`.
  - `MilingoResult` carries optional `boundingBox`.
- `lib/features/snap_and_learn/providers/snap_provider.dart`
  - Maps backend `SnapBoundingBox` into UI `ObjectBoundingBox`.
- `lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`
  - Adds `_DetectedObjectOverlay` and `_DetectedObjectPainter`.
  - Draws bbox on the captured full-screen image.
  - Bbox scaling accounts for the same `BoxFit.cover` used by `Image.file`, so original-image coordinates map correctly to screen coordinates.

Backend contract changes in `C:\FPTU\SP26\EXE\milingo_be\Milingo.Backend`:

- `Models/SnapAnalysisResponse.cs`
  - Added `SnapBoundingBox`.
  - `SnapVocabItem` now serializes nullable `bounding_box`.
- `Controller/SnapController.cs`
  - Copies YOLO `DetectedObject.BoundingBox` into each returned `SnapVocabItem`.
- `Services/YoloService.cs`
  - Calls YOLO with `confidence_threshold=0.35` instead of `0.5`.

YOLO service changes in `C:\FPTU\SP26\EXE\milingo_be\milingo_yolo_service`:

- `app/main.py`
  - Default `confidence_threshold` is now `0.35`.
  - Applies `ImageOps.exif_transpose(image)` before inference so phone images respect EXIF orientation.
- `app/detector.py`
  - Uses `imgsz=960`, `iou=0.45`, and a larger `max_det` candidate pool.
  - Adds padded crops with `CROP_PADDING_RATIO = 0.08` so object cards are not clipped tightly.
  - Replaces raw-area sorting with `rank_score`, combining confidence, center proximity, reasonable object size, and penalty for frame-filling background objects.
  - Adds foreground fallback when YOLO returns no usable boxes. This estimates a central foreground bbox using edge/contrast saliency and returns label `object`; backend still sends the crop to Gemini for final vocabulary naming.

Important runtime note:

- Restart both the ASP.NET backend and `milingo_yolo_service` after these changes. If old processes are still running, Flutter may show the correct Gemini word but no bbox/crop border.
- During verification, `dotnet build` failed while the backend was running because `Milingo.Backend.exe/.dll` were locked by process `Milingo.Backend`. Building to a temp output worked:

```powershell
dotnet build -o C:\tmp\milingo-backend-build-check /p:UseAppHost=false
```

Verification already run:

- `python -m py_compile app\detector.py app\main.py` in the YOLO service passed.
- `dotnet build -o C:\tmp\milingo-backend-build-check /p:UseAppHost=false` in `Milingo.Backend` passed.
- Full `flutter analyze` still fails for existing project issues, especially `test/widget_test.dart` referencing `MyApp`; do not treat the project as analyzer-clean yet.

### Bottom Navigation Refactor

The app now uses a shared bottom navigation bar:

- New file: `lib/shared/widgets/app_bottom_nav_bar.dart`
- Home uses `AppBottomNavBar(currentIndex: 0)`.
- Flashcards/Vocabulary uses `currentIndex: 1`.
- Snap & Learn is a full-screen camera route and does not show the shared bottom nav.
- Leaderboard/Progress uses `currentIndex: 3`.
- Profile uses `currentIndex: 4`.

The centered Snap tab in the shared nav is used to enter Snap from other tabs, but the Snap screen itself hides the nav for an immersive camera view. New users and returning logged-in users should still land on Snap & Learn first.

The previous top-right dropdown plus button was removed from active tab screens. `floating_nav_button.dart` is now legacy/unused unless a future design intentionally brings it back.

### Documentation Refresh

`ARCHITECTURE.md` was rewritten to match the current code structure. This file was also rewritten to be the quick-start context for future agents.

### Flashcards Screen Layout Refresh

`lib/features/flashcards/screens/flashcards_screen.dart` was redesigned to match the requested flashcard/category layout while keeping the existing warm orange MiLingo color scheme:

- The screen no longer has a hamburger icon, top-right language selector, "Categories" title, "Pick a set to practice" subtitle, or orange pinned header panel.
- The large words-learned progress ring remains near the top of the screen.
- The "My favorites" and "New set" action cards remain below the ring.
- The ring, action cards, and deck progress rows now live in a single normal scroll view, so the top summary area is not pinned separately from the deck list.
- Deck rows still navigate to `AppConstants.deckRoute` with `DeckArg`.
- The "New set" card opens a small bottom sheet and creates decks through `flashcardProvider.addDeck(...)`.

## Navigation Rules

Routes live in `AppConstants` and are wired in `app_router.dart`.

Main tab route mapping:

```text
0 Home     -> AppConstants.homeRoute           -> /home
1 Vocabulary -> AppConstants.flashcardsRoute   -> /flashcards
2 Snap     -> AppConstants.snapAndLearnRoute   -> /snap-and-learn (full-screen, no bottom nav)
3 Progress -> AppConstants.leaderboardRoute    -> /leaderboard
4 Profile  -> AppConstants.profileRoute        -> /profile

Flashcard drill-down routes:

```text
Deck detail       -> AppConstants.deckRoute        -> /flashcards/deck
Vocabulary detail -> AppConstants.vocabDetailRoute -> /flashcards/vocabulary
```
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
- Full-screen camera UI; no bottom nav while on Snap.
- The top-left arrow resets the Snap state and routes users back to Home (`/home`).

Follow:

- Keep capture UI in `snap_and_learn_screen.dart` and small reusable pieces under `snap_and_learn/widgets/`.
- Keep analysis state in `snap_provider.dart`.
- Keep camera/gallery utility logic in `shared/utils/image_utils.dart`.

### Flashcards / Vocabulary

Current:

- `flashcardProvider` loads decks from backend.
- Supports optimistic add/update/delete for decks and cards.
- `flashcards_screen.dart` is a library-style landing page with horizontal top tabs: "Tất cả bộ", "Tất cả từ vựng", "Từ vựng yêu thích", "Từ đã học", and "Từ chưa học".
- The default "Tất cả bộ" tab is backed by the deck API and shows horizontal deck rows without category photos.
- Deck rows navigate to `DeckScreen`, which loads cards for the selected deck and shows horizontal vocabulary rows.
- Vocabulary rows navigate to `VocabDetailScreen`, which displays the saved vocabulary detail.
- `DeckData` keeps backend `vocabCount` so deck rows can show counts before cards are loaded.

Known risk:

- Some deeper flashcard screens can still have fallback/sample vocabulary. Inspect before assuming backend data is complete.

### Gamification

Current:

- `userStatsProvider` fetches stats from backend.
- `recordStudy()` can update streak/stats.
- `addCoinsOptimistic()` updates coins/points after Snap.
- Home/profile consume stats through provider shims.

### Home

Current:

- `simple_home_screen.dart` is the Home dashboard.
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
- `flutter analyze lib/features/flashcards/screens/flashcards_screen.dart` passes after the layout refresh.
- Full `flutter analyze` has existing project issues, including `test/widget_test.dart` referencing `MyApp` instead of current `MiLingoApp`.
- There are many existing lint/info warnings such as deprecated `withOpacity`, `prefer_const_constructors`, and ordering rules.

Do not claim the whole project is analyzer-clean until the existing issues are fixed.

## Code Review Findings To Address

These findings came from a project-wide structure and lifecycle review. They are not all fixed yet. Use this section as a cleanup backlog when optimizing the app.

### Object Lifecycle

#### `SnapAndLearnScreen` / `_SnapAndLearnScreenState._initCamera`

Problem: `_initCamera()` awaits `availableCameras()` before checking `mounted`. If the screen is disposed while camera discovery or initialization is pending, a `CameraController` can be created after `dispose()` has already run.

Suggested pattern:

```dart
Future<void> _initCamera() async {
  CameraController? controller;

  try {
    final cameras = await availableCameras();
    if (!mounted) return;

    if (cameras.isEmpty) {
      setState(() {
        _isCameraError = true;
        _cameraErrorMsg = 'Không tìm thấy camera trên thiết bị.';
      });
      return;
    }

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() {
      _cameraController = controller;
      _isCameraInitialized = true;
    });
  } catch (e) {
    await controller?.dispose();
    if (!mounted) return;
    setState(() {
      _isCameraError = true;
      _cameraErrorMsg = 'Lỗi khởi tạo camera: $e';
    });
  }
}
```

Lifecycle check result: obvious owned controllers are mostly disposed correctly. Login/register text controllers, deck search controller, save sheet text controller, profile tab controller, splash animation controllers, and snap animation/camera controllers all have `dispose()` paths. The main concern is async initialization continuing after disposal.

### Widget Rebuild Efficiency

#### `SnapAndLearnScreen` / `_SnapAndLearnScreenState.build`

Problem: `ref.listen` currently lives inside `build()` and drives animation controllers plus a post-frame provider mutation. Move it to `initState()` with `ref.listenManual`.

Suggested pattern:

```dart
ProviderSubscription<SnapState>? _snapSub;

@override
void initState() {
  super.initState();

  _bubbleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  _scanCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  _snapSub = ref.listenManual<SnapState>(snapControllerProvider, (prev, next) {
    if (next.isLoading && !(prev?.isLoading ?? false)) {
      _scanCtrl.repeat();
    }

    if (prev?.result == null && next.result != null) {
      _scanCtrl.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(snapControllerProvider.notifier).showVocab();
        }
      });
    }

    if (!(prev?.showVocabulary ?? false) && next.showVocabulary) {
      _bubbleCtrl.forward(from: 0);
    }
  });

  _initTts();
  _initCamera();
}

@override
void dispose() {
  _snapSub?.close();
  _tts.stop();
  _cameraController?.dispose();
  _bubbleCtrl.dispose();
  _scanCtrl.dispose();
  super.dispose();
}
```

#### `DeckScreen` / `_DeckScreenState._filtered`

Problem: `_filtered` calls `ref.read(flashcardProvider)` and rebuilds converted/filter lists from scratch from a getter. Since `build()` already watches the provider, pass the state into a pure method.

Suggested pattern:

```dart
List<VocabItem> _filteredFromState(FlashcardState state) {
  final deck = state.decks.where((d) => d.id == widget.deck.id).firstOrNull;
  final entries = deck?.cards ?? const <FlashcardEntry>[];
  final query = _query.trim().toLowerCase();

  final all = [
    for (final entry in entries.indexed)
      _entryToVocabItem(entry.$2, isNew: entry.$1 < 3),
  ];

  final byFilter = switch (_filterIndex) {
    1 => all.length > 3 ? all.sublist(all.length - 3) : all,
    2 => all.where((v) => !v.isNew).toList(),
    _ => all,
  };

  if (query.isEmpty) return byFilter;

  return byFilter.where((v) {
    return v.word.toLowerCase().contains(query) ||
        v.reading.toLowerCase().contains(query);
  }).toList();
}
```

Then call it from the provider `data` branch and pass the result into `_buildVocabList(items)`.

#### `AllCategoriesScreen` / `_filtered`

Problem: `_filtered` creates a new list every time it is accessed. `GridView.builder` uses it for `itemCount` and again in `itemBuilder`, causing repeated filtering.

Suggested pattern:

```dart
@override
Widget build(BuildContext context) {
  final query = _query.trim().toLowerCase();
  final filtered = query.isEmpty
      ? _kCategories
      : _kCategories
          .where((c) => c.nameVi.toLowerCase().contains(query))
          .toList();

  return GridView.builder(
    itemCount: filtered.length,
    itemBuilder: (context, i) => _CategoryCard(category: filtered[i]),
  );
}
```

### Redundant Or Unused Code

#### `ExamScreen` / `_ExamScreenState`

Problem: `_optionCtrl` is initialized, forwarded, reset, and disposed, but no widget consumes it. Remove it unless a real option animation is added.

Suggested cleanup:

```dart
class _ExamScreenState extends State<ExamScreen> {
  late List<_Question> _questions;
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions(widget.langCode);
    _tts = FlutterTts();
    unawaited(_tts.setSpeechRate(0.45));
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
```

If using `unawaited`, import:

```dart
import 'dart:async';
```

#### `SaveFlashcardSheet`

Problem: `flashcard_models.dart` is imported directly, but `flashcard_provider.dart` already exports the models. Analyzer flags this as unnecessary.

Suggested cleanup:

```dart
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
// Remove:
// import 'package:milingo/features/flashcards/models/flashcard_models.dart';
```

#### `floating_nav_button.dart`

Problem: legacy top-right dropdown nav is now unused after the bottom navigation refactor.

Suggested options:

- Delete it if confirmed no future design needs it.
- Or mark it deprecated:

```dart
@Deprecated('Legacy top-right dropdown nav. Use AppBottomNavBar instead.')
class FloatingNavButton extends StatefulWidget {
  const FloatingNavButton({super.key});
}
```

#### `test/widget_test.dart`

Problem: analyzer fails because the test pumps `MyApp`, but current root widget is `MiLingoApp`.

Suggested correction:

```dart
await tester.pumpWidget(
  const ProviderScope(
    child: MiLingoApp(),
  ),
);
```

### Async Handling

#### `FlashcardNotifier` mutation methods

Problem: several mutations use `state.value!`. If the provider is loading or has errored, these can crash. Affected methods include `addDeck`, `updateDeck`, `deleteDeck`, `addCardToDeck`, and `deleteCard`.

Suggested pattern:

```dart
FlashcardState? get _currentState => state.valueOrNull;

Future<void> addDeck(String name, String emoji, {String? description}) async {
  final current = _currentState;
  if (current == null) return;

  final previousState = state;
  final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

  state = AsyncData(
    current.copyWith(
      decks: [
        ...current.decks,
        DeckData(id: tempId, name: name, emoji: emoji),
      ],
    ),
  );

  try {
    final created = await _api.createDeck(
      name: name,
      emoji: emoji,
      description: description,
    );

    final next = state.valueOrNull;
    if (next == null) return;

    state = AsyncData(
      next.copyWith(
        decks: next.decks
            .map((d) => d.id == tempId ? _deckResponseToDeckData(created) : d)
            .toList(),
      ),
    );
  } catch (_) {
    state = previousState;
    rethrow;
  }
}
```

#### `SaveFlashcardSheet` delayed close callbacks

Problem: `Future.delayed` callbacks are used to pop the sheet. They check `mounted`, which is good, but there is no cancelable handle. This is acceptable for a short-lived sheet, but if this grows more complex, replace with a `Timer` stored on state and cancel in `dispose()`.

Suggested pattern:

```dart
Timer? _closeTimer;

void _scheduleClose() {
  _closeTimer?.cancel();
  _closeTimer = Timer(const Duration(milliseconds: 1400), () {
    if (mounted) Navigator.of(context).pop();
  });
}

@override
void dispose() {
  _closeTimer?.cancel();
  _nameCtrl.dispose();
  super.dispose();
}
```

### Build Method Hygiene

#### `FlashcardsScreen.build`

Problem: `totalCards` is recalculated on every rebuild. For current data sizes this is fine, but if decks/cards grow, move aggregation into provider/selectors or a derived provider.

Suggested derived provider idea:

```dart
final flashcardSummaryProvider = Provider<FlashcardSummary>((ref) {
  final state = ref.watch(flashcardStateProvider);
  final totalCards = state.decks.fold<int>(0, (sum, d) => sum + d.cards.length);
  return FlashcardSummary(totalCards: totalCards, totalDecks: state.decks.length);
});
```

Then the screen watches only the summary:

```dart
final summary = ref.watch(flashcardSummaryProvider);
```

### Memory And Resource Management

#### `AllCategoriesScreen` / `_CategoryCard.build`

Problem: `Image.network` does not specify `cacheWidth`/`cacheHeight`. Grid thumbnails may decode larger images than needed on high-density screens.

Suggested pattern:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.network(
      category.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: (constraints.maxWidth * dpr).round(),
      cacheHeight: (constraints.maxHeight * dpr).round(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFD8D8D8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  },
)
```

#### `SnapAndLearnScreen.build`

Problem: captured camera image uses full-screen `Image.file` without decode sizing. Camera images can be large.

Suggested pattern:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Image.file(
      File(snap.capturedImage!.path),
      fit: BoxFit.cover,
      cacheWidth: (constraints.maxWidth * dpr).round(),
      cacheHeight: (constraints.maxHeight * dpr).round(),
    );
  },
)
```

### Logging Cleanup

#### `ImageUtils` and `dio_client.dart`

Problem: shared/network utilities use many production `print()` calls. Replace with debug-only logging.

Suggested helper:

```dart
import 'package:flutter/foundation.dart';

void logDebug(String message) {
  if (kDebugMode) debugPrint(message);
}
```

Usage:

```dart
logDebug('[ImageUtils] Starting pickImageAsXFile...');
```
