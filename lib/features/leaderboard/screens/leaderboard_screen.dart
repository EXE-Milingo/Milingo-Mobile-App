import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kInk = Color(0xFF2B1D19);
const _kMuted = Color(0xFF8B7D76);
const _kLine = Color(0xFFF1E3DC);
const _kAccent = AppTheme.primaryColor;
const _kSoft = Color(0xFFFFEDE7);
const _kSuccess = Color(0xFF2EAD62);

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
    });
  }

  Future<void> _reload() async {
    final notifier = ref.read(flashcardProvider.notifier);
    await notifier.refresh();
    await notifier.loadCardsForAllDecks();
  }

  void _startDailyReview() {
    HapticFeedback.mediumImpact();
    context.push(
      AppConstants.examRoute,
      extra: const {
        'deckId': 'all',
        'deckName': 'Ôn tập hôm nay',
        'langCode': 'en',
        'langName': 'English',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flashcards = ref.watch(flashcardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: flashcards.when(
            data: (data) => RefreshIndicator(
              color: _kAccent,
              onRefresh: _reload,
              child: _ReviewContent(
                decks: data.decks,
                onStart: _startDailyReview,
              ),
            ),
            loading: () => const _ReviewLoading(),
            error: (error, _) => _ReviewError(
              message: error.toString(),
              onRetry: _reload,
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({
    required this.decks,
    required this.onStart,
  });

  final List<DeckData> decks;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final loadedCards = decks.expand((deck) => deck.cards).toList();
    final totalWords = decks.fold<int>(0, (sum, deck) => sum + deck.total);
    final dueCount = loadedCards.isEmpty
        ? totalWords
        : loadedCards.where(_isDueForReview).length;
    final flashcardCount =
        loadedCards.where((card) => card.isNewForStudy).length;
    final reviewedCount =
        loadedCards.where((card) => !card.isNewForStudy).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        _ReviewHeader(
          dueCount: dueCount,
          onStart: onStart,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.menu_book_rounded,
                value: '$totalWords',
                label: 'Từ vựng',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.folder_rounded,
                value: '${decks.length}',
                label: 'Bộ từ',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                icon: Icons.bolt_rounded,
                value: '$dueCount',
                label: 'Đến hạn',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DailySessionPanel(
          dueCount: dueCount,
          flashcardCount: flashcardCount,
          reviewedCount: reviewedCount,
          onStart: onStart,
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Nguồn ôn tập',
          trailing: '${decks.length} bộ',
        ),
        const SizedBox(height: 10),
        if (decks.isEmpty)
          const _EmptySourceCard()
        else
          ...decks.map((deck) => _DeckSourceTile(deck: deck)),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.dueCount,
    required this.onStart,
  });

  final int dueCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _kInk.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ôn tập hôm nay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            dueCount == 0
                ? 'Bạn đã hoàn tất phiên ôn tập trong ngày.'
                : '$dueCount thẻ đang sẵn sàng để ôn theo lịch SRS.',
            style: const TextStyle(
              color: Color(0xFFEEDFD8),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: dueCount == 0 ? null : onStart,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Bắt đầu ôn tập'),
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.16),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _kAccent, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySessionPanel extends StatelessWidget {
  const _DailySessionPanel({
    required this.dueCount,
    required this.flashcardCount,
    required this.reviewedCount,
    required this.onStart,
  });

  final int dueCount;
  final int flashcardCount;
  final int reviewedCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.all_inbox_rounded,
                  color: _kAccent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phiên ôn tập chung',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tất cả bộ từ, đúng lịch SRS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeBadge(
                icon: Icons.style_rounded,
                label: '$flashcardCount thẻ mới',
              ),
              _ModeBadge(
                icon: Icons.quiz_rounded,
                label: '$reviewedCount trắc nghiệm',
              ),
              _ModeBadge(
                icon: Icons.schedule_rounded,
                label: '$dueCount đến hạn',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: dueCount == 0 ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: _kInk,
                disabledBackgroundColor: _kInk.withValues(alpha: 0.22),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: const Text('Vào bài ôn tập'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kAccent, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _kInk,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DeckSourceTile extends StatelessWidget {
  const _DeckSourceTile({required this.deck});

  final DeckData deck;

  @override
  Widget build(BuildContext context) {
    final dueCount = _deckDueCount(deck);
    final reviewedCount =
        deck.cards.where((card) => !card.isNewForStudy).length;
    final progress = deck.total == 0
        ? 0.0
        : (reviewedCount / deck.total).clamp(0.0, 1.0).toDouble();
    final emoji = deck.emoji.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: emoji.isEmpty
                  ? const Icon(
                      Icons.folder_rounded,
                      color: _kAccent,
                      size: 26,
                    )
                  : Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$dueCount cần ôn · ${deck.total} từ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: progress,
                    backgroundColor: _kSoft,
                    color: dueCount == 0 ? _kSuccess : _kAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _DueBadge(count: dueCount),
        ],
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final done = count == 0;
    return Container(
      constraints: const BoxConstraints(minWidth: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: done ? _kSuccess.withValues(alpha: 0.12) : _kSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        done ? 'Xong' : '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: done ? _kSuccess : _kAccent,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptySourceCard extends StatelessWidget {
  const _EmptySourceCard();

  @override
  Widget build(BuildContext context) {
    return const _StateCard(
      icon: Icons.menu_book_outlined,
      title: 'Chưa có bộ từ',
      message: 'Lưu từ mới trước, rồi quay lại để ôn tập theo lịch SRS.',
    );
  }
}

class _ReviewLoading extends StatelessWidget {
  const _ReviewLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kAccent),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: _StateCard(
          icon: Icons.error_outline_rounded,
          title: 'Không tải được dữ liệu',
          message: message,
          actionLabel: 'Thử lại',
          onAction: onRetry,
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kAccent, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

int _deckDueCount(DeckData deck) {
  if (deck.cards.isEmpty) return deck.total;
  return deck.cards.where(_isDueForReview).length;
}

bool _isDueForReview(FlashcardEntry card) {
  if (card.isNewForStudy) return true;

  final raw = card.srsNextReviewAt?.trim();
  if (raw == null || raw.isEmpty) return true;

  final nextReview = DateTime.tryParse(raw);
  if (nextReview == null) return true;

  return !nextReview.toUtc().isAfter(DateTime.now().toUtc());
}
