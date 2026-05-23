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
    this.imageUrl,
    this.objectImageBase64,
  });

  final String id;
  final String english;
  final String translation;
  final String pronunciation;
  final String partOfSpeech;
  final String langCode;
  final String? imageUrl;
  final String? objectImageBase64;

  FlashcardEntry copyWith({
    String? id,
    String? english,
    String? translation,
    String? pronunciation,
    String? partOfSpeech,
    String? langCode,
    String? imageUrl,
    String? objectImageBase64,
  }) {
    return FlashcardEntry(
      id: id ?? this.id,
      english: english ?? this.english,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      langCode: langCode ?? this.langCode,
      imageUrl: imageUrl ?? this.imageUrl,
      objectImageBase64: objectImageBase64 ?? this.objectImageBase64,
    );
  }
}

class DeckData {
  DeckData({
    required this.id,
    required this.name,
    required this.emoji,
    List<FlashcardEntry>? cards,
    this.vocabCount = 0,
    this.isDefault = false,
  }) : cards = List.unmodifiable(cards ?? const []);

  final String id;
  final String name;
  final String emoji;
  final List<FlashcardEntry> cards;
  final int vocabCount;

  /// True for decks that the backend marks as default (cannot be deleted).
  final bool isDefault;

  int get total => cards.isEmpty ? vocabCount : cards.length;

  DeckData copyWith({
    String? name,
    String? emoji,
    List<FlashcardEntry>? cards,
    int? vocabCount,
    bool? isDefault,
  }) =>
      DeckData(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        cards: cards ?? List<FlashcardEntry>.from(this.cards),
        vocabCount: vocabCount ?? this.vocabCount,
        isDefault: isDefault ?? this.isDefault,
      );
}

class FlashcardState {
  FlashcardState({required List<DeckData> decks})
      : decks = List.unmodifiable(decks);

  final List<DeckData> decks;

  FlashcardState copyWith({List<DeckData>? decks}) =>
      FlashcardState(decks: decks ?? List<DeckData>.from(this.decks));
}
