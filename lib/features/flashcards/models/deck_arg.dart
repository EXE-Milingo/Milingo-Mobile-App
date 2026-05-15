import 'package:milingo/features/flashcards/models/flashcard_models.dart';

class DeckArg {
  const DeckArg({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.total,
    required this.learned,
    required this.emoji,
  });

  final String id;
  final String name;
  final String nameVi;
  final int total;
  final int learned;
  final String emoji;
}

class VocabItem {
  const VocabItem({
    required this.word,
    required this.reading,
    required this.emoji,
    this.isNew = false,
  });

  final String word;
  final String reading;
  final String emoji;
  final bool isNew;
}

class VocabDetailArg {
  const VocabDetailArg({
    required this.deckId,
    required this.deckName,
    required this.entry,
  });

  final String deckId;
  final String deckName;
  final FlashcardEntry entry;
}
