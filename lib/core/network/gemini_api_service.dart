import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────

/// A related vocabulary word (shown as floating bubble on image)
class RelatedWord {
  const RelatedWord({
    required this.english,
    required this.translation,
    required this.pronunciation,
  });

  factory RelatedWord.fromJson(Map<String, dynamic> json) {
    return RelatedWord(
      english: (json['english'] ?? '').toString(),
      translation: (json['translation'] ?? '').toString(),
      pronunciation: (json['pronunciation'] ?? '').toString(),
    );
  }

  final String english;
  final String translation;
  final String pronunciation;
}

/// Main analysis result from Gemini
class MilingoResult {
  MilingoResult({
    required this.keyword,
    required this.translation,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.sentence,
    required this.sentenceTranslation,
    this.relatedWords = const [],
  });

  factory MilingoResult.fromJson(Map<String, dynamic> json) {
    final related = (json['relatedWords'] as List<dynamic>?)
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
    );
  }

  /// Tên đối tượng bằng English
  final String keyword;

  /// Dịch sang ngôn ngữ đích
  final String translation;

  /// Phiên âm romanized
  final String pronunciation;

  /// Loại từ: Noun, Verb, Adjective...
  final String partOfSpeech;

  /// Câu ví dụ bằng ngôn ngữ đích
  final String sentence;

  /// Dịch tiếng Việt câu ví dụ
  final String sentenceTranslation;

  /// Từ liên quan (hiển thị dưới dạng bubble)
  final List<RelatedWord> relatedWords;
}

// ─────────────────────────────────────────────────────────
// Gemini API Service
// ─────────────────────────────────────────────────────────

final geminiApiServiceProvider = Provider<GeminiApiService>((ref) {
  return GeminiApiService._();
});

class GeminiApiService {
  GeminiApiService._() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: AppConstants.geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
  }

  late final GenerativeModel _model;

  static const Map<String, String> _languageDisplayNames = {
    'en': 'tiếng Anh (English)',
    'ja': 'tiếng Nhật (Japanese)',
    'ko': 'tiếng Hàn (Korean)',
    'zh': 'tiếng Trung (Chinese)',
    'es': 'tiếng Tây Ban Nha (Spanish)',
    'fr': 'tiếng Pháp (French)',
    'de': 'tiếng Đức (German)',
    'th': 'tiếng Thái (Thai)',
    'vi': 'tiếng Việt (Vietnamese)',
  };

  /// Analyze image → main vocabulary + related words
  Future<MilingoResult> analyzeImageForLanguage({
    required Uint8List imageBytes,
    required String targetLanguage,
  }) async {
    try {
      final langName =
          _languageDisplayNames[targetLanguage] ?? targetLanguage;

      final prompt = '''
Hãy đóng vai là trợ lý học tập MiLingo. Phân tích hình ảnh này.

Bước 1: Xác định đối tượng nổi bật nhất trong ảnh.
Bước 2: Tìm 3-4 khái niệm/đặc điểm liên quan đến đối tượng đó (ví dụ: nếu là cây, thì liên quan có thể là "lá", "thiên nhiên", "xanh", "sống").
Bước 3: Tạo bài học bằng $langName.

Trả về JSON CHÍNH XÁC theo format sau:
{
  "keyword": "tên đối tượng chính bằng tiếng Anh",
  "translation": "dịch keyword sang $langName",
  "pronunciation": "phiên âm romanized của translation",
  "partOfSpeech": "loại từ bằng tiếng Anh (Noun/Verb/Adjective)",
  "sentence": "một câu giao tiếp tự nhiên bằng $langName có chứa từ đó",
  "sentenceTranslation": "dịch câu trên sang tiếng Việt",
  "relatedWords": [
    {"english": "CONCEPT1", "translation": "dịch sang $langName", "pronunciation": "phiên âm"},
    {"english": "CONCEPT2", "translation": "dịch sang $langName", "pronunciation": "phiên âm"},
    {"english": "CONCEPT3", "translation": "dịch sang $langName", "pronunciation": "phiên âm"},
    {"english": "CONCEPT4", "translation": "dịch sang $langName", "pronunciation": "phiên âm"}
  ]
}

Lưu ý:
- relatedWords: chọn những khái niệm thật sự liên quan đến vật thể trong ảnh
- pronunciation: dùng Romaji cho tiếng Nhật, Pinyin cho tiếng Trung, romanization phù hợp cho các ngôn ngữ khác
- english: viết IN HOA
- Chỉ trả về JSON, không thêm text nào khác
''';

      final content = [
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null || text.isEmpty) {
        throw Exception('Không nhận được phản hồi từ AI');
      }

      return _parseResponse(text);
    } catch (e) {
      throw Exception('Lỗi phân tích ảnh: $e');
    }
  }

  MilingoResult _parseResponse(String responseText) {
    try {
      var cleaned = responseText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      }
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final Map<String, dynamic> json = jsonDecode(cleaned);
      return MilingoResult.fromJson(json);
    } catch (e) {
      // Fallback regex extraction
      try {
        final match = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        if (match != null) {
          final Map<String, dynamic> json = jsonDecode(match.group(0)!);
          return MilingoResult.fromJson(json);
        }
      } catch (_) {}
      throw Exception('Không thể parse phản hồi AI: $e');
    }
  }
}
