# Fast Language-Matched Review Options Design

## Goal

Ensure every multiple-choice option uses the selected target language while keeping review-session loading fast.

## Scope

- Change only backend distractor selection, session assembly, and focused regression coverage.
- Keep the Flutter request, response parsing, review UI, answer submission, SRS behavior, and AI integration contract unchanged.
- Read cards only from the authenticated user's Firestore document tree.

## Confirmed Performance Cause

Flutter requests up to 30 due cards and waits for the complete study-session response. The backend currently processes those cards sequentially. For every card it repeats Firestore deck scans, excludes every other due card from the candidate pool, and may await a separate OpenAI request before moving to the next card.

The language filter is also applied after small Firestore limits, so matching cards outside those batches are missed and AI can be invoked unnecessarily. Emulator logs measured English session requests at 9.56 to 21.35 seconds, compared with 0.89 seconds for Japanese on the same backend.

## Design

The backend will build one reusable, same-language candidate pool for the entire session.

1. Seed the pool with all due cards already selected for the session. These cards belong to the authenticated user and already match the selected target language.
2. Treat cards scheduled elsewhere in the same session as valid distractors.
3. If the session contains fewer than four unique terms, enumerate every deck owned by the authenticated user and query matching cards using `target_lang_code` before applying the limit.
4. Query every eligible deck at most once for the session, in parallel, retrieving at most 10 matching cards per deck. Merge terms case-insensitively, shuffle them, and retain at most 50 supplemental candidates; do not download an unbounded vocabulary library.
5. For each question, exclude only the current correct card and its duplicate term, then select three unique distractors from the shared pool.
6. Use the existing AI generator only for questions that still have fewer than three distractors after the authenticated user's matching-language pool is exhausted.
7. When multiple questions require AI, process them concurrently with a maximum of three in-flight OpenAI requests.

No global or cross-user vocabulary source will be queried. Cards in other languages remain ineligible even when they belong to the authenticated user.

## Candidate-Pool Behavior

- All decks owned by the authenticated user are eligible sources.
- Due cards, new cards, and non-due cards may be distractors when their normalized target language matches.
- The current question's correct card and duplicate term are never distractors for that question.
- The same matching-language card may be a correct answer in one question and a distractor in another.
- Candidate order is shuffled so repeated sessions do not always show the same choices.

## Data Flow

1. Flutter requests the daily session with the selected target language.
2. The backend fetches due cards using the existing language filter.
3. The due cards seed one session candidate pool.
4. Only when the pool has fewer than four unique terms, Firestore supplements it from every one of that user's decks using server-side language filtering, up to 10 cards per deck and 50 retained supplemental candidates.
5. The backend builds each question from the shared pool, excluding only that question's correct card.
6. Existing cached or newly generated AI terms fill any remaining shortage.
7. The backend returns the unchanged study-session response.

## Error Handling

- Preserve cancellation propagation and existing API error handling.
- Preserve the current AI-unavailable behavior: use flashcard mode only when four unique MCQ options still cannot be formed.
- A failed supplemental deck query fails the session through the existing endpoint error handling rather than silently mixing languages.
- Do not add client-side language detection or filtering.

## Verification

- Add focused policy tests proving same-session cards are eligible, the current card is excluded, duplicate terms are removed, and other languages are rejected.
- Add a focused controller/service test proving a shared user pool avoids per-card distractor queries and invokes AI only for a genuine shortage.
- Run the backend test project and backend build once after the focused red-green cycle.
- Perform one bounded emulator timing check for an English daily session; do not run the full Flutter suite because no Dart files should change.
