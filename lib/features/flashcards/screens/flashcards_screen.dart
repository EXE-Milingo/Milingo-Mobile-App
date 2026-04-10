import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/shared/widgets/floating_nav_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFFFFF8F4);
const _kAccent = Color(0xFFF25F36);
const _kDark = Color(0xFF1A1A1A);
const _kGrey = Color(0xFF9E9E9E);

// ─────────────────────────────────────────────────────────────────────────────
// Mock recent-card data
// ─────────────────────────────────────────────────────────────────────────────

class _RecentCard {
  final String imagePath;
  final String word;
  final String reading;
  final String lang;

  const _RecentCard({
    required this.imagePath,
    required this.word,
    required this.reading,
    required this.lang,
  });
}

const _kRecentCards = [
  _RecentCard(imagePath: 'assets/images/dog_beach.png', word: '犬', reading: 'Inu', lang: 'NHẬT'),
  _RecentCard(imagePath: 'assets/images/dog_beach.png', word: 'Dog', reading: 'Dog', lang: 'ANH'),
  _RecentCard(imagePath: 'assets/images/dog_beach.png', word: '狗', reading: 'Gǒu', lang: 'TRUNG'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                          const _WordsLearnedRing(),
                          const SizedBox(height: 20),
                          // ── Stats card ──
                          const _StatsCard(),
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
                          // ── Swipeable recent cards ──
                          const _RecentCardsCarousel(),
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
  const _WordsLearnedRing();

  @override
  Widget build(BuildContext context) {
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
              painter: _RingPainter(progress: 0.72),
            ),
            // Center text
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '428',
                  style: TextStyle(
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
                  child: const Text(
                    '+12 today',
                    style: TextStyle(
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
  const _StatsCard();

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
          // Left: Rank
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HẠNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kGrey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '#4',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _kDark,
                          height: 1.1,
                        ),
                      ),
                      TextSpan(
                        text: 'th',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _kGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Top 12% • ↑3 Từ tuần trước',
                  style: TextStyle(fontSize: 11, color: _kGrey),
                ),
                const SizedBox(height: 2),
                const Text(
                  '62% to #3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),

          // Right: Points + streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '3,540',
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
                      'Chuỗi · 14',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _kAccent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Rank #3: 3,990 pts',
                style: TextStyle(fontSize: 10, color: _kGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RECENT CARDS CAROUSEL (swipeable)
// ═════════════════════════════════════════════════════════════════════════════

class _RecentCardsCarousel extends StatefulWidget {
  const _RecentCardsCarousel();

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
          height: 340,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _kRecentCards.length,
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
                child: _FlashcardTile(card: _kRecentCards[index]),
              );
            },
          ),
        ),


      ],
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Individual flashcard tile
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
        child: Column(
          children: [
            // Image + overlays
            Expanded(
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.asset(
                      card.imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Top-left: speaker icon
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.volume_up_rounded, size: 18, color: _kAccent),
                    ),
                  ),
                  // Top-right: favorite star
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_border_rounded, size: 18, color: _kGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
