import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';

class VocabularyDashboardColors {
  const VocabularyDashboardColors._();

  static const background = Color(0xFFFBF7F2);
  static const accent = AppTheme.primaryColor;
  static const accentDeep = Color(0xFFFF4D1A);
  static const ink = Color(0xFF1D1814);
  static const muted = Color(0x8C1D1814);
  static const border = Colors.white;
}

class VocabularyDashboardBackground extends StatelessWidget {
  const VocabularyDashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          right: -80,
          top: -70,
          child: _Glow(size: 288, color: Color(0x33FF8A1F)),
        ),
        Positioned(
          left: -110,
          top: 300,
          child: _Glow(size: 256, color: Color(0x1AFF4D1A)),
        ),
        Positioned(
          right: -20,
          bottom: 70,
          child: _Glow(size: 256, color: Color(0x1FFACC15)),
        ),
      ],
    );
  }
}

class VocabularyDashboardHeader extends StatelessWidget {
  const VocabularyDashboardHeader({
    required this.title,
    required this.onCreateDeck,
    super.key,
  });

  final String title;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 44, height: 44),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: VocabularyDashboardColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
        _RoundIconButton(
          tooltip: 'Tạo bộ từ',
          icon: Icons.add_rounded,
          onTap: onCreateDeck,
        ),
      ],
    );
  }
}

class VocabularyHeroCard extends StatelessWidget {
  const VocabularyHeroCard({required this.totalWords, super.key});

  final int totalWords;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 292,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: VocabularyDashboardColors.accent.withValues(alpha: 0.24),
            blurRadius: 50,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 218,
                height: 218,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const _Glow(size: 158, color: Color(0x4DFF6A00)),
                    CustomPaint(
                      size: const Size.square(218),
                      painter: _VocabularyRingPainter(),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 154,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$totalWords',
                              maxLines: 1,
                              style: const TextStyle(
                                color: VocabularyDashboardColors.ink,
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'TỪ VỰNG ĐÃ QUÉT',
                          style: TextStyle(
                            color: VocabularyDashboardColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const _ScanHistoryButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class VocabularyCollectionSection extends StatelessWidget {
  const VocabularyCollectionSection({
    required this.decks,
    required this.showSeeAll,
    required this.onSeeAll,
    required this.onDeckTap,
    super.key,
  });

  final List<DeckData> decks;
  final bool showSeeAll;
  final VoidCallback onSeeAll;
  final ValueChanged<DeckData> onDeckTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bộ sưu tập của bạn',
                style: TextStyle(
                  color: VocabularyDashboardColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
            if (showSeeAll)
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  foregroundColor: VocabularyDashboardColors.accentDeep,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (decks.isEmpty)
          const _EmptyCollectionCard()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var i = 0; i < decks.length; i++)
                    SizedBox(
                      width: width,
                      child: _DeckCollectionCard(
                        deck: decks[i],
                        color: _deckColor(i),
                        onTap: () => onDeckTap(decks[i]),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class VocabularyReviewBanner extends StatelessWidget {
  const VocabularyReviewBanner({
    required this.dueCount,
    required this.onTap,
    super.key,
  });

  final int? dueCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final message = dueCount == null
        ? 'Đang kiểm tra từ cần ôn tập nè'
        : 'Bạn có $dueCount từ cần ôn tập nè, bấm vào đây để ôn tập ngay';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                VocabularyDashboardColors.accent,
                VocabularyDashboardColors.accentDeep,
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: VocabularyDashboardColors.accent.withValues(alpha: 0.32),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned(
                right: -36,
                top: -42,
                child: Container(
                  width: 144,
                  height: 144,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 20,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Ôn tập ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ôn tập ngay',
                            style: TextStyle(
                              color: VocabularyDashboardColors.accentDeep,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: VocabularyDashboardColors.accentDeep,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VocabularyDashboardLoading extends StatelessWidget {
  const VocabularyDashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const VocabularyDashboardBackground(),
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: const [
            VocabularyDashboardHeader(title: 'Từ vựng', onCreateDeck: _noop),
            SizedBox(height: 16),
            _Skeleton(height: 292, radius: 36),
            SizedBox(height: 28),
            _Skeleton(height: 180, radius: 24),
            SizedBox(height: 22),
            _Skeleton(height: 190, radius: 32),
          ],
        ),
      ],
    );
  }
}

class VocabularyDashboardError extends StatelessWidget {
  const VocabularyDashboardError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const VocabularyDashboardBackground(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: VocabularyDashboardColors.accent,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không tải được từ vựng',
                    style: TextStyle(
                      color: VocabularyDashboardColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: VocabularyDashboardColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: VocabularyDashboardColors.accent,
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckCollectionCard extends StatelessWidget {
  const _DeckCollectionCard({
    required this.deck,
    required this.color,
    required this.onTap,
  });

  final DeckData deck;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = deck.emoji.trim();

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: VocabularyDashboardColors.ink.withValues(alpha: 0.09),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: emoji.isEmpty
                      ? const Icon(
                          Icons.menu_book_rounded,
                          color: VocabularyDashboardColors.accent,
                          size: 22,
                        )
                      : Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VocabularyDashboardColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${deck.total} từ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VocabularyDashboardColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanHistoryButton extends StatelessWidget {
  const _ScanHistoryButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VocabularyDashboardColors.accent,
            VocabularyDashboardColors.accentDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: VocabularyDashboardColors.accent.withValues(alpha: 0.42),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'LỊCH SỬ QUÉT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCollectionCard extends StatelessWidget {
  const _EmptyCollectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: const Text(
        'Chưa có bộ sưu tập',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: VocabularyDashboardColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: VocabularyDashboardColors.accent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white),
      ),
    );
  }
}

class _VocabularyRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2 - 18;
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          VocabularyDashboardColors.accent.withValues(alpha: 0.36),
          VocabularyDashboardColors.accent.withValues(alpha: 0.16),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 8));
    final active = Paint()
      ..shader = const SweepGradient(
        colors: [
          VocabularyDashboardColors.accent,
          VocabularyDashboardColors.accentDeep,
          VocabularyDashboardColors.accent,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 10, fill);
    canvas.drawCircle(center, radius, active);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _deckColor(int index) {
  const colors = [
    Color(0xFFFFF1E6),
    Color(0xFFFFEAE0),
    Color(0xFFE8F1FF),
    Color(0xFFE9F7EC),
    Color(0xFFFFF4D9),
    Color(0xFFF3EAFE),
  ];
  return colors[index % colors.length];
}

void _noop() {}
