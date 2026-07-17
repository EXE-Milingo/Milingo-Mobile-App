# Vocabulary Detail Pronunciation Button Design

## Goal

Add a pronunciation control to the deck vocabulary detail screen. Tapping it speaks the currently displayed vocabulary term in that entry's saved language.

## Behavior

- Speak `FlashcardEntry.english`, which is the target-language vocabulary term shown as the large heading.
- Select the TTS locale from `FlashcardEntry.langCode` through the existing `ttsLocaleForLanguageCode` helper. For example, `ja` uses `ja-JP` and `de` uses `de-DE`.
- Stop any current speech before starting the new term so repeated taps do not overlap.
- Stop speech and release screen-owned TTS activity when the vocabulary detail screen is disposed.
- Keep the control available even when the phonetic pronunciation string is empty, because TTS uses the vocabulary term rather than the phonetic text.

## UI

Place a compact speaker button in the word panel on the same row as the phonetic pronunciation. If no phonetic text exists, the row contains only the speaker button.

Match the Snap & Learn returned-word speaker control:

- `Icons.volume_up_rounded`, size 18;
- soft orange background using the existing detail-screen soft accent color;
- orange foreground using the existing detail-screen accent color;
- 8 logical pixels of internal padding;
- 10 logical pixel corner radius;
- semantic label and tooltip `Phát âm`.

The existing save-word and save-deck controls remain unchanged.

## State and Error Handling

Convert `VocabDetailScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` so the screen owns one `FlutterTts` instance. Initialize its speech rate and volume once, and stop it in `dispose`.

If speaking fails, keep the screen usable and show a short Vietnamese `SnackBar`. No new Riverpod state or package is needed because pronunciation is temporary screen-local behavior.

## Verification

- Add a focused regression test proving the speaker control exists and requests the current term with the entry language locale.
- Run the vocabulary-detail pronunciation test, formatting, and targeted static analysis only.
