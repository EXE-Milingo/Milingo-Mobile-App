import 'dart:convert';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

// ─────────────────────────────────────────────────────────
// Shared AI Response Parser
// ─────────────────────────────────────────────────────────

/// Robust JSON parser shared by all AI service implementations.
/// Handles clean JSON, truncated JSON, and fully malformed responses.
class AIResponseParser {
  /// The prompt template used by all AI providers.
  static String buildPrompt(String langName) => '''
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

  /// Language display names shared across providers.
  static const Map<String, String> languageDisplayNames = {
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

  /// Parse AI response text into a MilingoResult.
  static MilingoResult parse(String responseText) {
    // ── Step 1: strip markdown fences ────────────────────
    var cleaned = responseText.trim();
    if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
    if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
    if (cleaned.endsWith('```'))
      cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();

    // ── Step 2: try clean JSON decode ────────────────────
    try {
      return MilingoResult.fromJson(
          jsonDecode(cleaned) as Map<String, dynamic>);
    } catch (_) {}

    // ── Step 3: try to repair truncated JSON ─────────────
    try {
      final start = cleaned.indexOf('{');
      if (start != -1) {
        var partial = cleaned.substring(start);
        partial = partial.trimRight();
        if (partial.endsWith(',')) {
          partial = partial.substring(0, partial.length - 1);
        }
        int braces = 0, brackets = 0;
        for (final ch in partial.runes) {
          if (ch == '{'.codeUnitAt(0))
            braces++;
          else if (ch == '}'.codeUnitAt(0))
            braces--;
          else if (ch == '['.codeUnitAt(0))
            brackets++;
          else if (ch == ']'.codeUnitAt(0)) brackets--;
        }
        final sb = StringBuffer(partial);
        for (var i = 0; i < brackets; i++) sb.write(']');
        for (var i = 0; i < braces; i++) sb.write('}');
        final repaired = sb.toString();
        try {
          return MilingoResult.fromJson(
              jsonDecode(repaired) as Map<String, dynamic>);
        } catch (_) {}
      }
    } catch (_) {}

    // ── Step 4: per-field regex extraction ───────────────
    String extract(String field) {
      final match = RegExp(
        '"$field"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"',
      ).firstMatch(cleaned);
      return match?.group(1) ?? '';
    }

    final relatedWords = <RelatedWord>[];
    final rwMatch =
        RegExp(r'"relatedWords"\s*:\s*\[([\s\S]*?)\]').firstMatch(cleaned);
    if (rwMatch != null) {
      final items = RegExp(r'\{[^}]+\}').allMatches(rwMatch.group(1) ?? '');
      for (final item in items) {
        try {
          relatedWords.add(RelatedWord.fromJson(
              jsonDecode(item.group(0)!) as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    final keyword = extract('keyword');
    if (keyword.isEmpty) {
      throw Exception('Không thể parse phản hồi AI');
    }

    return MilingoResult(
      keyword: keyword,
      translation: extract('translation'),
      pronunciation: extract('pronunciation'),
      partOfSpeech:
          extract('partOfSpeech').isEmpty ? 'Noun' : extract('partOfSpeech'),
      sentence: extract('sentence'),
      sentenceTranslation: extract('sentenceTranslation'),
      relatedWords: relatedWords,
    );
  }
}
