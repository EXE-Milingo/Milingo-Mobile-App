import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/floating_nav_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFFFFF8F4);
const _kAccent = Color(0xFFF25F36);
const _kDark = Color(0xFF1A1A1A);
const _kGrey = Color(0xFF9E9E9E);

// ─────────────────────────────────────────────────────────────────────────────
// Helper: simple card display model (used only in this file)
// ─────────────────────────────────────────────────────────────────────────────

class _RecentCard {
  final String word;
  final String reading;
  final String emoji;
  final String deckName;

  const _RecentCard({
    required this.word,
    required this.reading,
    required this.emoji,
    required this.deckName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  /// Collect up to 10 recent cards across all decks from the real state
  List<_RecentCard> _collectRecentCards(FlashcardState state) {
    const posEmoji = {
      'noun': '📦', 'verb': '🏃', 'adjective': '✨', 'adverb': '💨',
      'pronoun': '👤', 'preposition': '📍', 'conjunction': '🔗',
    };

    final cards = <_RecentCard>[];
    for (final deck in state.decks) {
      for (final card in deck.cards) {
        final emoji = posEmoji[card.partOfSpeech.toLowerCase()] ?? '📝';
        cards.add(_RecentCard(
          word: card.english,
          reading: '${card.translation} (${card.pronunciation})',
          emoji: emoji,
          deckName: deck.name,
        ));
      }
    }
    // Return last 10 (most recently added)
    if (cards.length > 10) {
      return cards.sublist(cards.length - 10);
    }
    return cards;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(flashcardProvider);
    final state = asyncState.valueOrNull ?? FlashcardState(decks: const []);
    final recentCards = _collectRecentCards(state);

    // Count total cards across all decks
    final totalCards = state.decks.fold<int>(0, (sum, d) => sum + d.cards.length);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _TopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          // ── Progress ring ──
                          _WordsLearnedRing(totalCards: totalCards),
                          const SizedBox(height: 20),
                          // ── Stats card ──
                          _StatsCard(totalDecks: state.decks.length, totalCards: totalCards),
                          const SizedBox(height: 28),
                          // ── Recent cards header ──
                          Row(
                            children: [
                              const Text(
                                'Thẻ gần đây',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _kDark,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => context.push(AppConstants.allCategoriesRoute),
                                child: const Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _kAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ── Swipeable recent cards or empty state ──
                          if (recentCards.isEmpty)
                            _EmptyCardsState()
                          else
                            _RecentCardsCarousel(cards: recentCards),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Floating Navigation Button (top-right) ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: const FloatingNavButton(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE — when no cards exist yet
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyCardsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'Chưa có thẻ nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy thêm từ vựng qua Snap & Learn\nđể bắt đầu ôn tập!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _kGrey),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TOP BAR: ← Ôn tập ⊕
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => context.go(AppConstants.snapAndLearnRoute),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _kDark),
            ),
          ),
          const Spacer(),
          // Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: const Text(
              'Ôn tập',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
          ),
          const Spacer(),
          // Right spacer (FloatingNavButton zone)
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WORDS LEARNED RING
// ═════════════════════════════════════════════════════════════════════════════

class _WordsLearnedRing extends StatelessWidget {
  const _WordsLearnedRing({required this.totalCards});
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    // Progress out of an estimated goal (e.g. 600 words)
    const goal = 600;
    final progress = (totalCards / goal).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ring painter
            CustomPaint(
              size: const Size(180, 180),
              painter: _RingPainter(progress: progress),
            ),
            // Center text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalCards',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: _kDark,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'WORDS LEARNED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kGrey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progress * 100).toInt()}% goal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [
          Color(0xFFF25F36),
          Color(0xFFFF8A65),
          Color(0xFFF25F36),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // start from top
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}

// ═════════════════════════════════════════════════════════════════════════════
// STATS CARD
// ═════════════════════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.totalDecks, required this.totalCards});
  final int totalDecks;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Decks count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BỘ THẺ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kGrey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalDecks',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: _kDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$totalCards từ vựng',
                  style: const TextStyle(fontSize: 11, color: _kGrey),
                ),
              ],
            ),
          ),

          // Right: Points + streak (placeholder — will connect to userStatsProvider)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kAccent,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'ĐIỂM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kGrey,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded, size: 14, color: _kAccent),
                    const SizedBox(width: 4),
                    const Text(
                      'Chuỗi · —',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RECENT CARDS CAROUSEL (swipeable) — now uses real data
// ═════════════════════════════════════════════════════════════════════════════

class _RecentCardsCarousel extends StatefulWidget {
  const _RecentCardsCarousel({required this.cards});
  final List<_RecentCard> cards;

  @override
  State<_RecentCardsCarousel> createState() => _RecentCardsCarouselState();
}

class _RecentCardsCarouselState extends State<_RecentCardsCarousel> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.72);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cards
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageCtrl,
                builder: (ctx, child) {
                  double scale = 1.0;
                  if (_pageCtrl.position.haveDimensions) {
                    double page = _pageCtrl.page ?? _currentPage.toDouble();
                    scale = (1 - (page - index).abs() * 0.1).clamp(0.9, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: _FlashcardTile(card: widget.cards[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual flashcard tile — now shows word/reading/emoji from real data
// ─────────────────────────────────────────────────────────────────────────────

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({required this.card});
  final _RecentCard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Emoji
              Text(card.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              // Word
              Text(
                card.word,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 6),
              // Reading / translation
              Text(
                card.reading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kGrey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Deck name badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _kAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.deckName,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
