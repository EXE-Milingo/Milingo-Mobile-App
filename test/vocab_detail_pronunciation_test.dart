import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/flashcards/screens/vocab_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');

  testWidgets('speaker pronounces the current word in its saved language', (
    tester,
  ) async {
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
