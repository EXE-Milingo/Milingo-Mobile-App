/// A related vocabulary word returned by Gemini (shown as a floating bubble)
class RelatedWord {
  const RelatedWord({
    required this.english,
    required this.translation,
    required this.pronunciation,
  });

  factory RelatedWord.fromJson(Map<String, dynamic> json) {
    return RelatedWord(
      english:
          (json['english'] ?? json['keyword'] ?? json['term'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
    );
  }

  final String english;
  final String translation;
  final String pronunciation;
}

/// Main analysis result from Gemini for Snap & Learn
class MilingoResult {
  MilingoResult({
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.sentence,
    required this.sentenceTranslation,
    this.relatedWords = const [],
    this.boundingBox,
    this.segmentation,
    this.objectImageBase64,
    this.objectImageUrl,
  });

  factory MilingoResult.fromJson(Map<String, dynamic> json) {
    final related =
        ((json['relatedWords'] ?? json['related_words']) as List<dynamic>?)
                ?.map((e) => RelatedWord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

    return MilingoResult(
      keyword: (json['keyword'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
      partOfSpeech: (json['partOfSpeech'] ?? 'Noun').toString(),
      sentence: (json['sentence'] ?? '').toString(),
      sentenceTranslation: (json['sentenceTranslation'] ?? '').toString(),
      relatedWords: related,
      boundingBox: _parseBoundingBox(json),
      segmentation: _parseSegmentation(json),
    );
  }

  static ObjectBoundingBox? _parseBoundingBox(Map<String, dynamic> json) {
    final raw = json['boundingBox'] ?? json['bounding_box'];
    if (raw is! Map<String, dynamic>) return null;
    final box = ObjectBoundingBox.fromJson(raw);
    return box.isValid ? box : null;
  }

  static ObjectSegmentation? _parseSegmentation(Map<String, dynamic> json) {
    final raw = json['segmentation'];
    if (raw is! Map) return null;
    final segmentation = ObjectSegmentation.fromJson(
      Map<String, dynamic>.from(raw),
    );
    return segmentation.isValid ? segmentation : null;
  }

  /// Main object name in English
  final String keyword;

  /// Translation in the target language
  final String translation;

  /// Romanized pronunciation
  final String pronunciation;

  /// Part of speech: Noun / Verb / Adjective...
  final String partOfSpeech;

  /// Example sentence in the target language
  final String sentence;

  /// Vietnamese translation of the example sentence
  final String sentenceTranslation;

  /// Related concepts shown as floating bubbles on the image
  final List<RelatedWord> relatedWords;

  /// YOLO bounding box in original image pixels.
  final ObjectBoundingBox? boundingBox;

  /// YOLO segmentation contour in original image pixels.
  final ObjectSegmentation? segmentation;

  /// Base64-encoded JPEG of the cropped object from YOLO detection.
  /// Null when fallback (full-image) was used.
  String? objectImageBase64;

  /// Firebase Storage download URL of the cropped object image.
  /// Set after the image is uploaded to Cloud Storage.
  String? objectImageUrl;
}

class ObjectBoundingBox {
  const ObjectBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory ObjectBoundingBox.fromJson(Map<String, dynamic> json) {
    return ObjectBoundingBox(
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
}

class ObjectSegmentationPoint {
  const ObjectSegmentationPoint({
    required this.x,
    required this.y,
  });

  factory ObjectSegmentationPoint.fromJson(Map<String, dynamic> json) {
    return ObjectSegmentationPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }

  final double x;
  final double y;
}

class ObjectSegmentation {
  const ObjectSegmentation({
    required this.points,
  });

  factory ObjectSegmentation.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    final points = <ObjectSegmentationPoint>[];
    for (final raw in rawPoints) {
      if (raw is Map) {
        points.add(
          ObjectSegmentationPoint.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    }
    return ObjectSegmentation(points: points);
  }

  final List<ObjectSegmentationPoint> points;

  bool get isValid => points.length >= 3;
}

class DetectedObjectResult {
  const DetectedObjectResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.objectImageBase64,
    this.segmentation,
  });

  final String label;
  final double confidence;
  final ObjectBoundingBox boundingBox;
  final ObjectSegmentation? segmentation;
  final String objectImageBase64;
}
