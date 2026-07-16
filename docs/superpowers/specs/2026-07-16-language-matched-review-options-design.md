# Language-Matched Review Options Design

## Goal

Ensure every multiple-choice option in a review question uses the reviewed card's target language.

## Scope

- Change only backend distractor selection and its focused regression coverage.
- Keep the Flutter request, response parsing, review UI, answer submission, SRS behavior, and AI integration contract unchanged.
- Never read cards belonging to another user.

## Current Cause

`FirestoreService.GetDistractorCardsAsync` searches the active deck and then the authenticated user's remaining decks without filtering candidates by `target_lang_code`. Consequently, a Chinese review card can receive English, Japanese, or German distractors.

## Design

`StudyController` will pass the reviewed card's normalized `TargetLangCode` into `GetDistractorCardsAsync`.

The Firestore service will:

1. Search the reviewed card's deck first.
2. Keep only cards owned by the authenticated user whose normalized target-language code matches the reviewed card.
3. Search the same authenticated user's remaining decks only when the current deck does not provide three unique candidates, applying the same language filter.
4. Return at most three unique distractors.

No global or cross-user vocabulary pool will be queried. If the authenticated user's matching-language cards provide fewer than three unique distractors, the existing AI generator will supply the missing options. If database and AI candidates together still cannot form four unique choices including the correct answer, the existing flashcard-mode fallback remains unchanged.

## Data Flow

1. Flutter requests the study session with the current target language.
2. The backend selects due cards using the existing target-language filter.
3. For each MCQ card, the controller requests distractors using that card's target-language code.
4. Firestore returns same-language candidates from that user's decks, prioritizing the current deck.
5. The existing AI generator fills any shortage.
6. The existing response returns four shuffled options, or falls back to flashcard mode when four unique options cannot be formed.

## Error Handling

- Preserve the current AI-unavailable behavior: log the failure and use flashcard mode if there are insufficient options.
- Preserve cancellation propagation and existing API error handling.
- Do not add client-side language detection or filtering.

## Verification

- Add a focused backend regression test proving mixed-language candidates are rejected while matching-language candidates remain eligible.
- Run that focused test and a backend build/test check only; no full Flutter suite is needed because no Dart files should change.
