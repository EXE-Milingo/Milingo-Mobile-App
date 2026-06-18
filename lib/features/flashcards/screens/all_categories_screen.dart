import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AllCategoriesScreen extends ConsumerStatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  ConsumerState<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends ConsumerState<AllCategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(flashcardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7F2),
        body: SafeArea(
          child: Stack(
            children: [
              // Glassmorphic glows in the background
              const _GlowBackground(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Bar with back button & header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Color(0xFF1D1814),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bộ sưu tập',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF1D1814),
                                  letterSpacing: -0.45,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Khám phá tất cả chủ đề từ vựng',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0x991D1814),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Search Bar ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEFECE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(fontSize: 14, color: Color(0xFF1D1814)),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bộ từ...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  // ── Decks Grid ──
                  Expanded(
                    child: asyncState.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'Không tải được dữ liệu\n$error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ),
                      ),
                      data: (state) {
                        final filteredDecks = state.decks.where((deck) {
                          return deck.name.toLowerCase().contains(_query.toLowerCase());
                        }).toList();

                        if (filteredDecks.isEmpty) {
                          return const Center(
                            child: Text(
                              'Không tìm thấy bộ sưu tập nào.',
                              style: TextStyle(
                                color: Color(0x8C1D1814),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: filteredDecks.length,
                          itemBuilder: (context, i) {
                            final deck = filteredDecks[i];
                            return _DeckGridCard(
                              deck: deck,
                              index: i,
                              onTap: () {
                                final learnedCount = deck.cards.where((entry) => !entry.isNewForStudy).length;
                                context.push(
                                  AppConstants.deckRoute,
                                  extra: DeckArg(
                                    id: deck.id,
                                    name: deck.name,
                                    nameVi: deck.name,
                                    total: deck.total,
                                    learned: learnedCount,
                                    emoji: deck.emoji,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck grid card
// ─────────────────────────────────────────────────────────────────────────────

class _DeckGridCard extends StatelessWidget {
  const _DeckGridCard({
    required this.deck,
    required this.index,
    required this.onTap,
  });

  final DeckData deck;
  final int index;
  final VoidCallback onTap;

  List<Color> _getDeckGradient(int index) {
    final gradients = [
      [const Color(0xFFFFF1E6), const Color(0xFFFFE2CC)], // Orange/Peach
      [const Color(0xFFE8F1FF), const Color(0xFFD5E6FF)], // Blue
      [const Color(0xFFF0EAFF), const Color(0xFFE2D6FF)], // Purple
      [const Color(0xFFE9F7EC), const Color(0xFFD4F0DC)], // Green
      [const Color(0xFFFFEAF2), const Color(0xFFFFD6E6)], // Pink
      [const Color(0xFFFFFAEC), const Color(0xFFFFE9C2)], // Yellow
    ];
    return gradients[index % gradients.length];
  }

  Color _getDeckAccentColor(int index) {
    final colors = [
      const Color(0xFFFF6A00), // Orange
      const Color(0xFF2E7DEB), // Blue
      const Color(0xFF5B5BD6), // Indigo
      const Color(0xFF3CA45C), // Green
      const Color(0xFFE5468A), // Pink
      const Color(0xFFD69E00), // Gold
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getDeckGradient(index);
    final accentColor = _getDeckAccentColor(index);
    
    final total = deck.total;
    final learned = deck.cards.where((card) => !card.isNewForStudy).length;
    final progress = total == 0 ? 0.0 : (learned / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final isCompleted = progress >= 1.0 && total > 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D1814).withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    deck.emoji.isEmpty ? '📚' : deck.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, color: Colors.white, size: 10),
                        SizedBox(width: 2),
                        Text(
                          'Hoàn thành',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deck.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D1814),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$total từ',
              style: TextStyle(
                color: const Color(0xFF1D1814).withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow background components
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -64,
          top: -64,
          child: _GlowBlob(size: 288, color: const Color(0x33FF8A1F)),
        ),
        Positioned(
          left: -96,
          top: 320,
          child: _GlowBlob(size: 256, color: const Color(0x1AFF4D1A)),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

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
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
