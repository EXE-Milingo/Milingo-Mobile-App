import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/ai_tutor/providers/chat_provider.dart';
import 'package:milingo/features/ai_tutor/widgets/chat_bubble.dart';
import 'package:milingo/features/ai_tutor/widgets/chat_input_bar.dart';
import 'package:milingo/features/ai_tutor/widgets/suggestion_chips.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';

// ─────────────────────────────────────────────────────────
//  AI Tutor Screen
// ─────────────────────────────────────────────────────────

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({super.key});

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _onSend(String text) {
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _onChipTap(String text) {
    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('👑 ', style: TextStyle(fontSize: 20)),
            Text(
              'Hết lượt tin nhắn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1814),
              ),
            ),
          ],
        ),
        content: const Text(
          'Bạn đã dùng hết 20 tin nhắn miễn phí hôm nay. '
          'Hãy nâng cấp lên Premium để nhắn tin không giới hạn với AI Tutor!',
          style: TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF4A3728)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppConstants.premiumRoute);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Nâng cấp Premium', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final targetLanguage = profile?.targetLanguage ?? 'en';

    // Scroll to bottom when new messages arrive, and listen to quota exhaustion
    ref.listen(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }

      final nextLimitReached = next.quota?.isLimitReached ?? false;
      final prevLimitReached = previous?.quota?.isLimitReached ?? false;
      if (nextLimitReached && !prevLimitReached) {
        _showUpgradeDialog(context);
      }
    });

    final isLimitReached = chatState.quota?.isLimitReached ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: Stack(
        children: [
          // ── Background decorative blurred circles (Figma #1187:848, #1187:849) ──
          Positioned(
            right: -40,
            top: -50,
            child: _BlurredCircle(
              size: 260,
              color: const Color(0xFFFF8A1F).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: -80,
            top: 380,
            child: _BlurredCircle(
              size: 230,
              color: const Color(0xFFFF6A00).withValues(alpha: 0.10),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          Column(
            children: [
              // Header (Figma #1187:967)
              _AiTutorHeader(
                onClearHistory: () =>
                    ref.read(chatProvider.notifier).clearHistory(),
              ),

              // Suggestion chips (Figma #1187:987)
              const SizedBox(height: 8),
              SuggestionChips(
                onChipTap: _onChipTap,
                targetLanguage: targetLanguage,
              ),
              const SizedBox(height: 4),

              // Message list
              Expanded(
                child: _ChatMessageList(
                  scrollController: _scrollController,
                  chatState: chatState,
                ),
              ),

              // Error snack
              if (chatState.error != null)
                _ErrorBanner(
                  message: chatState.error!,
                  onDismiss: () => ref.read(chatProvider.notifier).clearError(),
                ),

              // Input bar (Figma #1187:992)
              ChatInputBar(
                onSend: _onSend,
                isLoading: chatState.isLoading,
                isLimitReached: isLimitReached,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────

class _AiTutorHeader extends ConsumerWidget {
  const _AiTutorHeader({required this.onClearHistory});

  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    final quota = chatState.quota;

    String statusText = 'Đang hoạt động';
    if (quota != null) {
      if (quota.isPremium) {
        statusText = 'Đang hoạt động • Premium';
      } else {
        statusText = 'Còn lại ${quota.remainingToday}/${quota.freeLimit} tin nhắn';
      }
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.70),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.60),
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 12,
            20,
            12,
          ),
          child: Row(
            children: [
              // Back button
              _HeaderButton(
                onTap: () => context.go(AppConstants.homeRoute),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1D1814),
                ),
              ),

              const SizedBox(width: 12),

              // AI avatar + title
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF8A1F), Color(0xFFFF6A00)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6A00).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '✦',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Tutor',
                      style: TextStyle(
                        color: Color(0xFF1D1814),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Info / clear button
              _HeaderButton(
                onTap: () => _showInfoDialog(context, onClearHistory),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF1D1814),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, VoidCallback onClear) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiTutorInfoSheet(onClearHistory: onClear),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}

// ── Message List ─────────────────────────────────────────

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.scrollController,
    required this.chatState,
  });

  final ScrollController scrollController;
  final ChatState chatState;

  @override
  Widget build(BuildContext context) {
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final totalItems = messages.length + (isLoading ? 1 : 0);

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: totalItems,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (isLoading && index == totalItems - 1) {
          return const TypingIndicator();
        }
        return ChatBubble(message: messages[index]);
      },
    );
  }
}

// ── Error Banner ─────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFE53935), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFE53935), size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Blurred Background Circle ─────────────────────────────

class _BlurredCircle extends StatelessWidget {
  const _BlurredCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

// ── Info / Options Bottom Sheet ───────────────────────────

class _AiTutorInfoSheet extends StatelessWidget {
  const _AiTutorInfoSheet({required this.onClearHistory});

  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2D6CF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'AI Tutor',
            style: TextStyle(
              color: Color(0xFF1D1814),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trợ lý học ngôn ngữ thông minh. Tôi có thể giúp bạn về ngữ pháp, '
            'từ vựng, phát âm và các mẹo học tập hiệu quả.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 6),
          // Scope notice
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0C0)),
            ),
            child: const Row(
              children: [
                Text('ℹ️', style: TextStyle(fontSize: 16)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI Tutor chỉ hỗ trợ các chủ đề học ngôn ngữ. Câu hỏi ngoài phạm vi sẽ được từ chối lịch sự.',
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Clear history action
          Material(
            color: const Color(0xFFFFF1F0),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                onClearHistory();
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFE53935), size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Xóa lịch sử trò chuyện',
                      style: TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
