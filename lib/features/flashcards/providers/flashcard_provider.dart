import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/services/storage_service.dart';
import 'package:milingo/features/auth/providers/auth_provider.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';

export 'package:milingo/features/flashcards/models/flashcard_models.dart';

// ─────────────────────────────────────────────────────────
// Map backend DeckResponse → local DeckData
// ─────────────────────────────────────────────────────────

DeckData _deckResponseToDeckData(DeckResponse r) {
  return DeckData(
    id: r.id,
    name: r.name,
    emoji: r.emoji.isEmpty ? '📚' : r.emoji,
    vocabCount: r.vocabCount,
    isDefault: r.isDefault,
    isFavorite: r.isFavorite,
  );
}

FlashcardEntry _cardResponseToEntry(CardResponse r) {
  return FlashcardEntry(
    id: r.id,
    english: r.term,
    translation: r.translation,
    pronunciation: r.pronunciation,
    partOfSpeech: r.partOfSpeech,
    langCode: r.targetLangCode,
    imageUrl: r.imageUrl,
    isFavorite: r.isFavorite,
    createdAt: r.createdAt,
    srsState: r.srsState,
    srsRepetitions: r.srsRepetitions,
    srsIntervalDays: r.srsIntervalDays,
    srsNextReviewAt: r.srsNextReviewAt,
  );
}

// ─────────────────────────────────────────────────────────
// FlashcardNotifier — AsyncNotifierProvider
// ─────────────────────────────────────────────────────────

class FlashcardNotifier extends AsyncNotifier<FlashcardState> {
  late MilingoApiService _api;

  @override
  Future<FlashcardState> build() async {
    final authUser = ref.watch(authStateProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return FlashcardState(decks: const []);
    }

    _api = ref.watch(milingoApiServiceProvider);
    return _loadDecks();
  }

  Future<FlashcardState> _loadDecks() async {
    final deckResponses = await _api.getDecks();
    final decks = deckResponses.map(_deckResponseToDeckData).toList();
    return FlashcardState(decks: decks);
  }

  /// Reload decks from the server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadDecks());
  }

  // ── Decks ──────────────────────────────────────────────

  Future<void> addDeck(String name, String emoji, {String? description}) async {
    final previousState = state;
    // Optimistic: add placeholder deck immediately
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    state = AsyncValue.data(
      previousState.value!.copyWith(
        decks: [
          ...previousState.value!.decks,
          DeckData(id: tempId, name: name, emoji: emoji),
        ],
      ),
    );

    try {
      final created = await _api.createDeck(
        name: name,
        emoji: emoji,
        description: description,
      );
      // Replace temp with real server deck
      final newDecks = state.value!.decks.map((d) {
        return d.id == tempId ? _deckResponseToDeckData(created) : d;
      }).toList();
      state = AsyncValue.data(state.value!.copyWith(decks: newDecks));
    } catch (e) {
      // Rollback on error
      state = previousState;
      rethrow;
    }
  }

  Future<void> updateDeck(
    String deckId, {
    String? name,
    String? emoji,
    String? description,
  }) async {
    final previousState = state;
    // Optimistic update
    final updatedDecks = state.value!.decks.map((d) {
      if (d.id != deckId) return d;
      return d.copyWith(
        name: name ?? d.name,
        emoji: emoji ?? d.emoji,
      );
    }).toList();
    state = AsyncValue.data(state.value!.copyWith(decks: updatedDecks));

    try {
      await _api.updateDeck(deckId,
          name: name, emoji: emoji, description: description);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> deleteDeck(String deckId) async {
    final previousState = state;
    // Optimistic remove
    final filtered = state.value!.decks.where((d) => d.id != deckId).toList();
    state = AsyncValue.data(state.value!.copyWith(decks: filtered));

    try {
      await _api.deleteDeck(deckId);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> setDeckFavorite(String deckId, bool isFavorite) async {
    final previousState = state;
    final current = state.valueOrNull;
    if (current == null) return;

    final optimisticDecks = current.decks.map((d) {
      return d.id == deckId ? d.copyWith(isFavorite: isFavorite) : d;
    }).toList();
    state = AsyncValue.data(current.copyWith(decks: optimisticDecks));

    try {
      final updated =
          await _api.setDeckFavorite(deckId, isFavorite: isFavorite);
      final latest = state.valueOrNull;
      if (latest == null) return;

      final serverDecks = latest.decks.map((d) {
        if (d.id != deckId) return d;
        return d.copyWith(
          name: updated.name,
          emoji: updated.emoji.isEmpty ? d.emoji : updated.emoji,
          vocabCount: updated.vocabCount,
          isDefault: updated.isDefault,
          isFavorite: updated.isFavorite,
        );
      }).toList();
      state = AsyncValue.data(latest.copyWith(decks: serverDecks));
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  // ── Cards ──────────────────────────────────────────────

  /// Load cards for a deck from the backend and merge them in.
  Future<void> loadCardsForDeck(String deckId) async {
    try {
      final cards = await _api.getCards(deckId);
      final entries = cards.map(_cardResponseToEntry).toList();
      final current = state.valueOrNull;
      if (current == null) return;

      final updatedDecks = current.decks.map((d) {
        return d.id == deckId
            ? d.copyWith(cards: entries, vocabCount: entries.length)
            : d;
      }).toList();
      state = AsyncValue.data(current.copyWith(decks: updatedDecks));
    } catch (_) {
      // Non-fatal — deck list still shows; cards just won't load
    }
  }

  Future<void> loadCardsForAllDecks() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final decksToLoad = current.decks
        .where((deck) => deck.cards.isEmpty && deck.total > 0)
        .toList();
    if (decksToLoad.isEmpty) return;

    final loadedEntries = await Future.wait(
      decksToLoad.map((deck) async {
        try {
          final cards = await _api.getCards(deck.id);
          return MapEntry(deck.id, cards.map(_cardResponseToEntry).toList());
        } catch (_) {
          return MapEntry(deck.id, <FlashcardEntry>[]);
        }
      }),
    );

    final cardsByDeck = {
      for (final entry in loadedEntries) entry.key: entry.value,
    };
    final latest = state.valueOrNull;
    if (latest == null) return;

    final updatedDecks = latest.decks.map((deck) {
      final cards = cardsByDeck[deck.id];
      if (cards == null) return deck;
      return deck.copyWith(cards: cards, vocabCount: cards.length);
    }).toList();

    state = AsyncValue.data(latest.copyWith(decks: updatedDecks));
  }

  /// Returns true if added, false if already exists in that deck.
  Future<bool> addCardToDeck(
    String deckId,
    FlashcardEntry card, {
    String sourceLangCode = 'vi',
    String? sourceVocabId,
  }) async {
    final currentDeck = state.value?.decks.firstWhere(
      (d) => d.id == deckId,
      orElse: () => DeckData(id: '', name: '', emoji: ''),
    );
    if (currentDeck == null || currentDeck.id.isEmpty) return false;

    final alreadyExists = currentDeck.cards.any(
      (c) =>
          c.english.toLowerCase() == card.english.toLowerCase() &&
          c.langCode == card.langCode,
    );
    if (alreadyExists) return false;

    final previousState = state;
    var cardToSave = card;
    var imageUrl = card.imageUrl;

    if ((imageUrl == null || imageUrl.isEmpty) &&
        card.objectImageBase64 != null &&
        card.objectImageBase64!.isNotEmpty) {
      final uploadedUrl =
          await ref.read(storageServiceProvider).uploadCroppedObjectImage(
                base64Image: card.objectImageBase64!,
                keyword: card.english,
              );

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Không thể lưu ảnh. Vui lòng thử lại.');
      }

      imageUrl = uploadedUrl;
      cardToSave = card.copyWith(imageUrl: uploadedUrl);
    }

    // Optimistic add
    final updatedDecks = state.value!.decks.map((d) {
      if (d.id != deckId) return d;
      return d.copyWith(
        cards: [...d.cards, cardToSave],
        vocabCount: d.vocabCount + 1,
      );
    }).toList();
    state = AsyncValue.data(state.value!.copyWith(decks: updatedDecks));

    try {
      var created = await _createCardOnServer(
        deckId: deckId,
        card: card,
        sourceLangCode: sourceLangCode,
        sourceVocabId: sourceVocabId,
        imageUrl: imageUrl,
      );

      if ((created.imageUrl == null || created.imageUrl!.isEmpty) &&
          imageUrl != null &&
          imageUrl.isNotEmpty) {
        created = created.copyWithImageUrl(imageUrl);
      }

      // Replace temp card with server card (real id)
      final serverEntry = FlashcardEntry(
        id: created.id,
        english: created.term,
        translation: created.translation,
        pronunciation: created.pronunciation,
        partOfSpeech: created.partOfSpeech,
        langCode: created.targetLangCode,
        imageUrl: created.imageUrl ?? imageUrl,
        isFavorite: created.isFavorite,
        srsState: created.srsState,
        srsRepetitions: created.srsRepetitions,
        srsIntervalDays: created.srsIntervalDays,
        srsNextReviewAt: created.srsNextReviewAt,
      );
      final finalDecks = state.value!.decks.map((d) {
        if (d.id != deckId) return d;
        final cards =
            d.cards.map((c) => c.id == card.id ? serverEntry : c).toList();
        return d.copyWith(cards: cards);
      }).toList();
      state = AsyncValue.data(state.value!.copyWith(decks: finalDecks));
      return true;
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<CardResponse> _createCardOnServer({
    required String deckId,
    required FlashcardEntry card,
    required String sourceLangCode,
    required String? sourceVocabId,
    required String? imageUrl,
  }) async {
    try {
      return await _api.addCard(
        deckId,
        term: card.english,
        translation: card.translation,
        pronunciation: card.pronunciation,
        partOfSpeech: card.partOfSpeech,
        sourceLangCode: sourceLangCode,
        targetLangCode: card.langCode,
        sourceVocabId: sourceVocabId,
        imageUrl: imageUrl,
      );
    } on MilingoApiException {
      if (imageUrl == null || imageUrl.isEmpty) rethrow;

      return _api.addCard(
        deckId,
        term: card.english,
        translation: card.translation,
        pronunciation: card.pronunciation,
        partOfSpeech: card.partOfSpeech,
        sourceLangCode: sourceLangCode,
        targetLangCode: card.langCode,
        sourceVocabId: sourceVocabId,
      );
    }
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    final previousState = state;
    // Optimistic remove
    final updatedDecks = state.value!.decks.map((d) {
      if (d.id != deckId) return d;
      final cards = d.cards.where((c) => c.id != cardId).toList();
      return d.copyWith(cards: cards, vocabCount: cards.length);
    }).toList();
    state = AsyncValue.data(state.value!.copyWith(decks: updatedDecks));

    try {
      await _api.deleteCard(deckId, cardId);
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  // ── Query helpers (kept for UI backward compat) ────────

  Future<void> setCardFavorite(
    String deckId,
    String cardId,
    bool isFavorite,
  ) async {
    final previousState = state;
    final current = state.valueOrNull;
    if (current == null) return;

    final optimisticDecks = current.decks.map((d) {
      if (d.id != deckId) return d;
      return d.copyWith(
        cards: d.cards.map((c) {
          return c.id == cardId ? c.copyWith(isFavorite: isFavorite) : c;
        }).toList(),
      );
    }).toList();
    state = AsyncValue.data(current.copyWith(decks: optimisticDecks));

    try {
      final updated = await _api.setCardFavorite(
        deckId,
        cardId,
        isFavorite: isFavorite,
      );
      final serverEntry = _cardResponseToEntry(updated);
      final latest = state.valueOrNull;
      if (latest == null) return;

      final serverDecks = latest.decks.map((d) {
        if (d.id != deckId) return d;
        return d.copyWith(
          cards: d.cards.map((c) {
            if (c.id != cardId) return c;
            return serverEntry.copyWith(
              imageUrl: serverEntry.imageUrl ?? c.imageUrl,
              objectImageBase64: c.objectImageBase64,
            );
          }).toList(),
        );
      }).toList();
      state = AsyncValue.data(latest.copyWith(decks: serverDecks));
    } catch (e) {
      state = previousState;
      rethrow;
    }
  }

  Future<int> deleteCardsEverywhere(String english, String langCode) async {
    await loadCardsForAllDecks();
    final current = state.valueOrNull;
    if (current == null) return 0;

    final normalizedTerm = english.trim().toLowerCase();
    final normalizedLang = langCode.trim().toLowerCase();
    final matches = <MapEntry<String, String>>[];

    for (final deck in current.decks) {
      for (final card in deck.cards) {
        final sameTerm = card.english.trim().toLowerCase() == normalizedTerm;
        final sameLang = card.langCode.trim().toLowerCase() == normalizedLang;
        if (sameTerm && sameLang) {
          matches.add(MapEntry(deck.id, card.id));
        }
      }
    }

    for (final match in matches) {
      await deleteCard(match.key, match.value);
    }

    return matches.length;
  }

  bool isCardSavedAnywhere(String english, String langCode) {
    return state.value?.decks.any((d) => d.cards.any(
              (c) =>
                  c.english.toLowerCase() == english.toLowerCase() &&
                  c.langCode == langCode,
            )) ??
        false;
  }
}

// ─────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────

final flashcardProvider =
    AsyncNotifierProvider<FlashcardNotifier, FlashcardState>(
  FlashcardNotifier.new,
);

// Convenience sync accessor — returns empty state while loading.
// Existing widgets that call `ref.watch(flashcardProvider)` need
// to be updated to handle AsyncValue; use this shim for a softer
// migration where needed.
final flashcardStateProvider = Provider<FlashcardState>((ref) {
  return ref.watch(flashcardProvider).valueOrNull ??
      FlashcardState(decks: const []);
});
