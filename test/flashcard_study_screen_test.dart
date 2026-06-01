import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';
import 'package:milingo/features/flashcards/screens/flashcard_study_screen.dart';

void main() {
  const cards = [
    FlashcardEntry(
      id: '1',
      english: 'bookshelf',
      translation: 'gia sach',
      pronunciation: '/book-shelf/',
      partOfSpeech: 'noun',
    ),
    FlashcardEntry(
      id: '2',
      english: 'chair',
      translation: 'cai ghe',
      pronunciation: '/chair/',
      partOfSpeech: 'noun',
    ),
  ];

  testWidgets('flips a card and advances to the next card', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlashcardStudyScreen(
          deckName: 'Do vat',
          cards: cards,
        ),
      ),
    );

    expect(find.text('bookshelf'), findsOneWidget);
    expect(find.text('gia sach'), findsNothing);

    await tester.tap(find.byType(FlashcardStudyCard));
    await tester.pumpAndSettle();

    expect(find.text('bookshelf'), findsNothing);
    expect(find.text('gia sach'), findsOneWidget);

    await tester.tap(find.byTooltip('The tiep theo'));
    await tester.pumpAndSettle();

    expect(find.text('chair'), findsOneWidget);
    expect(find.text('cai ghe'), findsNothing);
  });

  testWidgets('animates the card around the y axis while flipping',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlashcardStudyScreen(
          deckName: 'Do vat',
          cards: cards,
        ),
      ),
    );

    await tester.tap(find.byType(FlashcardStudyCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('flashcard-flip-transform')),
    );

    expect(transform.transform.storage[0], isNot(1.0));
  });
}
