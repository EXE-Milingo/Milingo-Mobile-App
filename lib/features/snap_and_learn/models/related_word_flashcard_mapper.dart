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
