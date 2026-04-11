import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/ai_service.dart';
import 'package:milingo/core/network/gemini_api_service.dart';
import 'package:milingo/core/network/openai_api_service.dart';

// ─────────────────────────────────────────────────────────
// AI Provider Switcher
// ─────────────────────────────────────────────────────────
//
// Usage:
//   // Read the current AI service
//   final ai = ref.watch(aiServiceProvider);
//
//   // Switch provider at runtime
//   ref.read(aiProviderTypeProvider.notifier).state = AIProviderType.gemini;
//   ref.read(aiProviderTypeProvider.notifier).state = AIProviderType.openai;
//
// ─────────────────────────────────────────────────────────

/// Controls which AI backend is active.
/// Change this at runtime to switch providers.
final aiProviderTypeProvider = StateProvider<AIProviderType>((ref) {
  // ──────────────────────────────────────────────────────
  // DEFAULT PROVIDER — change this line to switch default
  // ──────────────────────────────────────────────────────
  return AIProviderType.gemini;
});

/// Provides the active [AIService] instance based on [aiProviderTypeProvider].
final aiServiceProvider = Provider<AIService>((ref) {
  final type = ref.watch(aiProviderTypeProvider);
  switch (type) {
    case AIProviderType.gemini:
      return GeminiAIService();
    case AIProviderType.openai:
      return OpenAIService();
  }
});

// ─────────────────────────────────────────────────────────
// Backward-compatible alias
// (so snap_provider.dart doesn't need to change its import)
// ─────────────────────────────────────────────────────────

/// @deprecated Use [aiServiceProvider] instead.
/// Kept for backward compatibility with existing code.
final geminiApiServiceProvider = Provider<AIService>((ref) {
  return ref.watch(aiServiceProvider);
});
