# Snap Related-Word Actions Design

## Goal

Make every recommended word surrounding the Snap & Learn result image directly useful. A user can pronounce a related word in the selected learning language or save it to one of their flashcard decks.

## Interaction and Layout

- Replace the display-only result halo bubble with an interactive related-word bubble that preserves the existing white, rounded visual style.
- Increase each bubble from 92 x 70 logical pixels to 120 x 104 logical pixels. The existing halo placement algorithm continues positioning bubbles around the detected object and avoiding overlap where space permits.
- Keep the word and Vietnamese translation as display-only content.
- Add a bottom action row containing two distinct 40 x 40 logical-pixel controls:
  - speaker icon with tooltip and semantic label `Phát âm`;
  - bookmark-add icon with tooltip and semantic label `Lưu vào bộ thẻ`.
- Tapping the text or unused bubble surface performs no action, preventing accidental saves.

## Data and Behavior

The result screen supplies both callbacks to each bubble.

For a backend `RelatedWord`:

- pronunciation uses `targetSpeechTextForLanguage` to choose the target-language term and uses `ttsLocaleForLanguageCode` for the selected language locale;
- saving creates a `FlashcardEntry` containing the word, translation, pronunciation, and selected language code;
- the existing `SaveFlashcardSheet` handles deck selection, duplicate detection, loading feedback, errors, and the final mutation through `flashcardProvider`.

When related words are unavailable, the current fallback vocabulary items from the same scan remain visible. Each fallback bubble receives equivalent pronunciation and save actions using its complete `MilingoResult` data.

## State Management and Lifecycle

- Do not add a Riverpod provider for temporary button interactions.
- TTS remains owned by `SnapAndLearnScreen` and is stopped during disposal, matching its existing lifecycle.
- All persistent flashcard mutations remain in `FlashcardNotifier`; the screen and bubble only open the existing save sheet with an immutable `FlashcardEntry`.
- The existing auto-disposed Snap state and scan flow are unchanged.

## Error Handling

- Ignore pronunciation requests whose selected speech text is empty, matching the current TTS helper behavior.
- Existing save-sheet busy state prevents duplicate submissions and reports API failures without closing the result screen.
- No interaction changes are made to the primary result word, example sentences, image capture, quota, or navigation flows.

## Focused Verification

- Add a widget test proving the speaker and bookmark controls are independently tappable and invoke only their respective callbacks.
- Add a focused test for mapping a related word into the flashcard data passed to the save flow, including the selected language and pronunciation.
- Run the new focused tests, formatting, `flutter analyze`, and the Flutter test suite once as the final regression check. No emulator or broad manual test matrix is required.
