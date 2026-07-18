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
