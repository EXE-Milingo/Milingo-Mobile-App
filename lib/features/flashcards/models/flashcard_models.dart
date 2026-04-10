// ─────────────────────────────────────────────────────────
// Flashcard Models
// ─────────────────────────────────────────────────────────

class FlashcardEntry {
  const FlashcardEntry({
    required this.id,
    required this.english,
    required this.translation,
    required this.pronunciation,
    this.partOfSpeech = '',
    this.langCode = 'en',
  });

  final String id;
  final String english;
  final String translation;
  final String pronunciation;
  final String partOfSpeech;
  final String langCode;
}

class DeckData {
  DeckData({
    required this.id,
    required this.name,
    required this.emoji,
    List<FlashcardEntry>? cards,
  }) : cards = List.unmodifiable(cards ?? const []);

  final String id;
  final String name;
  final String emoji;
  final List<FlashcardEntry> cards;

  int get total => cards.length;

  DeckData copyWith({
    String? name,
    String? emoji,
    List<FlashcardEntry>? cards,
  }) =>
      DeckData(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        cards: cards ?? List<FlashcardEntry>.from(this.cards),
      );
}

class FlashcardState {
  FlashcardState({required List<DeckData> decks})
      : decks = List.unmodifiable(decks);

  final List<DeckData> decks;

  FlashcardState copyWith({List<DeckData>? decks}) =>
      FlashcardState(decks: decks ?? List<DeckData>.from(this.decks));
}
