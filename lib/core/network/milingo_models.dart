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
    required this.isFavorite,
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
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  final String id;
  final String name;
  final String emoji;
  final String description;
  final int vocabCount;
  final bool isDefault;
  final bool isFavorite;
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
    required this.isFavorite,
    this.srsState = 'new',
    this.srsRepetitions = 0,
    this.srsIntervalDays = 0,
    this.srsEasinessFactor = 2.5,
    this.srsNextReviewAt,
    this.sourceVocabId,
    this.imageUrl,
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
      isFavorite: json['is_favorite'] as bool? ?? false,
      srsState: (json['srs_state'] ?? 'new').toString(),
      srsRepetitions: (json['srs_repetitions'] as num?)?.toInt() ?? 0,
      srsIntervalDays: (json['srs_interval_days'] as num?)?.toInt() ?? 0,
      srsEasinessFactor:
          (json['srs_easiness_factor'] as num?)?.toDouble() ?? 2.5,
      srsNextReviewAt: json['srs_next_review_at'] as String?,
      sourceVocabId: json['source_vocab_id'] as String?,
      imageUrl: json['image_url'] as String?,
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
  final bool isFavorite;
  final String srsState;
  final int srsRepetitions;
  final int srsIntervalDays;
  final double srsEasinessFactor;
  final String? srsNextReviewAt;
  final String? sourceVocabId;
  final String? imageUrl;

  CardResponse copyWithImageUrl(String? value) {
    return CardResponse(
      id: id,
      term: term,
      translation: translation,
      pronunciation: pronunciation,
      partOfSpeech: partOfSpeech,
      sourceLangCode: sourceLangCode,
      targetLangCode: targetLangCode,
      createdAt: createdAt,
      isFavorite: isFavorite,
      srsState: srsState,
      srsRepetitions: srsRepetitions,
      srsIntervalDays: srsIntervalDays,
      srsEasinessFactor: srsEasinessFactor,
      srsNextReviewAt: srsNextReviewAt,
      sourceVocabId: sourceVocabId,
      imageUrl: value,
    );
  }
}

// Study / Exam

class StudyOption {
  const StudyOption({
    required this.id,
    required this.term,
    required this.isCorrect,
  });

  factory StudyOption.fromJson(Map<String, dynamic> json) {
    return StudyOption(
      id: (json['id'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }

  final String id;
  final String term;
  final bool isCorrect;
}

class StudyCard {
  const StudyCard({
    required this.cardId,
    required this.deckId,
    required this.deckName,
    required this.term,
    required this.translation,
    required this.pronunciation,
    required this.exampleSentence,
    required this.srsState,
    required this.srsRepetitions,
    required this.srsIntervalDays,
    required this.isFirstReview,
    required this.suggestedMode,
    required this.options,
    this.imageUrl,
  });

  factory StudyCard.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>?;
    final repetitions = (json['srs_repetitions'] as num?)?.toInt() ?? 0;
    return StudyCard(
      cardId: (json['card_id'] ?? '').toString(),
      deckId: (json['deck_id'] ?? '').toString(),
      deckName: (json['deck_name'] ?? '').toString(),
      term: (json['term'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      exampleSentence: (json['example_sentence'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      srsState: (json['srs_state'] ?? 'new').toString(),
      srsRepetitions: repetitions,
      srsIntervalDays: (json['srs_interval_days'] as num?)?.toInt() ?? 0,
      isFirstReview: json['is_first_review'] as bool? ?? repetitions <= 0,
      suggestedMode: (json['suggested_mode'] ?? 'flashcard').toString(),
      options: rawOptions
          ?.whereType<Map>()
          .map((e) => StudyOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  final String cardId;
  final String deckId;
  final String deckName;
  final String term;
  final String translation;
  final String pronunciation;
  final String exampleSentence;
  final String? imageUrl;
  final String srsState;
  final int srsRepetitions;
  final int srsIntervalDays;
  final bool isFirstReview;
  final String suggestedMode;
  final List<StudyOption>? options;

  bool get isMcq => suggestedMode == 'mcq' && (options?.isNotEmpty ?? false);
}

class StudySessionResponse {
  const StudySessionResponse({
    required this.deckId,
    required this.deckName,
    required this.cards,
    required this.totalDue,
    required this.flashcardCount,
    required this.mcqCount,
  });

  factory StudySessionResponse.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as List<dynamic>? ?? const [];
    return StudySessionResponse(
      deckId: (json['deck_id'] ?? '').toString(),
      deckName: (json['deck_name'] ?? '').toString(),
      cards: rawCards
          .whereType<Map>()
          .map((e) => StudyCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalDue: (json['total_due'] as num?)?.toInt() ?? 0,
      flashcardCount: (json['flashcard_count'] as num?)?.toInt() ?? 0,
      mcqCount: (json['mcq_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String deckId;
  final String deckName;
  final List<StudyCard> cards;
  final int totalDue;
  final int flashcardCount;
  final int mcqCount;
}

class SubmitStudyAnswerResponse {
  const SubmitStudyAnswerResponse({
    required this.cardId,
    required this.mode,
    required this.qualityApplied,
    required this.newSrsState,
    required this.newIntervalDays,
    required this.nextReviewAt,
    required this.coinsAwarded,
  });

  factory SubmitStudyAnswerResponse.fromJson(Map<String, dynamic> json) {
    return SubmitStudyAnswerResponse(
      cardId: (json['card_id'] ?? '').toString(),
      mode: (json['mode'] ?? '').toString(),
      qualityApplied: (json['quality_applied'] as num?)?.toInt() ?? 0,
      newSrsState: (json['new_srs_state'] ?? '').toString(),
      newIntervalDays: (json['new_interval_days'] as num?)?.toInt() ?? 0,
      nextReviewAt: (json['next_review_at'] ?? '').toString(),
      coinsAwarded: (json['coins_awarded'] as num?)?.toInt() ?? 0,
    );
  }

  final String cardId;
  final String mode;
  final int qualityApplied;
  final String newSrsState;
  final int newIntervalDays;
  final String nextReviewAt;
  final int coinsAwarded;
}

class DeckStudyStats {
  const DeckStudyStats({
    required this.deckId,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
    required this.masteredCount,
    required this.dueToday,
    required this.totalCards,
  });

  factory DeckStudyStats.fromJson(Map<String, dynamic> json) {
    return DeckStudyStats(
      deckId: (json['deck_id'] ?? '').toString(),
      newCount: (json['new_count'] as num?)?.toInt() ?? 0,
      learningCount: (json['learning_count'] as num?)?.toInt() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      masteredCount: (json['mastered_count'] as num?)?.toInt() ?? 0,
      dueToday: (json['due_today'] as num?)?.toInt() ?? 0,
      totalCards: (json['total_cards'] as num?)?.toInt() ?? 0,
    );
  }

  final String deckId;
  final int newCount;
  final int learningCount;
  final int reviewCount;
  final int masteredCount;
  final int dueToday;
  final int totalCards;
}

// ── Snap Analysis ────────────────────────────────────────

class SnapBoundingBox {
  const SnapBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory SnapBoundingBox.fromJson(Map<String, dynamic> json) {
    return SnapBoundingBox(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
    );
  }

  final double x;
  final double y;
  final double width;
  final double height;

  bool get isValid => width > 0 && height > 0;

  Map<String, dynamic> toJson() {
    return {
      'x': x.round(),
      'y': y.round(),
      'width': width.round(),
      'height': height.round(),
    };
  }
}

class SnapSegmentationPoint {
  const SnapSegmentationPoint({
    required this.x,
    required this.y,
  });

  factory SnapSegmentationPoint.fromJson(Map<String, dynamic> json) {
    return SnapSegmentationPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

  final double x;
  final double y;

  Map<String, dynamic> toJson() {
    return {
      'x': x.round(),
      'y': y.round(),
    };
  }
}

class SnapSegmentation {
  const SnapSegmentation({
    required this.points,
  });

  factory SnapSegmentation.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    final points = <SnapSegmentationPoint>[];
    for (final raw in rawPoints) {
      if (raw is Map) {
        points.add(
          SnapSegmentationPoint.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    }
    return SnapSegmentation(points: points);
  }

  final List<SnapSegmentationPoint> points;

  bool get isValid => points.length >= 3;

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => p.toJson()).toList(),
    };
  }
}

class SnapVocabItem {
  const SnapVocabItem({
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.exampleSentence,
    this.relatedWords = const [],
    this.detectionLabel,
    this.detectionConfidence,
    this.boundingBox,
    this.segmentation,
    this.croppedImageBase64,
  });

  factory SnapVocabItem.fromJson(Map<String, dynamic> json) {
    return SnapVocabItem(
      keyword: (json['keyword'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      exampleSentence: (json['example_sentence'] ?? '').toString(),
      relatedWords: _parseRelatedWords(json),
      detectionLabel: json['detection_label'] as String?,
      detectionConfidence: (json['detection_confidence'] as num?)?.toDouble(),
      boundingBox: _parseBoundingBox(json),
      segmentation: _parseSegmentation(json),
      croppedImageBase64: json['cropped_image_base64'] as String?,
    );
  }

  static SnapBoundingBox? _parseBoundingBox(Map<String, dynamic> json) {
    final raw = json['bounding_box'] ?? json['boundingBox'];
    if (raw is! Map<String, dynamic>) return null;
    final box = SnapBoundingBox.fromJson(raw);
    return box.isValid ? box : null;
  }

  static SnapSegmentation? _parseSegmentation(Map<String, dynamic> json) {
    final raw = json['segmentation'];
    if (raw is! Map) return null;
    final segmentation = SnapSegmentation.fromJson(
      Map<String, dynamic>.from(raw),
    );
    return segmentation.isValid ? segmentation : null;
  }

  static List<SnapRelatedWord> _parseRelatedWords(Map<String, dynamic> json) {
    final raw = json['related_words'] ?? json['relatedWords'];
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => SnapRelatedWord.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.keyword.trim().isNotEmpty)
        .toList();
  }

  final String keyword;
  final String translation;
  final String pronunciation;
  final String exampleSentence;
  final List<SnapRelatedWord> relatedWords;
  final String? detectionLabel;
  final double? detectionConfidence;
  final SnapBoundingBox? boundingBox;
  final SnapSegmentation? segmentation;

  /// Base64-encoded JPEG of the cropped object from YOLO detection.
  /// Null when fallback (full-image) was used.
  final String? croppedImageBase64;
}

class SnapRelatedWord {
  const SnapRelatedWord({
    required this.keyword,
    required this.translation,
    required this.pronunciation,
  });

  factory SnapRelatedWord.fromJson(Map<String, dynamic> json) {
    return SnapRelatedWord(
      keyword:
          (json['keyword'] ?? json['english'] ?? json['term'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
    );
  }

  final String keyword;
  final String translation;
  final String pronunciation;
}

class SnapDetectedObject {
  const SnapDetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.croppedImageBase64,
    this.segmentation,
  });

  factory SnapDetectedObject.fromJson(Map<String, dynamic> json) {
    final rawBox = json['bounding_box'] ?? json['boundingBox'];
    final box = rawBox is Map
        ? SnapBoundingBox.fromJson(Map<String, dynamic>.from(rawBox))
        : const SnapBoundingBox(x: 0, y: 0, width: 0, height: 0);

    return SnapDetectedObject(
      label: (json['label'] ?? 'object').toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      boundingBox: box,
      segmentation: SnapVocabItem._parseSegmentation(json),
      croppedImageBase64:
          (json['cropped_image_base64'] ?? json['croppedImageBase64'] ?? '')
              .toString(),
    );
  }

  final String label;
  final double confidence;
  final SnapBoundingBox boundingBox;
  final SnapSegmentation? segmentation;
  final String croppedImageBase64;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'bounding_box': boundingBox.toJson(),
      if (segmentation != null) 'segmentation': segmentation!.toJson(),
      'cropped_image_base64': croppedImageBase64,
    };
  }
}

class SnapDetectionResponse {
  const SnapDetectionResponse({
    required this.objects,
    required this.totalDetected,
    required this.returnedCount,
    required this.processingTimeMs,
  });

  factory SnapDetectionResponse.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['objects'] ?? json['Objects']) as List<dynamic>? ?? const [];
    final objects = rawItems
        .whereType<Map>()
        .map((e) => SnapDetectedObject.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.boundingBox.isValid && e.croppedImageBase64.isNotEmpty)
        .toList();
    final totalDetected = json['total_detected'] ?? json['totalDetected'];
    final returnedCount = json['returned_count'] ?? json['returnedCount'];
    final processingTime =
        json['processing_time_ms'] ?? json['processingTimeMs'];

    return SnapDetectionResponse(
      objects: objects,
      totalDetected: (totalDetected as num?)?.toInt() ?? objects.length,
      returnedCount: (returnedCount as num?)?.toInt() ?? objects.length,
      processingTimeMs: (processingTime as num?)?.toDouble() ?? 0,
    );
  }

  final List<SnapDetectedObject> objects;
  final int totalDetected;
  final int returnedCount;
  final double processingTimeMs;
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
// ── User Stats ────────────────────────────────────────────

class UserProfileResponse {
  const UserProfileResponse({
    required this.id,
    required this.displayName,
    required this.email,
    required this.cefrLevel,
    required this.isPremium,
    this.photoUrl,
    this.nativeLanguage,
    this.targetLanguage,
    this.localAvatarPath,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: (json['id'] ?? '').toString(),
      displayName:
          (json['displayName'] ?? json['display_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
      nativeLanguage:
          (json['nativeLanguage'] ?? json['native_language']) as String?,
      targetLanguage:
          (json['targetLanguage'] ?? json['target_language']) as String?,
      cefrLevel: (json['cefrLevel'] ?? json['cefr_level'] ?? 'A1').toString(),
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? nativeLanguage;
  final String? targetLanguage;
  final String cefrLevel;
  final bool isPremium;
  final String? localAvatarPath;

  UserProfileResponse copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    String? nativeLanguage,
    String? targetLanguage,
    String? cefrLevel,
    bool? isPremium,
    String? localAvatarPath,
  }) {
    return UserProfileResponse(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      isPremium: isPremium ?? this.isPremium,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
    );
  }
}

class UserStatsResponse {
  const UserStatsResponse({
    required this.coins,
    required this.currentStreak,
    required this.totalPoints,
    this.lastStudyDate,
  });

  factory UserStatsResponse.fromJson(Map<String, dynamic> json) {
    return UserStatsResponse(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      lastStudyDate: json['lastStudyDate'] as String?,
    );
  }

  final int coins;
  final int currentStreak;
  final int totalPoints;
  final String? lastStudyDate;
}

class CreatePayOSOrderResponse {
  const CreatePayOSOrderResponse({
    required this.checkoutUrl,
    required this.orderCode,
    required this.paymentLinkId,
  });

  factory CreatePayOSOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreatePayOSOrderResponse(
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      paymentLinkId: (json['paymentLinkId'] ?? '').toString(),
    );
  }

  final String checkoutUrl;
  final int orderCode;
  final String paymentLinkId;
}

class SubscriptionPlanResponse {
  const SubscriptionPlanResponse({
    required this.planId,
    required this.planName,
    required this.amount,
    required this.durationDays,
  });

  factory SubscriptionPlanResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanResponse(
      planId: (json['planId'] ?? '').toString(),
      planName: (json['planName'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
    );
  }

  final String planId;
  final String planName;
  final int amount;
  final int durationDays;
}

class PremiumStatusResponse {
  const PremiumStatusResponse({
    required this.isPremium,
    this.expiresAt,
    this.source,
  });

  factory PremiumStatusResponse.fromJson(Map<String, dynamic> json) {
    return PremiumStatusResponse(
      isPremium: json['isPremium'] as bool? ?? false,
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()),
      source: json['source'] as String?,
    );
  }

  final bool isPremium;
  final DateTime? expiresAt;
  final String? source;
}

class SubscriptionBenefitResponse {
  const SubscriptionBenefitResponse({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  factory SubscriptionBenefitResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionBenefitResponse(
      icon: (json['icon'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
    );
  }

  final String icon;
  final String title;
  final String subtitle;
}

class SubscriptionOverviewResponse {
  const SubscriptionOverviewResponse({
    required this.isPremium,
    required this.planName,
    required this.lastPaymentAmount,
    required this.nextPaymentAmount,
    required this.monthlyProgressPercent,
    required this.benefits,
    this.planId,
    this.expiresAt,
    this.source,
    this.remainingDays,
    this.startedAt,
    this.memberSince,
    this.lastPaymentAt,
  });

  factory SubscriptionOverviewResponse.fromJson(Map<String, dynamic> json) {
    final rawBenefits = json['benefits'] as List<dynamic>? ?? const [];
    return SubscriptionOverviewResponse(
      isPremium: json['isPremium'] as bool? ?? false,
      planId: json['planId'] as String?,
      planName: (json['planName'] ?? 'Gói miễn phí').toString(),
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()),
      source: json['source'] as String?,
      remainingDays: (json['remainingDays'] as num?)?.toInt(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()),
      memberSince: DateTime.tryParse((json['memberSince'] ?? '').toString()),
      lastPaymentAt:
          DateTime.tryParse((json['lastPaymentAt'] ?? '').toString()),
      lastPaymentAmount: (json['lastPaymentAmount'] as num?)?.toInt() ?? 0,
      nextPaymentAmount: (json['nextPaymentAmount'] as num?)?.toInt() ?? 0,
      monthlyProgressPercent:
          (json['monthlyProgressPercent'] as num?)?.toInt() ?? 0,
      benefits: rawBenefits
          .whereType<Map>()
          .map((item) => SubscriptionBenefitResponse.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  final bool isPremium;
  final String? planId;
  final String planName;
  final DateTime? expiresAt;
  final String? source;
  final int? remainingDays;
  final DateTime? startedAt;
  final DateTime? memberSince;
  final DateTime? lastPaymentAt;
  final int lastPaymentAmount;
  final int nextPaymentAmount;
  final int monthlyProgressPercent;
  final List<SubscriptionBenefitResponse> benefits;
}

class PaymentTransactionHistoryResponse {
  const PaymentTransactionHistoryResponse({
    required this.totalSpentThisYear,
    required this.transactions,
  });

  factory PaymentTransactionHistoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawTransactions = json['transactions'] as List<dynamic>? ?? const [];
    return PaymentTransactionHistoryResponse(
      totalSpentThisYear: (json['totalSpentThisYear'] as num?)?.toInt() ?? 0,
      transactions: rawTransactions
          .whereType<Map>()
          .map((item) => PaymentTransactionResponse.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  final int totalSpentThisYear;
  final List<PaymentTransactionResponse> transactions;
}

class PaymentTransactionResponse {
  const PaymentTransactionResponse({
    required this.id,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.status,
    required this.statusLabel,
    required this.source,
    required this.paymentMethodLabel,
    this.orderCode,
    this.paymentLinkId,
    this.checkoutUrl,
    this.createdAt,
    this.updatedAt,
    this.paidAt,
  });

  factory PaymentTransactionResponse.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionResponse(
      id: (json['id'] ?? '').toString(),
      orderCode: (json['orderCode'] as num?)?.toInt(),
      planId: (json['planId'] ?? '').toString(),
      planName: (json['planName'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      statusLabel: (json['statusLabel'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      paymentMethodLabel: (json['paymentMethodLabel'] ?? '').toString(),
      paymentLinkId: json['paymentLinkId'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      paidAt: DateTime.tryParse((json['paidAt'] ?? '').toString()),
    );
  }

  final String id;
  final int? orderCode;
  final String planId;
  final String planName;
  final int amount;
  final String status;
  final String statusLabel;
  final String source;
  final String paymentMethodLabel;
  final String? paymentLinkId;
  final String? checkoutUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  DateTime? get displayDate => paidAt ?? updatedAt ?? createdAt;

  bool get isPaid {
    final normalized = status.toUpperCase();
    return normalized == 'PAID' ||
        normalized == 'SUCCESS' ||
        normalized == 'COMPLETED';
  }
}
