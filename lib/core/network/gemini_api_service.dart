import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/ai_service.dart';
import 'package:milingo/core/network/ai_response_parser.dart';

// ─────────────────────────────────────────────────────────
// Gemini AI Service
// ─────────────────────────────────────────────────────────

class GeminiAIService implements AIService {
  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: AppConstants.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.4,
        topK: 32,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );
  }

  late final GenerativeModel _model;

  @override
  String get providerName => 'Google Gemini';

  @override
  String get modelName => 'gemini-3-flash-preview';

  @override
  Future<MilingoResult> analyzeImageForLanguage({
    required Uint8List imageBytes,
    required String targetLanguage,
  }) async {
    try {
      final langName =
          AIResponseParser.languageDisplayNames[targetLanguage] ?? targetLanguage;
      final prompt = AIResponseParser.buildPrompt(langName);

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

      return AIResponseParser.parse(text);
    } catch (e) {
      throw Exception('Lỗi phân tích ảnh (Gemini): $e');
    }
  }
}
