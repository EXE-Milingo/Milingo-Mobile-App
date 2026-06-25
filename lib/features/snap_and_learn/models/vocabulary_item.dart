/// Model representing a learned vocabulary item from Snap & Learn
class VocabularyItem {
  // 0.0 to 1.0

  VocabularyItem({
    required this.id,
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.exampleSentence,
    required this.languageCode,
    required this.learnedAt,
    this.imageUrl,
    this.reviewCount = 0,
    this.masteryLevel = 0.0,
  });

  /// Create from Firestore document
  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      translation: json['translation'] as String,
      pronunciation: json['pronunciation'] as String,
      exampleSentence: json['example_sentence'] as String,
      languageCode: json['language_code'] as String,
      imageUrl: json['image_url'] as String?,
      learnedAt: DateTime.parse(json['learned_at'] as String),
      reviewCount: json['review_count'] as int? ?? 0,
      masteryLevel: (json['mastery_level'] as num?)?.toDouble() ?? 0.0,
    );
  }
  final String id;
  final String keyword;
  final String translation;
  final String pronunciation;
  final String exampleSentence;
  final String languageCode;
  final String? imageUrl;
  final DateTime learnedAt;
  final int reviewCount;
  final double masteryLevel;

  /// Convert to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'translation': translation,
      'pronunciation': pronunciation,
      'example_sentence': exampleSentence,
      'language_code': languageCode,
      'image_url': imageUrl,
      'learned_at': learnedAt.toIso8601String(),
      'review_count': reviewCount,
      'mastery_level': masteryLevel,
    };
  }

  /// Create a copy with updated fields
  VocabularyItem copyWith({
    String? id,
    String? keyword,
    String? translation,
    String? pronunciation,
    String? exampleSentence,
    String? languageCode,
    String? imageUrl,
    DateTime? learnedAt,
    int? reviewCount,
    double? masteryLevel,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      languageCode: languageCode ?? this.languageCode,
      imageUrl: imageUrl ?? this.imageUrl,
      learnedAt: learnedAt ?? this.learnedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      masteryLevel: masteryLevel ?? this.masteryLevel,
    );
  }
}
