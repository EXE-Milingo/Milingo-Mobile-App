# Snap Related-Word Actions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the enlarged related-word bubbles on the Snap & Learn result screen pronounce and save their own vocabulary.

**Architecture:** Keep temporary pronunciation inside the existing screen-owned `FlutterTts` lifecycle and keep persistent deck mutations in `flashcardProvider` through `SaveFlashcardSheet`. Reuse the existing `VocabBubble` as the single interactive halo component, and add one pure mapper from `RelatedWord` to `FlashcardEntry` so the saved payload is independently testable.

**Tech Stack:** Flutter, Dart, Riverpod, `flutter_tts`, `flutter_test`.

## Global Constraints

- Each bubble is exactly 120 x 104 logical pixels.
- Speaker and bookmark controls are separate 40 x 40 logical-pixel tap targets.
- Bubble text and unused surface do not trigger an action.
- TTS must use `targetSpeechTextForLanguage` and `ttsLocaleForLanguageCode` through the screen's existing `_speak` flow.
- Saving must use `SaveFlashcardSheet` and `flashcardProvider`; do not add a provider or dependency.
- Fallback vocabulary items from the same scan must receive the same actions.
- Do not change capture, quota, primary-word, example-sentence, or navigation behavior.

---

### Task 1: Enlarge the bubble and expose independent action controls

**Files:**
- Modify: `lib/features/snap_and_learn/widgets/vocab_bubble.dart`
- Create: `test/vocab_bubble_test.dart`

**Interfaces:**
- Consumes: existing `VocabBubble({english, translation, onSpeak, onSave})` constructor.
- Produces: the same constructor API, a fixed 120 x 104 layout, and controls discoverable by tooltips `Phát âm` and `Lưu vào bộ thẻ`.

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/snap_and_learn/widgets/vocab_bubble.dart';

void main() {
  testWidgets('related word actions are large and independent', (tester) async {
    var speakCount = 0;
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VocabBubble(
              english: 'der Hund',
              translation: 'con chó',
              onSpeak: () => speakCount++,
              onSave: () => saveCount++,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(VocabBubble)), const Size(120, 104));

    final bubbleRect = tester.getRect(find.byType(VocabBubble));
    await tester.tapAt(bubbleRect.topCenter + const Offset(0, 18));
    await tester.pump();
    expect(speakCount, 0);
    expect(saveCount, 0);

    await tester.tap(find.byTooltip('Phát âm'));
    await tester.pump();
    expect(speakCount, 1);
    expect(saveCount, 0);

    await tester.tap(find.byTooltip('Lưu vào bộ thẻ'));
    await tester.pump();
    expect(speakCount, 1);
    expect(saveCount, 1);
  });
}
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
flutter test test/vocab_bubble_test.dart
```

Expected: FAIL because the current bubble is not 120 x 104 and has no tooltip-addressable action buttons.

- [ ] **Step 3: Implement the fixed-size interactive bubble**

Replace `vocab_bubble.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

/// Interactive vocabulary bubble displayed around a detected object.
class VocabBubble extends StatelessWidget {
  const VocabBubble({
    required this.english,
    required this.translation,
    required this.onSpeak,
    required this.onSave,
    super.key,
  });

  final String english;
  final String translation;
  final VoidCallback onSpeak;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            english.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            translation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF605851),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Phát âm',
                onPressed: onSpeak,
                constraints:
                    const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.10),
                ),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Lưu vào bộ thẻ',
                onPressed: onSave,
                constraints:
                    const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.10),
                ),
                icon: const Icon(
                  Icons.bookmark_add_rounded,
                  color: AppTheme.primaryColor,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test and verify GREEN**

Run:

```powershell
flutter test test/vocab_bubble_test.dart
```

Expected: PASS with one test.

- [ ] **Step 5: Commit the bubble behavior**

```powershell
git add lib/features/snap_and_learn/widgets/vocab_bubble.dart test/vocab_bubble_test.dart
git commit -m "feat: add related-word bubble actions"
```

---

### Task 2: Map related words and wire both result-screen actions

**Files:**
- Create: `lib/features/snap_and_learn/models/related_word_flashcard_mapper.dart`
- Modify: `lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`
- Create: `test/related_word_flashcard_mapper_test.dart`

**Interfaces:**
- Consumes: `RelatedWord`, selected language code, existing `_speak`, `_speechTextForRelatedWord`, `_showSaveToFlashcard`, and `VocabBubble`.
- Produces: `FlashcardEntry flashcardEntryForRelatedWord({required RelatedWord word, required String langCode})`.

- [ ] **Step 1: Write the failing mapper test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/features/snap_and_learn/models/related_word_flashcard_mapper.dart';

void main() {
  test('maps a related word to flashcard data in the selected language', () {
    const word = RelatedWord(
      english: 'der Hund',
      translation: 'con chó',
      pronunciation: 'hʊnt',
    );

    final entry = flashcardEntryForRelatedWord(word: word, langCode: 'de');

    expect(entry.id, 'der Hund_de');
    expect(entry.english, 'der Hund');
    expect(entry.translation, 'con chó');
    expect(entry.pronunciation, 'hʊnt');
    expect(entry.langCode, 'de');
  });
}
```

- [ ] **Step 2: Run the mapper test and verify RED**

Run:

```powershell
flutter test test/related_word_flashcard_mapper_test.dart
```

Expected: FAIL because `related_word_flashcard_mapper.dart` and `flashcardEntryForRelatedWord` do not exist.

- [ ] **Step 3: Add the minimal pure mapper**

Create the file with this implementation:

```dart
import 'package:milingo/features/flashcards/models/flashcard_models.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

FlashcardEntry flashcardEntryForRelatedWord({
  required RelatedWord word,
  required String langCode,
}) {
  return FlashcardEntry(
    id: '${word.english}_$langCode',
    english: word.english,
    translation: word.translation,
    pronunciation: word.pronunciation,
    langCode: langCode,
  );
}
```

- [ ] **Step 4: Run the mapper test and verify GREEN**

Run:

```powershell
flutter test test/related_word_flashcard_mapper_test.dart
```

Expected: PASS with one test.

- [ ] **Step 5: Wire the mapper and interactive bubble into the current result halo**

In `snap_and_learn_screen.dart`:

1. Import `related_word_flashcard_mapper.dart`.
2. Change `_kHaloBubbleWidth` to `120.0` and `_kHaloBubbleHeight` to `104.0` so collision placement matches the rendered widget.
3. Build `haloWords` as `List<RelatedWord>`. Copy up to four `result.relatedWords`; when empty, convert other scan items using their keyword, translation, and pronunciation:

```dart
final haloWords = <RelatedWord>[...result.relatedWords.take(4)];
if (haloWords.isEmpty) {
  for (final item in snap.allVocabItems) {
    if (item.keyword == result.keyword) continue;
    haloWords.add(
      RelatedWord(
        english: item.keyword,
        translation: item.translation,
        pronunciation: item.pronunciation,
      ),
    );
    if (haloWords.length == 4) break;
  }
}
```

4. Replace `_HaloWordBubble` at each positioned halo with:

```dart
VocabBubble(
  english: haloWords[i].english,
  translation: haloWords[i].translation,
  onSpeak: () => _speak(
    _speechTextForRelatedWord(haloWords[i], snap.selectedLanguage),
    snap.selectedLanguage,
  ),
  onSave: () => _showSaveToFlashcard(
    context,
    flashcardEntryForRelatedWord(
      word: haloWords[i],
      langCode: snap.selectedLanguage,
    ),
  ),
)
```

5. Update the older `_buildVocabBubbles` save callback to call `flashcardEntryForRelatedWord` instead of constructing the same `FlashcardEntry` inline.
6. Delete the now-unused private `_HaloWordBubble` class.

- [ ] **Step 6: Run both focused tests**

Run:

```powershell
flutter test test/vocab_bubble_test.dart test/related_word_flashcard_mapper_test.dart
```

Expected: PASS with two tests and no exceptions.

- [ ] **Step 7: Commit the result-screen wiring**

```powershell
git add lib/features/snap_and_learn/models/related_word_flashcard_mapper.dart lib/features/snap_and_learn/screens/snap_and_learn_screen.dart test/related_word_flashcard_mapper_test.dart
git commit -m "feat: enable snap related-word actions"
```

---

### Task 3: Verify the Flutter change

**Files:**
- Verify: `lib/features/snap_and_learn/widgets/vocab_bubble.dart`
- Verify: `lib/features/snap_and_learn/models/related_word_flashcard_mapper.dart`
- Verify: `lib/features/snap_and_learn/screens/snap_and_learn_screen.dart`
- Verify: `test/vocab_bubble_test.dart`
- Verify: `test/related_word_flashcard_mapper_test.dart`

**Interfaces:**
- Consumes: the completed interactive bubble and screen wiring.
- Produces: fresh formatting, analyzer, and regression-test evidence.

- [ ] **Step 1: Format and ensure no formatting diff remains**

Run:

```powershell
dart format lib test
dart format --output=none --set-exit-if-changed lib test
```

Expected: both commands exit 0; the second reports no changed files.

- [ ] **Step 2: Run static analysis**

Run:

```powershell
flutter analyze
```

Expected: exit 0 with `No issues found!`.

- [ ] **Step 3: Run the Flutter test suite once**

Run:

```powershell
flutter test
```

Expected: exit 0 with all tests passing.

- [ ] **Step 4: Inspect the final diff**

Run:

```powershell
git status --short
git diff --check
git diff --stat HEAD~2
```

Expected: only the planned files are present, `git diff --check` is empty, and no dependency or generated file changed.
