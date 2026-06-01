import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFF6F8FB);
const _kSurface = Colors.white;
const _kInk = Color(0xFF172033);
const _kMuted = Color(0xFF6C7482);
const _kSubtle = Color(0xFFE8EDF5);
const _kAccent = AppTheme.primaryColor;
const _kAccentSoft = Color(0xFFFFF0EA);
const _kSuccess = Color(0xFF21A67A);
const _kBlue = Color(0xFF4267D6);
const _kBlueSoft = Color(0xFFEAF0FF);

class ReviewExamScreen extends ConsumerStatefulWidget {
  const ReviewExamScreen({super.key});

  @override
  ConsumerState<ReviewExamScreen> createState() => _ReviewExamScreenState();
}

class _ReviewExamScreenState extends ConsumerState<ReviewExamScreen> {
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
    final newCount = loadedCards.where((card) => card.isNewForStudy).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        _ReviewHeader(
          dueCount: dueCount,
          totalWords: totalWords,
          onStart: onStart,
        ),
        const SizedBox(height: 14),
        _MetricIsland(
          totalWords: totalWords,
          deckCount: decks.length,
          newCount: newCount,
        ),
        const SizedBox(height: 28),
        const _SectionTitle(title: 'Nguồn ôn tập'),
        const SizedBox(height: 12),
        if (decks.isEmpty)
          const _EmptySourceCard()
        else
          ...decks.indexed.map(
            (entry) => _DeckSourceTile(
              deck: entry.$2,
              index: entry.$1,
            ),
          ),
      ],
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({
    required this.dueCount,
    required this.totalWords,
    required this.onStart,
  });

  final int dueCount;
  final int totalWords;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isDone = dueCount == 0;

    return _FloatingIsland(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SoftIcon(
                icon: Icons.auto_stories_rounded,
                backgroundColor: _kBlueSoft,
                color: _kBlue,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ôn tập hôm nay',
                  style: TextStyle(
                    color: _kInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
              _StatusPill(
                label: isDone ? 'Hoàn tất' : 'Cần ôn',
                color: isDone ? _kSuccess : _kAccent,
                backgroundColor:
                    isDone ? _kSuccess.withValues(alpha: 0.10) : _kAccentSoft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$dueCount',
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 78,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 9),
                child: Text(
                  'thẻ\nđến hạn',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isDone
                ? 'Bạn đã hoàn tất lịch ôn. $totalWords từ vẫn được theo dõi trong SRS.'
                : 'Tập trung vào các thẻ đến hạn từ tất cả bộ từ.',
            style: const TextStyle(
              color: _kMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: isDone ? null : onStart,
              icon: Icon(
                isDone ? Icons.check_rounded : Icons.play_arrow_rounded,
                size: 22,
              ),
              label: Text(isDone ? 'Đã hoàn tất' : 'Bắt đầu ôn tập'),
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                disabledBackgroundColor: _kSubtle,
                foregroundColor: Colors.white,
                disabledForegroundColor: _kMuted,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricIsland extends StatelessWidget {
  const _MetricIsland({
    required this.totalWords,
    required this.deckCount,
    required this.newCount,
  });

  final int totalWords;
  final int deckCount;
  final int newCount;

  @override
  Widget build(BuildContext context) {
    return _FloatingIsland(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              value: '$totalWords',
              label: 'Từ',
              color: _kBlue,
              backgroundColor: _kBlueSoft,
            ),
          ),
          Expanded(
            child: _MetricTile(
              value: '$deckCount',
              label: 'Bộ',
              color: _kInk,
              backgroundColor: const Color(0xFFF2F5F9),
            ),
          ),
          Expanded(
            child: _MetricTile(
              value: '$newCount',
              label: 'Mới',
              color: _kAccent,
              backgroundColor: _kAccentSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _kInk,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    );
  }
}

class _DeckSourceTile extends StatelessWidget {
  const _DeckSourceTile({
    required this.deck,
    required this.index,
  });

  final DeckData deck;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dueCount = _deckDueCount(deck);
    final reviewedCount =
        deck.cards.where((card) => !card.isNewForStudy).length;
    final progress = deck.total == 0
        ? 0.0
        : (reviewedCount / deck.total).clamp(0.0, 1.0).toDouble();
    final emoji = deck.emoji.trim();
    final isDone = dueCount == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _FloatingIsland(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _DeckMark(emoji: emoji, index: index + 1),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${deck.total} từ',
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusPill(
                  label: isDone ? 'Đã xong' : '$dueCount cần ôn',
                  color: isDone ? _kSuccess : _kAccent,
                  backgroundColor:
                      isDone ? _kSuccess.withValues(alpha: 0.10) : _kAccentSoft,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SoftProgressBar(
              progress: progress,
              color: isDone ? _kSuccess : _kAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckMark extends StatelessWidget {
  const _DeckMark({
    required this.emoji,
    required this.index,
  });

  final String emoji;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: emoji.isEmpty
            ? Text(
                index.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: _kBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Text(
                emoji,
                style: const TextStyle(fontSize: 23),
              ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _SoftProgressBar extends StatelessWidget {
  const _SoftProgressBar({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 6,
        value: progress,
        backgroundColor: const Color(0xFFF0F3F7),
        color: color,
      ),
    );
  }
}

class _FloatingIsland extends StatelessWidget {
  const _FloatingIsland({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25324A).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(27),
        ),
        child: child,
      ),
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({
    required this.icon,
    required this.backgroundColor,
    required this.color,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 22),
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
    return _FloatingIsland(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SoftIcon(
            icon: icon,
            backgroundColor: _kAccentSoft,
            color: _kAccent,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kInk,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _kAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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
