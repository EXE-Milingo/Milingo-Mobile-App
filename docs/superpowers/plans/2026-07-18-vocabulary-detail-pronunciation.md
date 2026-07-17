# Vocabulary Detail Pronunciation Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Snap-style speaker button to vocabulary details that pronounces the current target-language word with the correct locale.

**Architecture:** Keep pronunciation temporary and screen-local by giving `VocabDetailScreen` one `FlutterTts` instance with explicit initialization and disposal. The word panel receives a callback and renders a compact control matching Snap & Learn's returned-word action button; existing `ttsLocaleForLanguageCode` performs locale selection.

**Tech Stack:** Flutter, Riverpod, `flutter_tts`, Flutter widget tests, platform method-channel mocks.

## Global Constraints

- Speak `FlashcardEntry.english`, never the romanized pronunciation or Vietnamese translation.
- Use `ttsLocaleForLanguageCode(entry.langCode)` so `ja` maps to `ja-JP`, `de` maps to `de-DE`, and other supported languages keep their existing mappings.
- Match Snap & Learn's speaker styling: 18px rounded volume icon, soft-orange background, orange foreground, 8px padding, 10px radius.
- Keep the button visible even when `entry.pronunciation` is empty.
- Stop active speech before speaking and when the screen is disposed.
- Do not add packages or change flashcard/deck mutation logic.
- Preserve the user's uncommitted `lib/core/constants/app_constants.dart` and `pubspec.yaml` changes.

---

### Task 1: Add Target-Language Pronunciation to Vocabulary Details

**Files:**
- Modify: `lib/features/flashcards/screens/vocab_detail_screen.dart`
- Create: `test/vocab_detail_pronunciation_test.dart`

**Interfaces:**
- Consumes: `FlashcardEntry.english`, `FlashcardEntry.langCode`, `ttsLocaleForLanguageCode(String?)`, and the `flutter_tts` channel named `flutter_tts`.
- Produces: a `Phát âm` tooltip/semantic button and `_speak(FlashcardEntry entry) -> Future<void>` behavior local to `VocabDetailScreen`.

- [ ] **Step 1: Write the failing widget test**

Create `test/vocab_detail_pronunciation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/flashcards/screens/vocab_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');

  testWidgets('speaker pronounces the current word in its saved language',
      (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 1;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    const entry = FlashcardEntry(
      id: 'dog-ja',
      english: '犬',
      translation: 'con chó',
      pronunciation: 'inu',
      langCode: 'ja',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flashcardProvider.overrideWith(_EmptyFlashcardNotifier.new),
        ],
        child: const MaterialApp(
          home: VocabDetailScreen(
            arg: VocabDetailArg(
              deckId: '',
              deckName: 'Đồ vật',
              entry: entry,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    calls.clear();

    await tester.tap(find.byTooltip('Phát âm'));
    await tester.pump();

    expect(
      calls.map((call) => call.method),
      containsAllInOrder(['setLanguage', 'stop', 'speak']),
    );
    expect(
      calls.firstWhere((call) => call.method == 'setLanguage').arguments,
      'ja-JP',
    );
    final speakArguments =
        calls.firstWhere((call) => call.method == 'speak').arguments;
    expect(
      speakArguments is Map ? speakArguments['text'] : speakArguments,
      '犬',
    );
  });
}

class _EmptyFlashcardNotifier extends FlashcardNotifier {
  @override
  Future<FlashcardState> build() async {
    return FlashcardState(decks: const []);
  }
}
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
flutter test test/vocab_detail_pronunciation_test.dart
```

Expected: FAIL because `find.byTooltip('Phát âm')` finds no widget.

- [ ] **Step 3: Add screen-owned TTS lifecycle and speech behavior**

In `vocab_detail_screen.dart`, add imports:

```dart
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/shared/utils/tts_locale.dart';
```

Convert the screen shell to a `ConsumerStatefulWidget` and replace existing `arg` reads inside its state with `widget.arg`:

```dart
class VocabDetailScreen extends ConsumerStatefulWidget {
  const VocabDetailScreen({required this.arg, super.key});

  final VocabDetailArg arg;

  @override
  ConsumerState<VocabDetailScreen> createState() =>
      _VocabDetailScreenState();
}

class _VocabDetailScreenState extends ConsumerState<VocabDetailScreen> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    unawaited(_initializeTts());
  }

  Future<void> _initializeTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
    } catch (_) {
      // A failed optional initialization must not block vocabulary details.
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(FlashcardEntry entry) async {
    final term = entry.english.trim();
    if (term.isEmpty) return;

    try {
      await _tts.setLanguage(ttsLocaleForLanguageCode(entry.langCode));
      await _tts.stop();
      await _tts.speak(term);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể phát âm từ này. Vui lòng thử lại.'),
        ),
      );
    }
  }
```

Pass the callback when building the word panel:

```dart
_WordPanel(
  entry: entry,
  deckFavorite: deckFavorite,
  onSpeak: () => _speak(entry),
  onWordFavorite: widget.arg.deckId.isEmpty
      ? null
      : () => _toggleCardFavorite(context, ref, entry),
  onDeckFavorite: deck == null
      ? null
      : () => _toggleDeckFavorite(context, ref, deck),
),
```

- [ ] **Step 4: Render the Snap-style speaker control**

Add `required VoidCallback onSpeak` to `_WordPanel`, then replace the conditional pronunciation-only block with:

```dart
const SizedBox(height: 10),
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (entry.pronunciation.trim().isNotEmpty) ...[
      Flexible(
        child: Text(
          entry.pronunciation,
          softWrap: true,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ],
    Tooltip(
      message: 'Phát âm',
      child: Semantics(
        button: true,
        label: 'Phát âm',
        child: Material(
          color: _kSoft,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onSpeak,
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.volume_up_rounded,
                color: _kAccent,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    ),
  ],
),
```

- [ ] **Step 5: Run the focused test and verify GREEN**

Run:

```powershell
flutter test test/vocab_detail_pronunciation_test.dart
```

Expected: PASS with one test and no platform-channel exception.

- [ ] **Step 6: Run bounded verification**

Run:

```powershell
dart format --output=none --set-exit-if-changed lib/features/flashcards/screens/vocab_detail_screen.dart test/vocab_detail_pronunciation_test.dart
dart analyze lib/features/flashcards/screens/vocab_detail_screen.dart
dart analyze test/vocab_detail_pronunciation_test.dart
flutter test test/vocab_detail_pronunciation_test.dart test/tts_locale_test.dart
```

Expected: both files are format-clean, both targeted analyses report no issues, and all focused tests pass.

- [ ] **Step 7: Commit only the pronunciation change**

```powershell
git add lib/features/flashcards/screens/vocab_detail_screen.dart test/vocab_detail_pronunciation_test.dart
git commit -m "feat: add vocabulary pronunciation control"
```

Confirm `lib/core/constants/app_constants.dart` and `pubspec.yaml` remain unstaged.
