import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────
// Models
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

// ─────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────

class FlashcardState {
  FlashcardState({required List<DeckData> decks})
      : decks = List.unmodifiable(decks);

  final List<DeckData> decks;

  FlashcardState copyWith({List<DeckData>? decks}) =>
      FlashcardState(decks: decks ?? List<DeckData>.from(this.decks));
}

// ─────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier()
      : super(FlashcardState(decks: [
          DeckData(id: 'favorites', name: 'Yêu thích', emoji: '⭐'),
          DeckData(id: 'nouns', name: 'Danh từ', emoji: '📦'),
          DeckData(id: 'verbs', name: 'Động từ', emoji: '⚡'),
          DeckData(id: 'adjectives', name: 'Tính từ', emoji: '🎨'),
        ]));

  void addDeck(String name, String emoji) {
    final id =
        '${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(
      decks: [...state.decks, DeckData(id: id, name: name, emoji: emoji)],
    );
  }

  /// Returns true if added, false if the card already exists in this deck.
  bool addCardToDeck(String deckId, FlashcardEntry card) {
    final idx = state.decks.indexWhere((d) => d.id == deckId);
    if (idx == -1) return false;
    final deck = state.decks[idx];
    final alreadyExists = deck.cards.any(
      (c) =>
          c.english.toLowerCase() == card.english.toLowerCase() &&
          c.langCode == card.langCode,
    );
    if (alreadyExists) return false;
    final updatedCards = [...deck.cards, card];
    final updatedDecks = [...state.decks];
    updatedDecks[idx] = deck.copyWith(cards: updatedCards);
    state = state.copyWith(decks: updatedDecks);
    return true;
  }

  bool isCardSavedAnywhere(String english, String langCode) {
    return state.decks.any((d) => d.cards.any(
          (c) =>
              c.english.toLowerCase() == english.toLowerCase() &&
              c.langCode == langCode,
        ));
  }
}

// ─────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────

final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>(
  (ref) => FlashcardNotifier(),
);
