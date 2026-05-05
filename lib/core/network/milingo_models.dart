// ─────────────────────────────────────────────────────────
// Milingo API Response Models
// Maps backend JSON shapes to Dart classes.
// ─────────────────────────────────────────────────────────

// ── Deck ─────────────────────────────────────────────────

class DeckResponse {
  const DeckResponse({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.vocabCount,
    required this.isDefault,
    required this.createdAt,
  });

  factory DeckResponse.fromJson(Map<String, dynamic> json) {
    return DeckResponse(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      emoji: (json['emoji'] ?? '📚').toString(),
      description: (json['description'] ?? '').toString(),
      vocabCount: (json['vocab_count'] as num?)?.toInt() ?? 0,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String emoji;
  final String description;
  final int vocabCount;
  final bool isDefault;
  final String createdAt;
}

// ── Card ──────────────────────────────────────────────────

class CardResponse {
  const CardResponse({
    required this.id,
    required this.term,
    required this.translation,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.sourceLangCode,
    required this.targetLangCode,
    required this.createdAt,
    this.sourceVocabId,
  });

  factory CardResponse.fromJson(Map<String, dynamic> json) {
    return CardResponse(
      id: (json['id'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      partOfSpeech: (json['part_of_speech'] ?? '').toString(),
      sourceLangCode: (json['source_lang_code'] ?? 'en').toString(),
      targetLangCode: (json['target_lang_code'] ?? 'en').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      sourceVocabId: json['source_vocab_id'] as String?,
    );
  }

  final String id;
  final String term;
  final String translation;
  final String pronunciation;
  final String partOfSpeech;
  final String sourceLangCode;
  final String targetLangCode;
  final String createdAt;
  final String? sourceVocabId;
}

// ── Snap Analysis ────────────────────────────────────────

class SnapVocabItem {
  const SnapVocabItem({
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.exampleSentence,
    this.detectionLabel,
    this.detectionConfidence,
  });

  factory SnapVocabItem.fromJson(Map<String, dynamic> json) {
    return SnapVocabItem(
      keyword: (json['keyword'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      exampleSentence: (json['example_sentence'] ?? '').toString(),
      detectionLabel: json['detection_label'] as String?,
      detectionConfidence: (json['detection_confidence'] as num?)?.toDouble(),
    );
  }

  final String keyword;
  final String translation;
  final String pronunciation;
  final String exampleSentence;
  final String? detectionLabel;
  final double? detectionConfidence;
}

class SnapAnalysisResponse {
  const SnapAnalysisResponse({
    required this.vocabItems,
    required this.coinsAwarded,
    required this.snapGroupId,
    required this.usedFallback,
  });

  factory SnapAnalysisResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['vocab_items'] as List<dynamic>? ?? [];
    final items = rawItems
        .map((e) => SnapVocabItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return SnapAnalysisResponse(
      vocabItems: items,
      coinsAwarded: (json['coins_awarded'] as num?)?.toInt() ?? 0,
      snapGroupId: (json['snap_group_id'] ?? '').toString(),
      usedFallback: json['used_fallback'] as bool? ?? false,
    );
  }

  final List<SnapVocabItem> vocabItems;
  final int coinsAwarded;
  final String snapGroupId;
  final bool usedFallback;
}

// ── Saved Status ─────────────────────────────────────────

class SavedStatusResponse {
  const SavedStatusResponse({
    required this.isSaved,
    required this.deckIds,
  });

  factory SavedStatusResponse.fromJson(Map<String, dynamic> json) {
    final rawIds = json['deckIds'] as List<dynamic>? ?? [];
    return SavedStatusResponse(
      isSaved: json['isSaved'] as bool? ?? false,
      deckIds: rawIds.map((e) => e.toString()).toList(),
    );
  }

  final bool isSaved;
  final List<String> deckIds;
}

// ── Supported Language ───────────────────────────────────

class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  factory SupportedLanguage.fromJson(Map<String, dynamic> json) {
    return SupportedLanguage(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      nativeName: (json['nativeName'] ?? json['native_name'] ?? '').toString(),
      flag: (json['flag'] ?? '🌐').toString(),
    );
  }

  final String code;
  final String name;
  final String nativeName;
  final String flag;
}