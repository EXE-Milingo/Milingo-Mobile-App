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
    this.isFavorite = false,
    this.srsState = 'new',
    this.srsRepetitions = 0,
    this.srsIntervalDays = 0,
    this.srsNextReviewAt,
  });

  final String id;
  final String english;
  final String translation;
  final String pronunciation;
  final String partOfSpeech;
  final String langCode;
  final String? imageUrl;
  final String? objectImageBase64;
  final bool isFavorite;
  final String srsState;
  final int srsRepetitions;
  final int srsIntervalDays;
  final String? srsNextReviewAt;

  bool get isNewForStudy => srsState == 'new' || srsRepetitions == 0;
  bool get isLearning => srsState == 'learning';
  bool get isReviewing => srsState == 'review';
  bool get isMastered => srsState == 'mastered';

  FlashcardEntry copyWith({
    String? id,
    String? english,
    String? translation,
    String? pronunciation,
    String? partOfSpeech,
    String? langCode,
    String? imageUrl,
    String? objectImageBase64,
    bool? isFavorite,
    String? srsState,
    int? srsRepetitions,
    int? srsIntervalDays,
    String? srsNextReviewAt,
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
      isFavorite: isFavorite ?? this.isFavorite,
      srsState: srsState ?? this.srsState,
      srsRepetitions: srsRepetitions ?? this.srsRepetitions,
      srsIntervalDays: srsIntervalDays ?? this.srsIntervalDays,
      srsNextReviewAt: srsNextReviewAt ?? this.srsNextReviewAt,
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
    this.isFavorite = false,
  }) : cards = List.unmodifiable(cards ?? const []);

  final String id;
  final String name;
  final String emoji;
  final List<FlashcardEntry> cards;
  final int vocabCount;

  /// True for decks that the backend marks as default (cannot be deleted).
  final bool isDefault;
  final bool isFavorite;

  int get total => cards.isEmpty ? vocabCount : cards.length;

  DeckData copyWith({
    String? name,
    String? emoji,
    List<FlashcardEntry>? cards,
    int? vocabCount,
    bool? isDefault,
    bool? isFavorite,
  }) =>
      DeckData(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        cards: cards ?? List<FlashcardEntry>.from(this.cards),
        vocabCount: vocabCount ?? this.vocabCount,
        isDefault: isDefault ?? this.isDefault,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

class FlashcardState {
  FlashcardState({required List<DeckData> decks})
      : decks = List.unmodifiable(decks);

  final List<DeckData> decks;

  FlashcardState copyWith({List<DeckData>? decks}) =>
      FlashcardState(decks: decks ?? List<DeckData>.from(this.decks));
}
