import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';
import 'package:milingo/features/snap_and_learn/providers/snap_provider.dart';
import 'package:milingo/features/snap_and_learn/screens/snap_and_learn_screen.dart';
import 'package:milingo/features/snap_and_learn/widgets/save_flashcard_sheet.dart';
import 'package:milingo/features/snap_and_learn/widgets/vocab_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ttsChannel = MethodChannel('flutter_tts');
  late List<MethodCall> ttsCalls;

  setUp(() {
    ttsCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          ttsCalls.add(call);
          return 1;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  testWidgets('result halo pronounces a related word in the target language', (
    tester,
  ) async {
    await _pumpResultScreen(tester);
    ttsCalls.clear();

    expect(find.byType(VocabBubble), findsOneWidget);
    await tester.tap(find.byTooltip('Phát âm'));
    await tester.pump();

    expect(
      ttsCalls.map((call) => call.method),
      containsAllInOrder(['setLanguage', 'stop', 'speak']),
    );
    expect(
      ttsCalls.firstWhere((call) => call.method == 'setLanguage').arguments,
      'de-DE',
    );
    final speakArguments =
        ttsCalls.firstWhere((call) => call.method == 'speak').arguments;
    expect(
      speakArguments is Map ? speakArguments['text'] : speakArguments,
      'der Hund',
    );
  });

  testWidgets('result halo opens the save sheet for its related word', (
    tester,
  ) async {
    await _pumpResultScreen(tester);

    await tester.tap(find.byTooltip('Lưu vào bộ thẻ'));
    await tester.pumpAndSettle();

    final sheet = tester.widget<SaveFlashcardSheet>(
      find.byType(SaveFlashcardSheet),
    );
    expect(sheet.entry.english, 'der Hund');
    expect(sheet.entry.translation, 'con chó');
    expect(sheet.entry.pronunciation, 'hʊnt');
    expect(sheet.entry.langCode, 'de');
  });
}

Future<void> _pumpResultScreen(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        snapControllerProvider.overrideWith(_ResultSnapController.new),
        flashcardProvider.overrideWith(_EmptyFlashcardNotifier.new),
      ],
      child: const MaterialApp(home: SnapAndLearnScreen()),
    ),
  );
  await tester.pump();
}

class _ResultSnapController extends SnapController {
  _ResultSnapController(Ref ref) : super(MilingoApiService(), ref) {
    state = SnapState(
      selectedLanguage: 'de',
      showVocabulary: true,
      result: result,
      allVocabItems: [result],
    );
  }

  static final result = MilingoResult(
    keyword: 'die Katze',
    translation: 'con mèo',
    pronunciation: 'katsə',
    partOfSpeech: 'Noun',
    sentence: 'Die Katze schläft.',
    sentenceTranslation: 'Con mèo đang ngủ.',
    relatedWords: const [
      RelatedWord(
        english: 'der Hund',
        translation: 'con chó',
        pronunciation: 'hʊnt',
      ),
    ],
  );
}

class _EmptyFlashcardNotifier extends FlashcardNotifier {
  @override
  Future<FlashcardState> build() async {
    return FlashcardState(decks: const []);
  }
}
