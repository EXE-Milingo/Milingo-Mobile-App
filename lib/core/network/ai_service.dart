import 'dart:typed_data';
import 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

export 'package:milingo/features/snap_and_learn/models/milingo_result.dart';

// ─────────────────────────────────────────────────────────
// AI Provider type enum
// ─────────────────────────────────────────────────────────

enum AIProviderType {
  gemini,
  openai,
}

// ─────────────────────────────────────────────────────────
// Abstract AI Service Interface
// ─────────────────────────────────────────────────────────

/// Unified interface for all AI backends.
/// Both Gemini and OpenAI implement this contract.
abstract class AIService {
  /// Human-readable name of the provider.
  String get providerName;

  /// The model identifier being used.
  String get modelName;

  /// Analyze an image and return vocabulary results.
  Future<MilingoResult> analyzeImageForLanguage({
    required Uint8List imageBytes,
    required String targetLanguage,
  });
}
