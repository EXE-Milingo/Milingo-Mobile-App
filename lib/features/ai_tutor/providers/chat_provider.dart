import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/ai_tutor/models/chat_message_model.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';

// ─────────────────────────────────────────────────────────
//  AI Tutor — Chat State
// ─────────────────────────────────────────────────────────

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.quota,
  });

  final List<ChatMessageModel> messages;
  final bool isLoading;
  final String? error;
  final ChatQuotaInfo? quota;

  ChatState copyWith({
    List<ChatMessageModel>? messages,
    bool? isLoading,
    String? error,
    ChatQuotaInfo? quota,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      quota: quota ?? this.quota,
    );
  }
}

// ─────────────────────────────────────────────────────────
//  AI Tutor — Chat Notifier
// ─────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._apiService, this._targetLanguage, this._cefrLevel)
      : super(const ChatState()) {
    // Greet the user with an initial AI message
    _addWelcomeMessage();
    // Load initial quota status
    loadQuota();
  }

  final MilingoApiService _apiService;
  final String _targetLanguage;
  final String _cefrLevel;

  void _addWelcomeMessage() {
    final langName = _languageDisplayName(_targetLanguage);
    state = state.copyWith(
      messages: [
        ChatMessageModel(
          role: ChatRole.assistant,
          content: 'Xin chào! Tôi là AI Tutor của MiLingo 👋\n\n'
              'Tôi có thể giúp bạn về ngữ pháp, từ vựng, phát âm và các mẹo học $langName. '
              'Hỏi tôi bất cứ điều gì về $langName nhé!',
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  /// Loads current daily quota status from the backend.
  Future<void> loadQuota() async {
    try {
      final quota = await _apiService.getChatQuotaStatus();
      state = state.copyWith(quota: quota);
    } catch (_) {
      // Quietly ignore or let error handle on first message
    }
  }

  /// Sends a user message and appends the AI reply.
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.isLoading) return; // Prevent double-send

    // Pre-check if quota was already exceeded
    if (state.quota != null && state.quota!.isLimitReached) {
      state = state.copyWith(
        error:
            'Bạn đã dùng hết ${state.quota!.freeLimit} tin nhắn miễn phí hôm nay. '
            'Nâng cấp lên Premium để nhắn không giới hạn!',
      );
      return;
    }

    final userMessage = ChatMessageModel(
      role: ChatRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Optimistically append user message and show loading
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Build history (all previous messages in API format, max 40 items)
      final history = state.messages
          .take(state.messages.length - 1) // exclude the just-added user msg
          .toList()
          .reversed
          .take(40)
          .toList()
          .reversed
          .map((m) => m.toJson())
          .toList();

      final responseInfo = await _apiService.sendChatMessage(
        message: text.trim(),
        history: history,
        targetLanguage: _targetLanguage,
        cefrLevel: _cefrLevel,
      );

      final aiMessage = ChatMessageModel(
        role: ChatRole.assistant,
        content: responseInfo.reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        quota: responseInfo.quota ?? state.quota,
      );
    } on MilingoApiException catch (e) {
      if (e.statusCode == 402) {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
          quota: ChatQuotaInfo(
            isPremium: false,
            freeLimit: state.quota?.freeLimit ?? 20,
            usedToday: state.quota?.freeLimit ?? 20,
            remainingToday: 0,
            isLimitReached: true,
          ),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Đã xảy ra lỗi. Vui lòng thử lại.',
      );
    }
  }

  /// Clears the error state so the UI can re-enable the input.
  void clearError() => state = state.copyWith(error: null);

  /// Clears conversation history and shows the welcome message again.
  void clearHistory() {
    state = const ChatState(
        quota:
            null); // Keep/reset quota on close/reopen, but provider autoDisposes anyway
    _addWelcomeMessage();
    loadQuota();
  }

  static String _languageDisplayName(String code) {
    final base = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    return switch (base) {
      'en' => 'tiếng Anh',
      'ja' || 'jp' => 'tiếng Nhật',
      'ko' => 'tiếng Hàn',
      'zh' => 'tiếng Trung',
      'fr' => 'tiếng Pháp',
      'de' => 'tiếng Đức',
      'es' => 'tiếng Tây Ban Nha',
      'it' => 'tiếng Ý',
      'vi' => 'tiếng Việt',
      _ => 'ngôn ngữ đang học',
    };
  }
}

// ─────────────────────────────────────────────────────────
//  Riverpod Providers
// ─────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider.autoDispose<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(milingoApiServiceProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;

  final targetLanguage = profile?.targetLanguage ?? 'en';
  final cefrLevel = profile?.cefrLevel ?? 'A1';

  return ChatNotifier(apiService, targetLanguage, cefrLevel);
});
