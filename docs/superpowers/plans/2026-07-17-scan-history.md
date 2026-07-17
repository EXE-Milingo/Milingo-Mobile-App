# Scan History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Ôn tập screen's Lịch sử quét button open an authenticated, newest-first timeline that loads snapped words five at a time and opens read-only details.

**Architecture:** Add a cursor codec, paginated Firestore query, and authenticated snap-history endpoint in the backend. In Flutter, add response models and a small data-source boundary, then keep accumulated pagination state in an auth-scoped `AsyncNotifierProvider.autoDispose`; presentation lives in dedicated history/detail screens and focused reusable widgets.

**Tech Stack:** ASP.NET Core 8, Google.Cloud.Firestore 4.2.0, xUnit 3, Flutter/Dart, Riverpod, GoRouter, Dio.

## Global Constraints

- Page size defaults to 5 and backend input is clamped to 1–20.
- Use authenticated Firebase claims; never accept a user ID from query/body data.
- Preserve all existing snap analysis, quota, coins, streak, review, deck, and flashcard behavior.
- Add no packages and do not modify the user's existing uncommitted `pubspec.yaml` change.
- Do not persist or return Base64/image history data.
- No search, filters, editing, deletion, favorites, or save-to-deck actions in this version.
- Use Figma palette `#FBF7F2`, `#FF6A00`, `#FF8A1F`, `#FF4D1A`, and `#1D1814`.
- Verification stays focused: relevant backend tests, targeted Flutter tests, formatting, and Flutter analysis only.

## Repository Roots and File Structure

- Mobile root: `C:/FPTUniversity/MILINGO/PROJECT/APP/Milingo-Mobile-App`
- Backend root: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend`

Backend files:

- Create `Models/SnapHistoryModels.cs`: API item/page DTOs.
- Create `Services/SnapHistoryCursorCodec.cs`: opaque cursor encode/decode and limit normalization.
- Modify `Services/IFirestoreService.cs`: history query contract.
- Modify `Services/FirestoreService.cs`: per-user Firestore page query and document mapping.
- Modify `Controller/SnapController.cs`: authenticated GET endpoint and invalid-cursor response.
- Create `Milingo.Backend.Tests/SnapHistoryCursorCodecTests.cs`: pure cursor/limit tests.
- Create `Milingo.Backend.Tests/SnapHistorySourceTests.cs`: narrow source-contract test for user scoping and stable query order.

Mobile files:

- Modify `lib/core/network/milingo_models.dart`: history JSON models.
- Modify `lib/core/network/milingo_api_service.dart`: GET history method.
- Create `lib/features/flashcards/providers/scan_history_provider.dart`: auth-scoped auto-disposed pagination state.
- Create `lib/features/flashcards/widgets/scan_history_widgets.dart`: timeline/date grouping and cards.
- Create `lib/features/flashcards/screens/scan_history_screen.dart`: provider-aware infinite list shell.
- Create `lib/features/flashcards/screens/scan_history_detail_screen.dart`: read-only details.
- Modify `lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart`: callback-enabled history button.
- Modify `lib/features/flashcards/screens/flashcards_screen.dart`: push history route.
- Modify `lib/core/constants/app_constants.dart`: history routes.
- Modify `lib/core/routing/app_router.dart`: history/detail routes.
- Create `test/snap_history_models_test.dart`: JSON contract.
- Create `test/scan_history_provider_test.dart`: page merge and duplicate-load guard.
- Create `test/scan_history_widgets_test.dart`: local-date grouping and tap behavior.
- Create `test/scan_history_routing_source_test.dart`: callback/route wiring and read-only detail guard.

---

### Task 1: Backend Cursor and Response Contracts

**Files:**
- Create: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Models/SnapHistoryModels.cs`
- Create: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/SnapHistoryCursorCodec.cs`
- Test: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/SnapHistoryCursorCodecTests.cs`

**Interfaces:**
- Produces: `SnapHistoryItem`, `SnapHistoryPage`, `SnapHistoryCursor`, `SnapHistoryCursorCodec.Encode`, `SnapHistoryCursorCodec.TryDecode`, and `SnapHistoryCursorCodec.NormalizeLimit`.
- Consumes: only `System.Text.Json`; no Firestore dependency in the codec.

- [ ] **Step 1: Write failing cursor and limit tests**

```csharp
using Milingo.Backend.Services;
using Xunit;

namespace Milingo.Backend.Tests;

public class SnapHistoryCursorCodecTests
{
    [Fact]
    public void Cursor_round_trips_timestamp_and_document_id()
    {
        var value = new SnapHistoryCursor(
            new DateTime(2026, 7, 17, 3, 30, 0, DateTimeKind.Utc),
            "vocab-doc-2");

        var encoded = SnapHistoryCursorCodec.Encode(value);

        Assert.DoesNotContain("=", encoded);
        Assert.True(SnapHistoryCursorCodec.TryDecode(encoded, out var decoded));
        Assert.Equal(value, decoded);
    }

    [Theory]
    [InlineData("")]
    [InlineData("not-base64")]
    [InlineData("e30")]
    public void Invalid_cursor_is_rejected(string cursor)
    {
        Assert.False(SnapHistoryCursorCodec.TryDecode(cursor, out _));
    }

    [Theory]
    [InlineData(-1, 1)]
    [InlineData(0, 1)]
    [InlineData(5, 5)]
    [InlineData(21, 20)]
    public void Limit_is_clamped(int requested, int expected)
    {
        Assert.Equal(expected, SnapHistoryCursorCodec.NormalizeLimit(requested));
    }
}
```

- [ ] **Step 2: Run the cursor test and confirm RED**

Run from the backend root:

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter FullyQualifiedName~SnapHistoryCursorCodecTests
```

Expected: compile failure because `SnapHistoryCursor` and `SnapHistoryCursorCodec` do not exist.

- [ ] **Step 3: Add the minimal backend DTOs**

Create `Models/SnapHistoryModels.cs` with these public contracts:

```csharp
using System.Text.Json.Serialization;

namespace Milingo.Backend.Models;

public class SnapHistoryItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("snap_group_id")]
    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? SnapGroupId { get; set; }

    [JsonPropertyName("keyword")]
    public string Keyword { get; set; } = string.Empty;

    [JsonPropertyName("translation")]
    public string Translation { get; set; } = string.Empty;

    [JsonPropertyName("pronunciation")]
    public string Pronunciation { get; set; } = string.Empty;

    [JsonPropertyName("example_sentence")]
    public string ExampleSentence { get; set; } = string.Empty;

    [JsonPropertyName("related_words")]
    public List<RelatedWordResponse> RelatedWords { get; set; } = new();

    [JsonPropertyName("created_at")]
    public string CreatedAt { get; set; } = string.Empty;
}

public class SnapHistoryPage
{
    [JsonPropertyName("items")]
    public List<SnapHistoryItem> Items { get; set; } = new();

    [JsonPropertyName("next_cursor")]
    public string? NextCursor { get; set; }

    [JsonPropertyName("has_more")]
    public bool HasMore { get; set; }
}
```

- [ ] **Step 4: Implement the pure cursor codec**

Create `Services/SnapHistoryCursorCodec.cs`:

```csharp
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Milingo.Backend.Services;

public sealed record SnapHistoryCursor(DateTime CreatedAt, string DocumentId);

public static class SnapHistoryCursorCodec
{
    private sealed record Payload(
        [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
        [property: JsonPropertyName("documentId")] string DocumentId);

    public static int NormalizeLimit(int requested) => Math.Clamp(requested, 1, 20);

    public static string Encode(SnapHistoryCursor cursor)
    {
        var json = JsonSerializer.Serialize(new Payload(
            cursor.CreatedAt.ToUniversalTime(),
            cursor.DocumentId));
        return Convert.ToBase64String(Encoding.UTF8.GetBytes(json))
            .TrimEnd('=')
            .Replace('+', '-')
            .Replace('/', '_');
    }

    public static bool TryDecode(string? value, out SnapHistoryCursor cursor)
    {
        cursor = new SnapHistoryCursor(default, string.Empty);
        if (string.IsNullOrWhiteSpace(value)) return false;

        try
        {
            var base64 = value.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + ((4 - base64.Length % 4) % 4), '=');
            var payload = JsonSerializer.Deserialize<Payload>(
                Encoding.UTF8.GetString(Convert.FromBase64String(base64)));
            if (payload is null ||
                payload.CreatedAt == default ||
                string.IsNullOrWhiteSpace(payload.DocumentId))
            {
                return false;
            }

            cursor = new SnapHistoryCursor(
                payload.CreatedAt.ToUniversalTime(),
                payload.DocumentId.Trim());
            return true;
        }
        catch (Exception ex) when (
            ex is FormatException or JsonException or ArgumentException)
        {
            return false;
        }
    }
}
```

- [ ] **Step 5: Run the cursor tests and confirm GREEN**

Run the same filtered `dotnet test` command. Expected: all `SnapHistoryCursorCodecTests` pass.

- [ ] **Step 6: Commit the backend contracts**

```powershell
git add Models/SnapHistoryModels.cs Services/SnapHistoryCursorCodec.cs Milingo.Backend.Tests/SnapHistoryCursorCodecTests.cs
git commit -m "feat: add scan history cursor contract"
```

---

### Task 2: Authenticated Firestore History Endpoint

**Files:**
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/IFirestoreService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/FirestoreService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Controller/SnapController.cs`
- Test: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/SnapHistorySourceTests.cs`

**Interfaces:**
- Consumes: Task 1's cursor codec and DTOs.
- Produces: `IFirestoreService.GetSnapHistoryAsync(string userId, int limit, SnapHistoryCursor? cursor, CancellationToken)` and `GET /api/v1/snap/history`.

- [ ] **Step 1: Write the focused backend source-contract test**

```csharp
using Xunit;

namespace Milingo.Backend.Tests;

public class SnapHistorySourceTests
{
    [Fact]
    public void History_query_is_user_scoped_stably_ordered_and_bounded()
    {
        var source = File.ReadAllText(RepositoryFile("Services", "FirestoreService.cs"));

        Assert.Contains("Collection(\"users\").Document(userId)", source);
        Assert.Contains(".Collection(\"vocabularies\")", source);
        Assert.Contains(".OrderByDescending(\"created_at\")", source);
        Assert.Contains(".OrderByDescending(FieldPath.DocumentId)", source);
        Assert.Contains(".StartAfter(", source);
        Assert.Contains(".Limit(pageSize + 1)", source);
    }

    [Fact]
    public void Controller_reads_uid_from_claims_and_rejects_bad_cursor()
    {
        var source = File.ReadAllText(RepositoryFile("Controller", "SnapController.cs"));

        Assert.Contains("[HttpGet(\"history\")]", source);
        Assert.Contains("User.GetFirebaseUid()", source);
        Assert.Contains("SnapHistoryCursorCodec.TryDecode", source);
        Assert.Contains("return BadRequest", source);
        Assert.DoesNotContain("string userId, int limit", source);
    }

    private static string RepositoryFile(params string[] parts)
    {
        var root = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory, "..", "..", "..", ".."));
        return Path.Combine(new[] { root }.Concat(parts).ToArray());
    }
}
```

- [ ] **Step 2: Run the source test and confirm RED**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter FullyQualifiedName~SnapHistorySourceTests
```

Expected: failures for the missing endpoint and query.

- [ ] **Step 3: Add the service contract**

Add under `SNAP & LEARN` in `IFirestoreService.cs`:

```csharp
Task<SnapHistoryPage> GetSnapHistoryAsync(
    string userId,
    int limit,
    SnapHistoryCursor? cursor,
    CancellationToken cancellationToken = default);
```

- [ ] **Step 4: Implement the stable Firestore page query**

In `FirestoreService.cs`, build the query in this order:

```csharp
public async Task<SnapHistoryPage> GetSnapHistoryAsync(
    string userId,
    int limit,
    SnapHistoryCursor? cursor,
    CancellationToken cancellationToken = default)
{
    var pageSize = SnapHistoryCursorCodec.NormalizeLimit(limit);
    var vocabCollection = _db.Collection("users").Document(userId)
        .Collection("vocabularies");
    Query query = vocabCollection
        .OrderByDescending("created_at")
        .OrderByDescending(FieldPath.DocumentId);

    if (cursor is not null)
    {
        query = query.StartAfter(
            Timestamp.FromDateTime(DateTime.SpecifyKind(
                cursor.CreatedAt.ToUniversalTime(),
                DateTimeKind.Utc)),
            vocabCollection.Document(cursor.DocumentId));
    }

    var snapshot = await query
        .Limit(pageSize + 1)
        .GetSnapshotAsync(cancellationToken);
    var hasMore = snapshot.Documents.Count > pageSize;
    var visible = snapshot.Documents.Take(pageSize).ToList();
    var items = visible.Select(MapToSnapHistoryItem).ToList();
    var last = visible.LastOrDefault();

    return new SnapHistoryPage
    {
        Items = items,
        HasMore = hasMore,
        NextCursor = hasMore && last is not null
            ? SnapHistoryCursorCodec.Encode(new SnapHistoryCursor(
                last.GetValue<Timestamp>("created_at").ToDateTime(),
                last.Id))
            : null
    };
}
```

Add this private mapper in `FirestoreService.cs`:

```csharp
private static SnapHistoryItem MapToSnapHistoryItem(DocumentSnapshot document)
{
    var relatedWords = new List<RelatedWordResponse>();
    if (document.ContainsField("related_words"))
    {
        var rawWords = document.GetValue<List<Dictionary<string, object>>>(
            "related_words");
        relatedWords = rawWords.Select(word => new RelatedWordResponse
        {
            Keyword = word.TryGetValue("keyword", out var keyword)
                ? keyword?.ToString() ?? string.Empty
                : string.Empty,
            Translation = word.TryGetValue("translation", out var translation)
                ? translation?.ToString() ?? string.Empty
                : string.Empty,
            Pronunciation = word.TryGetValue("pronunciation", out var pronunciation)
                ? pronunciation?.ToString() ?? string.Empty
                : string.Empty
        }).ToList();
    }

    var createdAt = document.ContainsField("created_at")
        ? document.GetValue<Timestamp>("created_at").ToDateTime().ToUniversalTime()
        : DateTime.UnixEpoch;

    return new SnapHistoryItem
    {
        Id = document.Id,
        SnapGroupId = document.ContainsField("snap_group_id")
            ? document.GetValue<string>("snap_group_id")
            : null,
        Keyword = GetString(document, "keyword"),
        Translation = GetString(document, "translation"),
        Pronunciation = GetString(document, "pronunciation"),
        ExampleSentence = GetString(document, "example_sentence"),
        RelatedWords = relatedWords,
        CreatedAt = createdAt.ToString("O")
    };
}
```

- [ ] **Step 5: Add the authenticated controller action**

Add before POST actions in `SnapController.cs`:

```csharp
[HttpGet("history")]
public async Task<IActionResult> GetSnapHistory(
    [FromQuery] int limit = 5,
    [FromQuery] string? cursor = null,
    CancellationToken cancellationToken = default)
{
    try
    {
        var userId = User.GetFirebaseUid();
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized(new ApiResponse<object>
            {
                Status = "error",
                Message = "Invalid token: User identifier not found in claims."
            });
        }

        SnapHistoryCursor? decoded = null;
        if (cursor is not null)
        {
            if (!SnapHistoryCursorCodec.TryDecode(cursor, out var parsed))
            {
                return BadRequest(new ApiResponse<object>
                {
                    Status = "error",
                    Message = "Invalid scan history cursor."
                });
            }
            decoded = parsed;
        }

        var page = await _firestoreService.GetSnapHistoryAsync(
            userId,
            SnapHistoryCursorCodec.NormalizeLimit(limit),
            decoded,
            cancellationToken);

        return Ok(new ApiResponse<SnapHistoryPage>
        {
            Status = "success",
            Message = "Scan history retrieved successfully.",
            Data = page
        });
    }
    catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
    {
        _logger.LogInformation("Get scan history request cancelled: client disconnected.");
        return StatusCode(499);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Unexpected error getting scan history.");
        return StatusCode(StatusCodes.Status500InternalServerError,
            new ApiResponse<object>
            {
                Status = "error",
                Message = "An unexpected error occurred while loading scan history."
            });
    }
}
```

- [ ] **Step 6: Run the two focused backend test classes**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter "FullyQualifiedName~SnapHistory"
```

Expected: cursor and source-contract tests pass.

- [ ] **Step 7: Build the backend once**

```powershell
dotnet build Milingo.Backend.csproj --no-restore
```

Expected: build succeeds without warnings introduced by the new files.

- [ ] **Step 8: Commit the backend endpoint**

```powershell
git add Services/IFirestoreService.cs Services/FirestoreService.cs Controller/SnapController.cs Milingo.Backend.Tests/SnapHistorySourceTests.cs
git commit -m "feat: expose paginated scan history"
```

---

### Task 3: Flutter Network Models and Auth-Scoped Pagination State

**Files:**
- Modify: `lib/core/network/milingo_models.dart`
- Modify: `lib/core/network/milingo_api_service.dart`
- Create: `lib/features/flashcards/providers/scan_history_provider.dart`
- Test: `test/snap_history_models_test.dart`
- Test: `test/scan_history_provider_test.dart`

**Interfaces:**
- Consumes: backend payload from Task 2.
- Produces: `SnapHistoryItemResponse`, `SnapHistoryPageResponse`, `MilingoApiService.getSnapHistory`, `ScanHistoryDataSource`, `ScanHistoryState`, and `scanHistoryProvider`.

- [ ] **Step 1: Write the failing JSON model test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';

void main() {
  test('parses scan history page and optional detail fields', () {
    final page = SnapHistoryPageResponse.fromJson({
      'items': [
        {
          'id': 'v1',
          'snap_group_id': 'g1',
          'keyword': 'dog',
          'translation': 'con chó',
          'pronunciation': '/dɔːɡ/',
          'example_sentence': 'The dog is friendly.',
          'related_words': [
            {'keyword': 'puppy', 'translation': 'chó con', 'pronunciation': ''},
          ],
          'created_at': '2026-07-17T03:30:00Z',
        },
      ],
      'next_cursor': 'cursor-2',
      'has_more': true,
    });

    expect(page.items.single.keyword, 'dog');
    expect(page.items.single.relatedWords.single.keyword, 'puppy');
    expect(page.items.single.createdAt, DateTime.utc(2026, 7, 17, 3, 30));
    expect(page.nextCursor, 'cursor-2');
    expect(page.hasMore, isTrue);
  });
}
```

- [ ] **Step 2: Run the model test and confirm RED**

```powershell
flutter test test/snap_history_models_test.dart
```

Expected: compile failure because the history response classes do not exist.

- [ ] **Step 3: Add immutable Dart response models and Dio call**

Add these classes beside the existing snap models:

```dart
class SnapHistoryItemResponse {
  const SnapHistoryItemResponse({
    required this.id,
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.exampleSentence,
    required this.relatedWords,
    required this.createdAt,
    this.snapGroupId,
  });

  factory SnapHistoryItemResponse.fromJson(Map<String, dynamic> json) {
    final rawRelated = json['related_words'];
    final relatedWords = rawRelated is List
        ? rawRelated
            .whereType<Map>()
            .map((word) => SnapRelatedWord.fromJson(
                  Map<String, dynamic>.from(word),
                ))
            .toList(growable: false)
        : const <SnapRelatedWord>[];

    return SnapHistoryItemResponse(
      id: (json['id'] ?? '').toString(),
      snapGroupId: json['snap_group_id']?.toString(),
      keyword: (json['keyword'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      exampleSentence: (json['example_sentence'] ?? '').toString(),
      relatedWords: List.unmodifiable(relatedWords),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String? snapGroupId;
  final String keyword;
  final String translation;
  final String pronunciation;
  final String exampleSentence;
  final List<SnapRelatedWord> relatedWords;
  final DateTime createdAt;
}

class SnapHistoryPageResponse {
  const SnapHistoryPageResponse({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory SnapHistoryPageResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => SnapHistoryItemResponse.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <SnapHistoryItemResponse>[];
    return SnapHistoryPageResponse(
      items: List.unmodifiable(items),
      nextCursor: json['next_cursor']?.toString(),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  final List<SnapHistoryItemResponse> items;
  final String? nextCursor;
  final bool hasMore;
}
```

Add to `MilingoApiService`:

```dart
Future<SnapHistoryPageResponse> getSnapHistory({
  int limit = 5,
  String? cursor,
}) async {
  try {
    final response = await _dio.get(
      '/api/v1/snap/history',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return _unwrap(
      response,
      (data) => SnapHistoryPageResponse.fromJson(
        Map<String, dynamic>.from(data as Map),
      ),
    );
  } on DioException catch (error) {
    throw _apiExceptionFromDio(error);
  }
}
```

- [ ] **Step 4: Run the model test and confirm GREEN**

Run the same targeted Flutter test. Expected: pass.

- [ ] **Step 5: Write failing pagination-state tests**

In `test/scan_history_provider_test.dart`, use a fake `ScanHistoryDataSource` and override `scanHistoryUserIdProvider` with `user-a`. Test these exact behaviors:

```dart
test('loads five initially and merges exactly one concurrent next page', () async {
  final source = FakeScanHistoryDataSource.twoPages();
  final container = ProviderContainer(overrides: [
    scanHistoryDataSourceProvider.overrideWithValue(source),
    scanHistoryUserIdProvider.overrideWithValue('user-a'),
  ]);
  addTearDown(container.dispose);
  final subscription = container.listen(
    scanHistoryProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);

  final first = await container.read(scanHistoryProvider.future);
  expect(first.items.length, 5);

  final notifier = container.read(scanHistoryProvider.notifier);
  final requestA = notifier.loadMore();
  final requestB = notifier.loadMore();
  await Future.wait([requestA, requestB]);

  expect(source.loadMoreCalls, 1);
  expect(container.read(scanHistoryProvider).value!.items.length, 10);
});

test('does not request another page after hasMore becomes false', () async {
  final source = FakeScanHistoryDataSource.singlePage();
  final container = ProviderContainer(overrides: [
    scanHistoryDataSourceProvider.overrideWithValue(source),
    scanHistoryUserIdProvider.overrideWithValue('user-a'),
  ]);
  addTearDown(container.dispose);
  final subscription = container.listen(
    scanHistoryProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(subscription.close);

  await container.read(scanHistoryProvider.future);
  await container.read(scanHistoryProvider.notifier).loadMore();

  expect(source.totalCalls, 1);
});
```

Use this fake below the tests; `_page()` creates deterministic items named `word-$start` through `word-${start + count - 1}` with UTC timestamps:

```dart
class FakeScanHistoryDataSource implements ScanHistoryDataSource {
  FakeScanHistoryDataSource.twoPages()
      : pages = [
          _page(start: 0, count: 5, cursor: 'next', hasMore: true),
          _page(start: 5, count: 5, cursor: null, hasMore: false),
        ];

  FakeScanHistoryDataSource.singlePage()
      : pages = [
          _page(start: 0, count: 5, cursor: null, hasMore: false),
        ];

  final List<SnapHistoryPageResponse> pages;
  int totalCalls = 0;
  int loadMoreCalls = 0;

  @override
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  }) async {
    final index = totalCalls;
    totalCalls++;
    if (cursor != null) {
      loadMoreCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return pages[index < pages.length ? index : pages.length - 1];
  }
}

SnapHistoryPageResponse _page({
  required int start,
  required int count,
  required String? cursor,
  required bool hasMore,
}) {
  return SnapHistoryPageResponse(
    items: List.generate(count, (offset) {
      final index = start + offset;
      return SnapHistoryItemResponse(
        id: 'item-$index',
        keyword: 'word-$index',
        translation: 'translation-$index',
        pronunciation: '',
        exampleSentence: '',
        relatedWords: const [],
        createdAt: DateTime.utc(2026, 7, 17).subtract(Duration(minutes: index)),
      );
    }),
    nextCursor: cursor,
    hasMore: hasMore,
  );
}
```

- [ ] **Step 6: Run the provider test and confirm RED**

```powershell
flutter test test/scan_history_provider_test.dart
```

Expected: compile failure because the provider/data-source contracts do not exist.

- [ ] **Step 7: Implement the data-source boundary and auto-disposed notifier**

Create `scan_history_provider.dart` with this state/data-source implementation:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';

abstract interface class ScanHistoryDataSource {
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  });
}

class MilingoScanHistoryDataSource implements ScanHistoryDataSource {
  const MilingoScanHistoryDataSource(this._api);

  final MilingoApiService _api;

  @override
  Future<SnapHistoryPageResponse> fetchPage({
    int limit = 5,
    String? cursor,
  }) {
    return _api.getSnapHistory(limit: limit, cursor: cursor);
  }
}

final scanHistoryDataSourceProvider = Provider<ScanHistoryDataSource>((ref) {
  return MilingoScanHistoryDataSource(ref.watch(milingoApiServiceProvider));
});

final scanHistoryUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid ??
      FirebaseAuth.instance.currentUser?.uid;
});

final scanHistoryProvider = AsyncNotifierProvider.autoDispose<
    ScanHistoryNotifier, ScanHistoryState>(ScanHistoryNotifier.new);

class ScanHistoryState {
  const ScanHistoryState({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory ScanHistoryState.fromPage(SnapHistoryPageResponse page) {
    return ScanHistoryState(
      items: List.unmodifiable(page.items),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  final List<SnapHistoryItemResponse> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;
}

class ScanHistoryNotifier extends AutoDisposeAsyncNotifier<ScanHistoryState> {
  late ScanHistoryDataSource _dataSource;
  bool _loadMoreInFlight = false;
  bool _disposed = false;

  @override
  Future<ScanHistoryState> build() async {
    ref.onDispose(() => _disposed = true);
    final userId = ref.watch(scanHistoryUserIdProvider);
    if (userId == null) {
      return const ScanHistoryState(
        items: [],
        nextCursor: null,
        hasMore: false,
      );
    }

    _dataSource = ref.watch(scanHistoryDataSourceProvider);
    final page = await _dataSource.fetchPage(limit: 5);
    return ScanHistoryState.fromPage(page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null ||
        _loadMoreInFlight ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    _loadMoreInFlight = true;
    state = AsyncValue.data(ScanHistoryState(
      items: current.items,
      nextCursor: current.nextCursor,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));

    try {
      final page = await _dataSource.fetchPage(
        limit: 5,
        cursor: current.nextCursor,
      );
      if (_disposed) return;
      state = AsyncValue.data(ScanHistoryState(
        items: List.unmodifiable([...current.items, ...page.items]),
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      ));
    } catch (error) {
      if (_disposed) return;
      state = AsyncValue.data(ScanHistoryState(
        items: current.items,
        nextCursor: current.nextCursor,
        hasMore: current.hasMore,
        loadMoreError: error,
      ));
    } finally {
      _loadMoreInFlight = false;
    }
  }
}
```

Do not invalidate `flashcardProvider` or `snapControllerProvider`.

- [ ] **Step 8: Run model and provider tests and confirm GREEN**

```powershell
flutter test test/snap_history_models_test.dart test/scan_history_provider_test.dart
```

Expected: all targeted tests pass.

- [ ] **Step 9: Commit the mobile data/state layer**

```powershell
git add lib/core/network/milingo_models.dart lib/core/network/milingo_api_service.dart lib/features/flashcards/providers/scan_history_provider.dart test/snap_history_models_test.dart test/scan_history_provider_test.dart
git commit -m "feat: add scan history pagination state"
```

---

### Task 4: Timeline UI, Read-Only Detail, and Routing

**Files:**
- Create: `lib/features/flashcards/widgets/scan_history_widgets.dart`
- Create: `lib/features/flashcards/screens/scan_history_screen.dart`
- Create: `lib/features/flashcards/screens/scan_history_detail_screen.dart`
- Modify: `lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart`
- Modify: `lib/features/flashcards/screens/flashcards_screen.dart`
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/core/routing/app_router.dart`
- Test: `test/scan_history_widgets_test.dart`
- Test: `test/scan_history_routing_source_test.dart`

**Interfaces:**
- Consumes: Task 3's `scanHistoryProvider` and immutable history items.
- Produces: `ScanHistoryTimeline`, `ScanHistoryScreen`, `ScanHistoryDetailScreen`, `/flashcards/scan-history`, and `/flashcards/scan-history/detail`.

- [ ] **Step 1: Write the failing timeline widget test**

Create two items whose UTC timestamps become today and yesterday after conversion to device local time. Pump `ScanHistoryTimeline(items: ..., onItemTap: ...)`, then assert:

```dart
expect(find.text('Hôm nay'), findsOneWidget);
expect(find.text('Hôm qua'), findsOneWidget);
expect(find.text('Dog'), findsOneWidget);
expect(find.text('con chó'), findsOneWidget);
await tester.tap(find.text('Dog'));
expect(tappedId, 'today');
```

Use a `MaterialApp` and set timestamps from `DateTime.now()` at midday to avoid midnight boundary flakiness.

- [ ] **Step 2: Write the failing route/source guard test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scan history button pushes dedicated routes and detail stays read only', () {
    final constants = File('lib/core/constants/app_constants.dart').readAsStringSync();
    final dashboard = File('lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart').readAsStringSync();
    final screen = File('lib/features/flashcards/screens/flashcards_screen.dart').readAsStringSync();
    final detail = File('lib/features/flashcards/screens/scan_history_detail_screen.dart').readAsStringSync();

    expect(constants, contains("scanHistoryRoute = '/flashcards/scan-history'"));
    expect(dashboard, contains('required this.onScanHistoryTap'));
    expect(screen, contains('context.push(AppConstants.scanHistoryRoute)'));
    expect(detail, isNot(contains('flashcardProvider')));
    expect(detail, isNot(contains('delete')));
    expect(detail, isNot(contains('favorite')));
  });
}
```

- [ ] **Step 3: Run both UI tests and confirm RED**

```powershell
flutter test test/scan_history_widgets_test.dart test/scan_history_routing_source_test.dart
```

Expected: missing files/classes/routes.

- [ ] **Step 4: Build the reusable timeline widgets**

Implement `ScanHistoryTimeline` as a stateless widget that:

- groups items by `item.createdAt.toLocal()` date without reordering them;
- labels today/yesterday in Vietnamese and older groups as zero-padded `dd/MM/yyyy` without adding `intl`;
- renders the orange rail/dot and rounded translucent white cards;
- uses `Icons.auto_awesome_rounded` in a `#FF6A00` 10%-opacity container;
- shows translation and hides empty pronunciation;
- calls `onItemTap(item)` through `InkWell`.

Keep background, ink, orange, gradient, shadow, and spacing constants inside this history widget file so existing dashboard colors are untouched.

- [ ] **Step 5: Build the provider-aware infinite history screen**

Implement a `ConsumerStatefulWidget` with one `ScrollController`. Register a listener in `initState`, remove/dispose it in `dispose`, and call `loadMore()` when `position.extentAfter <= 200`. Render:

- centered initial spinner;
- friendly empty state;
- initial error plus `ref.invalidate(scanHistoryProvider)` retry;
- `ScanHistoryTimeline` for data;
- compact bottom spinner while `isLoadingMore`;
- inline retry when `loadMoreError != null`;
- subtle end message only when items are non-empty and `hasMore == false`.

Tap items with:

```dart
context.push(AppConstants.scanHistoryDetailRoute, extra: item);
```

- [ ] **Step 6: Build the dedicated read-only detail screen**

Accept `SnapHistoryItemResponse item` in the constructor. Use the approved palette, a back button, orange icon hero, keyword, optional pronunciation, translation, optional example sentence, optional related-word chips, and local scan date/time. Do not import or watch `flashcardProvider`, and expose no overflow menu or mutations.

- [ ] **Step 7: Wire constants, router, and dashboard callback**

Add:

```dart
static const String scanHistoryRoute = '/flashcards/scan-history';
static const String scanHistoryDetailRoute = '/flashcards/scan-history/detail';
```

Add both `GoRoute`s. The detail builder must type-check `state.extra`; if it is not `SnapHistoryItemResponse`, return `const ScanHistoryScreen()` rather than constructing fake history data.

Change `VocabularyHeroCard` to require `VoidCallback onScanHistoryTap`, pass it into `_ScanHistoryButton`, and render the button as `Material` + `InkWell` with the existing visual decoration. In `FlashcardsScreen`, pass:

```dart
onScanHistoryTap: () => context.push(AppConstants.scanHistoryRoute),
```

- [ ] **Step 8: Run the focused UI/routing tests and confirm GREEN**

```powershell
flutter test test/scan_history_widgets_test.dart test/scan_history_routing_source_test.dart
```

Expected: timeline grouping/tap and route/read-only guards pass.

- [ ] **Step 9: Commit the mobile UI**

```powershell
git add lib/features/flashcards/widgets/scan_history_widgets.dart lib/features/flashcards/screens/scan_history_screen.dart lib/features/flashcards/screens/scan_history_detail_screen.dart lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart lib/features/flashcards/screens/flashcards_screen.dart lib/core/constants/app_constants.dart lib/core/routing/app_router.dart test/scan_history_widgets_test.dart test/scan_history_routing_source_test.dart
git commit -m "feat: add scan history timeline screens"
```

---

### Task 5: Focused Verification and Handoff

**Files:**
- Modify only files requiring formatter output from Tasks 1–4.
- Do not stage or modify `pubspec.yaml`.

**Interfaces:**
- Consumes: all prior tasks.
- Produces: verification evidence and a concise handoff.

- [ ] **Step 1: Format only touched Dart/test files**

```powershell
dart format lib/core/network/milingo_models.dart lib/core/network/milingo_api_service.dart lib/features/flashcards/providers/scan_history_provider.dart lib/features/flashcards/widgets/scan_history_widgets.dart lib/features/flashcards/screens/scan_history_screen.dart lib/features/flashcards/screens/scan_history_detail_screen.dart lib/features/flashcards/widgets/vocabulary_dashboard_widgets.dart lib/features/flashcards/screens/flashcards_screen.dart lib/core/constants/app_constants.dart lib/core/routing/app_router.dart test/snap_history_models_test.dart test/scan_history_provider_test.dart test/scan_history_widgets_test.dart test/scan_history_routing_source_test.dart
```

Expected: formatter completes without touching unrelated files.

- [ ] **Step 2: Run all new Flutter tests together**

```powershell
flutter test test/snap_history_models_test.dart test/scan_history_provider_test.dart test/scan_history_widgets_test.dart test/scan_history_routing_source_test.dart
```

Expected: all new tests pass.

- [ ] **Step 3: Run Flutter analysis once**

```powershell
flutter analyze
```

Expected: no new warnings or errors. If pre-existing issues appear, distinguish them from changed-file issues in the handoff.

- [ ] **Step 4: Re-run backend history tests and build once**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter "FullyQualifiedName~SnapHistory"
dotnet build Milingo.Backend.csproj --no-restore
```

Expected: focused history tests and backend build pass.

- [ ] **Step 5: Inspect both worktrees without altering user changes**

```powershell
git status --short
git diff --check
```

Run in each repository. Confirm mobile `pubspec.yaml` is still the user's only unrelated modification and no generated/build files are staged.

- [ ] **Step 6: Commit formatter-only corrections if needed**

If Step 1 changed already committed feature files, stage only those named files and commit:

```powershell
git commit -m "style: format scan history files"
```

If the formatter produced no post-commit diff, skip this commit.

- [ ] **Step 7: Report the result**

Report the endpoint, first-page/load-more behavior, read-only detail navigation, exact focused checks run, any blocked check, backend deployment requirement, and that the user's `pubspec.yaml` change was preserved.
