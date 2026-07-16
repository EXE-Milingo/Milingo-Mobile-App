# Language-Matched Review Options Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restrict review MCQ distractors to the authenticated user's cards whose target language matches the reviewed card, then use the existing AI fallback for any shortage.

**Architecture:** Add a small pure language-matching policy and apply it inside the existing Firestore distractor selection path. Pass the reviewed card's target-language code through the existing service interface; keep current-deck priority, authenticated-user scoping, AI completion, response shape, and flashcard fallback unchanged.

**Tech Stack:** ASP.NET Core 8, C#, Google Cloud Firestore, xUnit v3

## Global Constraints

- Search only decks under `users/{authenticatedUserId}/flashcard_decks`; never use another user's cards.
- Search the reviewed card's deck first, followed by that same user's remaining decks.
- Accept only cards whose normalized `target_lang_code` matches the reviewed card.
- Use the existing AI generator when fewer than three unique database distractors remain.
- Preserve the existing flashcard fallback when four unique MCQ options still cannot be formed.
- Do not modify Flutter code or unrelated backend behavior.
- Run only the focused regression test plus the backend test project/build check.

---

### Task 1: Enforce Target-Language Matching in Distractor Selection

**Files:**
- Create: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/StudyDistractorPolicy.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/IFirestoreService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Services/FirestoreService.cs`
- Modify: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Controller/StudyController.cs`
- Test: `C:/FPTUniversity/MILINGO/PROJECT/BACKEND/Milingo-Backend/Milingo.Backend.Tests/StudyDistractorPolicyTests.cs`

**Interfaces:**
- Consumes: `SupportedLanguages.NormalizeLanguageCode(string? input)` and the existing `CardResponse.TargetLangCode` value.
- Produces: `StudyDistractorPolicy.MatchesTargetLanguage(string? candidateLanguage, string? requiredLanguage) : bool` and an updated `IFirestoreService.GetDistractorCardsAsync` parameter named `targetLanguageCode`.

- [ ] **Step 1: Write the failing policy regression test**

```csharp
using Milingo.Backend.Services;
using Xunit;

namespace Milingo.Backend.Tests;

public class StudyDistractorPolicyTests
{
    [Theory]
    [InlineData("zh", "zh")]
    [InlineData("Chinese", "zh")]
    [InlineData("zh-CN", "Chinese")]
    public void Matching_target_languages_are_accepted(
        string candidateLanguage,
        string requiredLanguage)
    {
        Assert.True(StudyDistractorPolicy.MatchesTargetLanguage(
            candidateLanguage,
            requiredLanguage));
    }

    [Theory]
    [InlineData("en", "zh")]
    [InlineData("ja", "zh")]
    [InlineData("de", "zh")]
    [InlineData("", "zh")]
    public void Mixed_language_distractors_are_rejected(
        string candidateLanguage,
        string requiredLanguage)
    {
        Assert.False(StudyDistractorPolicy.MatchesTargetLanguage(
            candidateLanguage,
            requiredLanguage));
    }
}
```

- [ ] **Step 2: Run the test to verify RED**

Run:

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter FullyQualifiedName~StudyDistractorPolicyTests
```

Expected: compilation fails because `StudyDistractorPolicy` does not exist.

- [ ] **Step 3: Add the minimal language policy**

```csharp
using Milingo.Backend.Models;

namespace Milingo.Backend.Services;

internal static class StudyDistractorPolicy
{
    internal static bool MatchesTargetLanguage(
        string? candidateLanguage,
        string? requiredLanguage)
    {
        var candidate = SupportedLanguages.NormalizeLanguageCode(candidateLanguage);
        var required = SupportedLanguages.NormalizeLanguageCode(requiredLanguage);

        return candidate.Length > 0
            && required.Length > 0
            && string.Equals(candidate, required, StringComparison.OrdinalIgnoreCase);
    }
}
```

- [ ] **Step 4: Thread the required language through the service contract**

Change the interface and implementation signature to:

```csharp
Task<List<CardResponse>> GetDistractorCardsAsync(
    string userId,
    string deckId,
    string targetLanguageCode,
    IEnumerable<string> excludeCardIds,
    int count = 3,
    CancellationToken cancellationToken = default);
```

In `FirestoreService.GetDistractorCardsAsync`, keep the existing authenticated-user collection path and current-deck-first traversal. Add the policy beside the existing non-empty-term filter:

```csharp
.Where(card => !string.IsNullOrWhiteSpace(card.Term))
.Where(card => StudyDistractorPolicy.MatchesTargetLanguage(
    card.TargetLangCode,
    targetLanguageCode))
```

- [ ] **Step 5: Pass the reviewed card's language from the controller**

Update the existing call in `BuildMcqOptionsAsync`:

```csharp
var realDistractors = await _firestoreService.GetDistractorCardsAsync(
    userId,
    deckId,
    correctCard.TargetLangCode,
    excludeIds,
    needed,
    cancellationToken);
```

Do not change the existing AI shortage calculation or flashcard fallback.

- [ ] **Step 6: Run the focused test to verify GREEN**

Run:

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj --filter FullyQualifiedName~StudyDistractorPolicyTests
```

Expected: all `StudyDistractorPolicyTests` cases pass.

- [ ] **Step 7: Run bounded backend verification**

Run:

```powershell
dotnet test Milingo.Backend.Tests/Milingo.Backend.Tests.csproj
dotnet build Milingo.Backend.csproj --no-restore
```

Expected: the backend test project passes and the backend project builds with zero errors.

- [ ] **Step 8: Commit the backend change**

```powershell
git add Controller/StudyController.cs Services/IFirestoreService.cs Services/FirestoreService.cs Services/StudyDistractorPolicy.cs Milingo.Backend.Tests/StudyDistractorPolicyTests.cs
git commit -m "fix: keep review options in target language"
```
