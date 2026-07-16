# Fast Language-Matched Review Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build review MCQ options from one shared, same-language pool owned by the authenticated user so normal sessions avoid per-card Firestore scans and AI calls.

**Architecture:** Seed a session pool from due cards, supplement it once from every user-owned deck only when fewer than four unique terms exist, and select three distractors per question while excluding only the current card/term. Keep the response contract unchanged and bound concurrent AI fallback to three requests.

**Tech Stack:** ASP.NET Core 8, C#, Google Cloud Firestore, xUnit v3

## Global Constraints

- Read cards only under `users/{authenticatedUserId}/flashcard_decks`.
- Reuse cards from the same review session and other matching-language decks.
- Exclude only the current correct card and duplicate term for each question.
- Apply `target_lang_code` in Firestore before `Limit(10)`.
- Query each owned deck at most once per session and retain at most 50 supplemental cards.
- Use AI only after the authenticated user's pool is exhausted, with concurrency limited to three.
- Preserve Flutter, API response, answer submission, SRS, caching, and flashcard fallback behavior.

---

### Task 1: Add Shared-Pool Selection Policy

**Files:**
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/StudyDistractorPolicy.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/StudyDistractorPolicyTests.cs`

**Interfaces:**
- Consumes: `CardResponse.Term`, `TargetLangCode`, `DeckId`, and `Id`.
- Produces: `BuildPool(IEnumerable<CardResponse>, string, int)` and `SelectDistractors(CardResponse, IEnumerable<CardResponse>, int)`.

- [ ] **Step 1: Add failing behavior tests**

```csharp
[Fact]
public void BuildPool_keeps_unique_matching_language_cards_across_decks()
{
    var cards = new[]
    {
        Card("current", "deck-a", "chair", "en"),
        Card("due", "deck-b", "table", "English"),
        Card("duplicate", "deck-c", "TABLE", "en"),
        Card("wrong-language", "deck-c", "椅子", "ja")
    };

    var pool = StudyDistractorPolicy.BuildPool(cards, "en", 50);

    Assert.Equal(2, pool.Count);
    Assert.Contains(pool, card => card.Id == "current");
    Assert.Contains(pool, card => card.Id == "due");
}

[Fact]
public void SelectDistractors_reuses_same_session_cards_but_excludes_current_term()
{
    var correct = Card("current", "deck-a", "chair", "en");
    var pool = new[]
    {
        correct,
        Card("same-term", "deck-b", "CHAIR", "en"),
        Card("one", "deck-a", "table", "en"),
        Card("two", "deck-b", "lamp", "English"),
        Card("three", "deck-c", "sofa", "en"),
        Card("wrong-language", "deck-c", "椅子", "ja")
    };

    var distractors =
        StudyDistractorPolicy.SelectDistractors(correct, pool, 3);

    Assert.Equal(3, distractors.Count);
    Assert.All(distractors, card =>
        Assert.True(StudyDistractorPolicy.MatchesTargetLanguage(
            card.TargetLangCode,
            "en")));
    Assert.DoesNotContain(distractors, card =>
        string.Equals(card.Term, "chair", StringComparison.OrdinalIgnoreCase));
}

private static CardResponse Card(
    string id,
    string deckId,
    string term,
    string language) => new()
{
    Id = id,
    DeckId = deckId,
    Term = term,
    TargetLangCode = language
};
```

- [ ] **Step 2: Run RED**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
```

Expected: compilation fails because `BuildPool` and `SelectDistractors` do not exist.

- [ ] **Step 3: Implement the pure policy**

```csharp
internal static List<CardResponse> BuildPool(
    IEnumerable<CardResponse> candidates,
    string requiredLanguage,
    int maxCandidates)
{
    var usedTerms = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

    return candidates
        .Where(card => MatchesTargetLanguage(
            card.TargetLangCode,
            requiredLanguage))
        .Where(card => !string.IsNullOrWhiteSpace(card.Term))
        .Where(card => usedTerms.Add(card.Term.Trim()))
        .Take(Math.Max(0, maxCandidates))
        .ToList();
}

internal static List<CardResponse> SelectDistractors(
    CardResponse correctCard,
    IEnumerable<CardResponse> candidatePool,
    int count)
{
    var usedTerms = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        correctCard.Term.Trim()
    };

    return candidatePool
        .Where(card => !(card.Id == correctCard.Id
            && card.DeckId == correctCard.DeckId))
        .Where(card => MatchesTargetLanguage(
            card.TargetLangCode,
            correctCard.TargetLangCode))
        .Where(card => !string.IsNullOrWhiteSpace(card.Term))
        .Where(card => usedTerms.Add(card.Term.Trim()))
        .OrderBy(_ => Guid.NewGuid())
        .Take(Math.Max(0, count))
        .ToList();
}
```

- [ ] **Step 4: Run GREEN**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
```

Expected: all policy tests pass.

### Task 2: Fetch One Supplemental Pool Per Session

**Files:**
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/IFirestoreService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/FirestoreService.cs`
- Create: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/StudyDistractorSourceTests.cs`

**Interfaces:**
- Replaces: `GetDistractorCardsAsync(...)`.
- Produces: `GetDistractorPoolAsync(string userId, string targetLanguageCode, int perDeckLimit = 10, int maxCandidates = 50, CancellationToken cancellationToken = default)`.

- [ ] **Step 1: Add a failing structural regression test**

```csharp
using Xunit;

namespace Milingo.Backend.Tests;

public class StudyDistractorSourceTests
{
    [Fact]
    public void Firestore_filters_language_before_the_per_deck_limit()
    {
        var source = File.ReadAllText(RepositoryFile(
            "Services",
            "FirestoreService.cs"));
        var filter = source.IndexOf(
            ".WhereEqualTo(\"target_lang_code\", normalizedLanguage)",
            StringComparison.Ordinal);
        var limit = source.IndexOf(
            ".Limit(perDeckLimit)",
            filter,
            StringComparison.Ordinal);

        Assert.True(filter >= 0);
        Assert.True(limit > filter);
        Assert.Contains("Task.WhenAll(deckTasks)", source);
    }

    private static string RepositoryFile(params string[] parts)
    {
        var root = Path.GetFullPath(Path.Combine(
            AppContext.BaseDirectory,
            "..",
            "..",
            "..",
            ".."));
        return Path.Combine(new[] { root }.Concat(parts).ToArray());
    }

    private static int Count(string source, string value) =>
        source.Split(value, StringSplitOptions.None).Length - 1;
}
```

- [ ] **Step 2: Run RED**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
```

Expected: `Firestore_filters_language_before_the_per_deck_limit` fails.

- [ ] **Step 3: Replace the service contract and implementation**

```csharp
public async Task<List<CardResponse>> GetDistractorPoolAsync(
    string userId,
    string targetLanguageCode,
    int perDeckLimit = 10,
    int maxCandidates = 50,
    CancellationToken cancellationToken = default)
{
    perDeckLimit = Math.Clamp(perDeckLimit, 1, 50);
    maxCandidates = Math.Clamp(maxCandidates, 1, 200);
    var normalizedLanguage =
        SupportedLanguages.NormalizeLanguageCode(targetLanguageCode);
    if (normalizedLanguage.Length == 0)
        return new List<CardResponse>();

    var decksSnapshot = await _db.Collection("users").Document(userId)
        .Collection("flashcard_decks")
        .GetSnapshotAsync(cancellationToken);

    var deckTasks = decksSnapshot.Documents.Select(async deck =>
    {
        var deckName = deck.ContainsField("name")
            ? deck.GetValue<string>("name")
            : string.Empty;
        var cards = await deck.Reference.Collection("cards")
            .WhereEqualTo("target_lang_code", normalizedLanguage)
            .Limit(perDeckLimit)
            .GetSnapshotAsync(cancellationToken);

        return cards.Documents.Select(card =>
            MapToCardResponse(card, deck.Id, deckName));
    });

    var candidates = (await Task.WhenAll(deckTasks))
        .SelectMany(cards => cards)
        .OrderBy(_ => Guid.NewGuid());

    return StudyDistractorPolicy.BuildPool(
        candidates,
        normalizedLanguage,
        maxCandidates);
}
```

Use the same signature in `IFirestoreService` and remove the old per-card method.

- [ ] **Step 4: Run GREEN**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
```

Expected: tests pass and the interface compiles.

### Task 3: Assemble Questions from the Shared Pool

**Files:**
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Controller/StudyController.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/StudyDistractorSourceTests.cs`

**Interfaces:**
- Consumes: `BuildPool`, `SelectDistractors`, and `GetDistractorPoolAsync`.
- Produces: one pool lookup per session and a three-request `SemaphoreSlim` AI gate.

- [ ] **Step 1: Add a failing controller-structure test**

```csharp
[Fact]
public void Controller_uses_one_session_pool_and_bounded_ai_concurrency()
{
    var source = File.ReadAllText(RepositoryFile(
        "Controller",
        "StudyController.cs"));

    Assert.Equal(1, Count(source, "GetDistractorPoolAsync("));
    Assert.DoesNotContain("dueCardIds", source);
    Assert.Contains("StudyDistractorPolicy.SelectDistractors(", source);
    Assert.Contains("new SemaphoreSlim(3)", source);
    Assert.Contains("Task.WhenAll(cardTasks)", source);
}
```

- [ ] **Step 2: Run RED**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
```

Expected: the controller source test fails.

- [ ] **Step 3: Build and supplement the pool once**

Inside `BuildStudyCardsAsync`, replace `dueCardIds` and the sequential loop with:

```csharp
var targetLanguage = dueCards.First().TargetLangCode;
var candidatePool = StudyDistractorPolicy.BuildPool(
    dueCards,
    targetLanguage,
    50);

if (candidatePool.Count < 4)
{
    var supplemental = await _firestoreService.GetDistractorPoolAsync(
        userId,
        targetLanguage,
        perDeckLimit: 10,
        maxCandidates: 50,
        cancellationToken: cancellationToken);
    candidatePool = StudyDistractorPolicy.BuildPool(
        candidatePool.Concat(supplemental),
        targetLanguage,
        80);
}

using var aiConcurrency = new SemaphoreSlim(3);
var cardTasks = dueCards.Select(card => BuildStudyCardAsync(
    userId,
    card,
    candidatePool,
    aiConcurrency,
    cancellationToken));
return (await Task.WhenAll(cardTasks)).ToList();
```

- [ ] **Step 4: Build each card without Firestore reads**

Extract `BuildStudyCardAsync` from the existing loop. Change `BuildMcqOptionsAsync` to select options with:

```csharp
var realDistractors = StudyDistractorPolicy.SelectDistractors(
    correctCard,
    candidatePool,
    needed);
```

Pass `SemaphoreSlim aiConcurrency` into `GetOrGenerateAiDistractorsAsync`. Keep its cache-first check, then wrap only OpenAI generation:

```csharp
await aiConcurrency.WaitAsync(cancellationToken);
try
{
    var openAiService =
        _serviceProvider.GetRequiredService<IOpenAiService>();
    distractors = await openAiService.GenerateDistractorsAsync(
        card.Term,
        card.Translation,
        targetLanguage,
        cancellationToken);
}
finally
{
    aiConcurrency.Release();
}
```

Keep cache writes, option shuffling, response mapping, and flashcard fallback unchanged.

- [ ] **Step 5: Run GREEN and bounded verification**

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --no-restore
dotnet build Milingo.Backend.csproj --no-restore
```

Expected: all backend tests pass and the backend builds with zero errors.

- [ ] **Step 6: Commit the backend change**

```powershell
git add Controller/StudyController.cs Services/IFirestoreService.cs Services/FirestoreService.cs Services/StudyDistractorPolicy.cs Milingo.Backend.Tests/StudyDistractorPolicyTests.cs Milingo.Backend.Tests/StudyDistractorSourceTests.cs
git commit -m "perf: pool review distractors per session"
```

- [ ] **Step 7: Perform one runtime timing check**

Restart or hot-reload the local backend, open English daily review once, and compare request/response timestamps for `/api/v1/study/daily-session?limit=30&targetLanguage=en` in emulator logcat. Expected: a session with at least four unique due English terms returns without AI-dependent multi-second delays.
