# Scan History Design

## Goal

Make the existing **Lịch sử quét** button on the Ôn tập vocabulary dashboard open the current user's recent snapped words. The screen initially loads five words, loads five more as the user reaches the bottom, and opens a read-only word detail screen when an item is tapped.

## Scope

- Show individual snapped vocabulary words newest first.
- Load five items per request with stable cursor pagination.
- Group loaded items using the device's local timezone: **Hôm nay**, **Hôm qua**, then `dd/MM/yyyy`.
- Use a generic orange-tinted vocabulary icon instead of stored scan thumbnails so existing records render consistently.
- Show keyword, translation, and pronunciation on each history card when those values exist.
- Open a dedicated read-only detail screen with keyword, translation, pronunciation, example sentence, related words, and scan time.
- Match the approved Figma color direction without copying its search or filter controls.

The first version does not include search, date filters, language filters, image persistence, editing, deletion, favorites, or adding a history item directly to a deck.

## Visual Design

Use the approved Figma node `1300:574` only as a color and surface reference:

- Page background: `#FBF7F2`
- Primary orange: `#FF6A00`
- Accent gradient: `#FF8A1F` to `#FF4D1A`
- Primary ink: `#1D1814`
- Muted ink: `rgba(29, 24, 20, 0.55)`
- Cards: translucent white with a white border, rounded corners, and a soft warm shadow

The history screen has a circular back button, centered **Lịch sử quét** title, subtitle, **Dòng thời gian** heading, date groups, an orange timeline rail, and word cards. It omits the Figma search button and all filter chips. A small orange-tinted container with Flutter's `Icons.auto_awesome_rounded` replaces image thumbnails.

The detail screen reuses the same palette and typography but remains independent of the deck vocabulary detail screen. This prevents scan history from exposing deck-only favorite or deletion actions.

## Backend Contract

Add an authenticated endpoint:

```text
GET /api/v1/snap/history?limit=5&cursor=<opaque-cursor>
```

The Firebase UID is read only from verified claims. The service queries `users/{uid}/vocabularies`, ordered by `created_at` descending and document ID descending. The document ID is a deterministic tie-breaker for words written with the same server timestamp.

`limit` defaults to 5 and is clamped to the inclusive range 1–20. The query requests `limit + 1` documents to determine whether another page exists. The cursor is an opaque, unpadded Base64 URL-safe encoding of JSON shaped as `{"createdAt":"<UTC ISO-8601>","documentId":"<id>"}` for the final visible item. Invalid cursors return HTTP 400 rather than restarting from the first page.

The endpoint uses the existing `ApiResponse<T>` wrapper. Its data payload is:

```json
{
  "items": [
    {
      "id": "firestore-document-id",
      "snap_group_id": "optional-idempotency-key",
      "keyword": "dog",
      "translation": "con chó",
      "pronunciation": "/dɔːɡ/",
      "example_sentence": "The dog is friendly.",
      "related_words": [],
      "created_at": "2026-07-17T03:30:00Z"
    }
  ],
  "next_cursor": "opaque-value-or-null",
  "has_more": true
}
```

No existing snap analysis, quota, coin, streak, vocabulary-save, or idempotency behavior changes.

## Flutter Architecture

Add scan-history response models to the network model layer and a `MilingoApiService.getSnapHistory` method. A small scan-history data-source abstraction keeps pagination state testable without coupling tests to Dio.

An `AsyncNotifierProvider.autoDispose` owns `ScanHistoryState`:

- accumulated immutable items
- next cursor
- `hasMore`
- `isLoadingMore`
- an optional load-more error

The provider watches `authStateProvider`. Logout or account changes dispose/rebuild the state, preventing one user's history from appearing for another user. Initial loading is represented by the provider's outer `AsyncValue`; loading another page preserves existing items. `loadMore()` returns early when a request is already running or `hasMore` is false.

The history screen owns only its `ScrollController`. When the remaining scroll extent reaches approximately 200 logical pixels, it requests the next page. Provider guards prevent duplicate network calls. A failed later page keeps existing cards visible and shows an inline retry action.

## Navigation and Data Flow

Add these routes:

```text
/flashcards/scan-history
/flashcards/scan-history/detail
```

`VocabularyHeroCard` receives an `onScanHistoryTap` callback. The Ôn tập screen passes a `context.push(...)` action, keeping the dashboard widget reusable and free of routing knowledge.

The list passes the selected immutable history item to the detail route through a typed argument. No second request is required because the page response already contains all detail fields.

## UI States

- Initial loading: centered progress indicator on the history surface.
- Empty: friendly icon and message that no scanned words exist yet.
- Initial error: error message with a retry button.
- Loading more: compact spinner below existing cards.
- Load-more error: inline retry row below existing cards.
- End reached: subtle end-of-history message with no further requests.
- Missing optional fields: hide empty pronunciation, example, and related-word sections rather than showing placeholders.

## Focused Verification

Use test-first coverage for the new behavior only:

- Backend cursor round-trip, invalid cursor rejection, stable timestamp/document-ID ordering contract, and five-item page boundary.
- Flutter JSON model parsing and page-state merging.
- Provider duplicate-load and end-of-list guards using a fake data source.
- Route/button wiring and core history screen states.

Run only relevant backend tests, targeted Flutter tests, formatting, and Flutter analysis. Do not run unrelated integration or device test suites.

## Compatibility and Safety

- Preserve the user's existing uncommitted `pubspec.yaml` change.
- Add no new packages.
- Keep `snapControllerProvider` and `flashcardProvider` unchanged.
- Do not store Base64 images in history responses or Firestore.
- Do not alter existing Firestore documents; older vocabulary documents continue to render from their current fields.
