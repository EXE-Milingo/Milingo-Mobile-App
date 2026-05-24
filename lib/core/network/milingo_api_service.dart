import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';

export 'package:milingo/core/network/milingo_models.dart';

// ─────────────────────────────────────────────────────────
// Exception helpers
// ─────────────────────────────────────────────────────────

class MilingoApiException implements Exception {
  const MilingoApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'MilingoApiException($statusCode): $message';
}

// ─────────────────────────────────────────────────────────
// MilingoApiService
// ─────────────────────────────────────────────────────────

class MilingoApiService {
  MilingoApiService() : _dio = _buildDio();

  final Dio _dio;
  final _uuid = const Uuid();

  // ── Dio factory ────────────────────────────────────────

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.milingoBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auto-attach Firebase JWT to every request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await FirebaseAuth.instance.currentUser
                ?.getIdToken(false); // false = dùng cache nếu chưa hết hạn
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Nếu lấy token thất bại, vẫn cho request đi tiếp
            // Server sẽ trả 401 nếu cần auth
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Wrap Dio errors with friendly messages
          final statusCode = error.response?.statusCode;
          String message;
          switch (statusCode) {
            case 400:
              final body = error.response?.data;
              message = (body is Map && body['message'] != null)
                  ? body['message'].toString()
                  : 'Yêu cầu không hợp lệ.';
            case 401:
              message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
            case 403:
              message = 'Bạn không có quyền thực hiện thao tác này.';
            case 404:
              message = 'Không tìm thấy tài nguyên yêu cầu.';
            case 409:
              message = 'Dữ liệu đã tồn tại.';
            case 500:
              message = 'Lỗi máy chủ. Vui lòng thử lại sau.';
            default:
              message = error.message ?? 'Đã xảy ra lỗi kết nối.';
          }
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: MilingoApiException(message, statusCode: statusCode),
            ),
          );
        },
      ),
    );

    // Dev logging (remove / gate behind kDebugMode in prod)
    dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (o) => debugPrint('[Milingo API] $o'),
      ),
    );

    return dio;
  }

  // ── Internal helpers ───────────────────────────────────

  /// Unwraps `{ "status": "success"|"error", "data": ... }` envelope.
  T _unwrap<T>(Response response, T Function(dynamic data) mapper) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const MilingoApiException('Phản hồi không hợp lệ từ máy chủ.');
    }
    if (body['status'] != 'success') {
      throw MilingoApiException(
        (body['message'] ?? 'Đã xảy ra lỗi.').toString(),
        statusCode: response.statusCode,
      );
    }
    return mapper(body['data']);
  }

  String _userFriendlyError(Object e) {
    if (e is DioException && e.error is MilingoApiException) {
      return (e.error as MilingoApiException).message;
    }
    if (e is MilingoApiException) return e.message;
    return 'Đã xảy ra lỗi không xác định.';
  }

  // ═══════════════════════════════════════════════════════
  // Auth / User
  // ═══════════════════════════════════════════════════════

  /// Call once after Firebase registration. Idempotent.
  Future<void> initProfile({
    required String displayName,
    required String targetLanguage,
  }) async {
    try {
      await _dio.post(
        '/api/v1/users/init-profile',
        data: {
          'displayName': displayName,
          'targetLanguage': targetLanguage,
        },
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  /// Returns the list of languages the backend supports.
  /// No auth required.
  Future<List<SupportedLanguage>> getSupportedLanguages() async {
    try {
      final response = await _dio.get(
        '/api/v1/users/supported-languages',
        options: Options(
          headers: {'Authorization': null}, // explicitly no auth
        ),
      );
      return _unwrap(response, (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((e) => SupportedLanguage.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  /// Lấy stats của user: coins, streak, totalPoints.
  Future<UserStatsResponse> getUserStats() async {
    try {
      final response = await _dio.get('/api/v1/users/stats');
      return _unwrap(
        response,
        (data) => UserStatsResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  /// Ghi nhận học flashcard hôm nay. Idempotent.
  /// Trả về stats mới nhất sau khi cập nhật streak.
  Future<UserStatsResponse> recordFlashcardStudy() async {
    try {
      final response = await _dio.post('/api/v1/users/record-study');
      return _unwrap(
        response,
        (data) => UserStatsResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Snap & Learn
  // ═══════════════════════════════════════════════════════

  Future<SnapDetectionResponse> detectSnap(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/api/v1/snap/detect',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      return _unwrap(
        response,
        (data) => SnapDetectionResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<SnapAnalysisResponse> analyzeDetectedSnap(
    List<SnapDetectedObject> objects,
  ) async {
    final idempotencyKey = _uuid.v4();
    try {
      final response = await _dio.post(
        '/api/v1/snap/analyze-detected',
        data: {
          'objects': objects.map((o) => o.toJson()).toList(),
        },
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );

      return _unwrap(
        response,
        (data) => SnapAnalysisResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<SnapAnalysisResponse> analyzeSnap(File imageFile) async {
    final idempotencyKey = _uuid.v4();
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await _dio.post(
        '/api/v1/snap/analyze',
        data: formData,
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return _unwrap(
        response,
        (data) => SnapAnalysisResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Decks
  // ═══════════════════════════════════════════════════════

  Future<List<DeckResponse>> getDecks() async {
    try {
      final response = await _dio.get('/api/v1/decks');
      return _unwrap(response, (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((e) => DeckResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<DeckResponse> createDeck({
    required String name,
    required String emoji,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/decks',
        data: {
          'name': name,
          'emoji': emoji,
          if (description != null) 'description': description,
        },
      );
      return _unwrap(
        response,
        (data) => DeckResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<DeckResponse> updateDeck(
    String deckId, {
    String? name,
    String? emoji,
    String? description,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/v1/decks/$deckId',
        data: {
          if (name != null) 'name': name,
          if (emoji != null) 'emoji': emoji,
          if (description != null) 'description': description,
        },
      );
      return _unwrap(
        response,
        (data) => DeckResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<void> deleteDeck(String deckId) async {
    try {
      await _dio.delete('/api/v1/decks/$deckId');
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<DeckResponse> setDeckFavorite(
    String deckId, {
    required bool isFavorite,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/v1/decks/$deckId/favorite',
        data: {'isFavorite': isFavorite},
      );
      return _unwrap(
        response,
        (data) => DeckResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Cards
  // ═══════════════════════════════════════════════════════

  Future<List<CardResponse>> getCards(String deckId) async {
    try {
      final response = await _dio.get('/api/v1/decks/$deckId/cards');
      return _unwrap(response, (data) {
        final list = data as List<dynamic>? ?? [];
        return list
            .map((e) => CardResponse.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<CardResponse> addCard(
    String deckId, {
    required String term,
    required String translation,
    required String sourceLangCode,
    required String targetLangCode,
    String pronunciation = '',
    String partOfSpeech = '',
    String? sourceVocabId,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/decks/$deckId/cards',
        data: {
          'term': term,
          'translation': translation,
          'pronunciation': pronunciation,
          'partOfSpeech': partOfSpeech,
          'sourceLangCode': sourceLangCode,
          'targetLangCode': targetLangCode,
          if (sourceVocabId != null) 'sourceVocabId': sourceVocabId,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      return _unwrap(
        response,
        (data) => CardResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<void> deleteCard(String deckId, String cardId) async {
    try {
      await _dio.delete('/api/v1/decks/$deckId/cards/$cardId');
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  Future<CardResponse> setCardFavorite(
    String deckId,
    String cardId, {
    required bool isFavorite,
  }) async {
    try {
      final response = await _dio.patch(
        '/api/v1/decks/$deckId/cards/$cardId/favorite',
        data: {'isFavorite': isFavorite},
      );
      return _unwrap(
        response,
        (data) => CardResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }

  // ═══════════════════════════════════════════════════════
  // Flashcard Saved Status
  // ═══════════════════════════════════════════════════════

  Future<SavedStatusResponse> getSavedStatus({
    required String term,
    required String sourceLangCode,
    required String targetLangCode,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/flashcards/saved-status',
        queryParameters: {
          'term': term,
          'sourceLangCode': sourceLangCode,
          'targetLangCode': targetLangCode,
        },
      );
      return _unwrap(
        response,
        (data) => SavedStatusResponse.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw MilingoApiException(_userFriendlyError(e));
    }
  }
}

// ─────────────────────────────────────────────────────────
// Riverpod Provider
// ─────────────────────────────────────────────────────────

final milingoApiServiceProvider = Provider<MilingoApiService>((ref) {
  return MilingoApiService();
});
