import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/ai_service.dart';
import 'package:milingo/core/network/ai_response_parser.dart';

// ─────────────────────────────────────────────────────────
// OpenAI API Service  (GPT-5.4 mini with vision)
// ─────────────────────────────────────────────────────────

class OpenAIService implements AIService {
  OpenAIService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.openai.com/v1',
      headers: {
        'Authorization': 'Bearer ${AppConstants.openaiApiKey}',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  late final Dio _dio;

  @override
  String get providerName => 'OpenAI';

  @override
  String get modelName => 'gpt-5-mini';

  @override
  Future<MilingoResult> analyzeImageForLanguage({
    required Uint8List imageBytes,
    required String targetLanguage,
  }) async {
    try {
      final langName =
          AIResponseParser.languageDisplayNames[targetLanguage] ?? targetLanguage;
      final prompt = AIResponseParser.buildPrompt(langName);

      // Encode image to base64 for OpenAI vision API
      final base64Image = base64Encode(imageBytes);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': modelName,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                    'detail': 'low',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1024,
          'temperature': 0.4,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;

      if (choices == null || choices.isEmpty) {
        throw Exception('Không nhận được phản hồi từ AI');
      }

      final text = choices[0]['message']['content'] as String?;

      if (text == null || text.isEmpty) {
        throw Exception('Không nhận được phản hồi từ AI');
      }

      return AIResponseParser.parse(text);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final body = e.response?.data;
      String msg = 'Lỗi kết nối API';
      if (statusCode == 401) {
        msg = 'API key không hợp lệ';
      } else if (statusCode == 429) {
        msg = 'Đã vượt quá giới hạn gọi API. Vui lòng thử lại sau.';
      } else if (statusCode == 400) {
        msg = 'Yêu cầu không hợp lệ: ${body?['error']?['message'] ?? ''}';
      } else if (statusCode != null) {
        msg = 'Lỗi API ($statusCode)';
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception('Lỗi phân tích ảnh (OpenAI): $e');
    }
  }
}
