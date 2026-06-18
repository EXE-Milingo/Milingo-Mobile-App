import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/flashcards/screens/flashcard_study_screen.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';

class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({required this.deck, super.key});

  final DeckArg deck;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userStatsProvider.notifier).recordStudy();
      ref.read(flashcardProvider.notifier).loadCardsForDeck(widget.deck.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(flashcardProvider);
    final liveDeck = asyncState.valueOrNull == null
        ? null
        : _findDeck(asyncState.valueOrNull!);

    // Calculate deck metrics
    final total = liveDeck?.total ?? widget.deck.total;
    final cards = liveDeck?.cards ?? const <FlashcardEntry>[];
    final learnedCount = cards.where((c) => !c.isNewForStudy).length;
    final progress = total == 0 ? 0.0 : (learnedCount / total).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final isCompleted = progress >= 1.0 && total > 0;

    // Filter cards by search query
    final entries = _filteredEntries(cards);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF7F2),
        body: SafeArea(
          child: Stack(
            children: [
              // Background Glows
              const _GlowBackground(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar: Back Button only ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: GestureDetector(
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
                  ),

                  // ── Scrollable Content ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        // ── Deck Banner Card ──
                        _DeckBannerCard(
                          name: liveDeck?.name ?? widget.deck.name,
                          emoji: liveDeck?.emoji ?? widget.deck.emoji,
                          total: total,
                          percent: percent,
                          progress: progress,
                          isCompleted: isCompleted,
                        ),
                        const SizedBox(height: 24),

                        // ── Vocabulary Header & Search ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Từ vựng',
                              style: TextStyle(
                                color: Color(0xFF1D1814),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (cards.isNotEmpty)
                              Text(
                                '${entries.length} từ',
                                style: const TextStyle(
                                  color: Color(0x8C1D1814),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── Search box inside scrollable content ──
                        _SearchBox(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 16),

                        // ── Cards List or Empty States ──
                        asyncState.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                              ),
                            ),
                          ),
                          error: (error, _) => _DeckError(message: error.toString()),
                          data: (_) {
                            if (entries.isEmpty) {
                              return const _DeckEmptyState();
                            }

                            return Column(
                              children: List.generate(entries.length, (index) {
                                final entry = entries[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _VocabRow(
                                    entry: entry,
                                    onTap: () => context.push(
                                      AppConstants.vocabDetailRoute,
                                      extra: VocabDetailArg(
                                        deckId: widget.deck.id,
                                        deckName: liveDeck?.name ?? widget.deck.name,
                                        entry: entry,
                                      ),
                                    ),
                                    onFavorite: () => _toggleCardFavorite(
                                      widget.deck.id,
                                      entry,
                                    ),
                                    onDelete: () => _confirmDeleteCard(
                                      widget.deck.id,
                                      entry,
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ],
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

  DeckData? _findDeck(FlashcardState state) {
    final matches =
        state.decks.where((deck) => deck.id == widget.deck.id).toList();
    return matches.isEmpty ? null : matches.first;
  }

  List<FlashcardEntry> _filteredEntries(List<FlashcardEntry> entries) {
    final trimmed = _query.trim().toLowerCase();
    if (trimmed.isEmpty) return entries;
    return entries.where((entry) {
      return entry.english.toLowerCase().contains(trimmed) ||
          entry.translation.toLowerCase().contains(trimmed) ||
          entry.pronunciation.toLowerCase().contains(trimmed);
    }).toList();
  }


  Future<void> _toggleCardFavorite(
    String deckId,
    FlashcardEntry entry,
  ) async {
    try {
      await ref
          .read(flashcardProvider.notifier)
          .setCardFavorite(deckId, entry.id, !entry.isFavorite);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được yêu thích: $error')),
      );
    }
  }

  Future<void> _confirmDeleteCard(
    String deckId,
    FlashcardEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xóa từ khỏi deck?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Xóa "${entry.english}" khỏi deck này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(flashcardProvider.notifier).deleteCard(deckId, entry.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa từ khỏi deck.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được từ: $error')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deck banner card component
// ─────────────────────────────────────────────────────────────────────────────

class _DeckBannerCard extends StatelessWidget {
  const _DeckBannerCard({
    required this.name,
    required this.emoji,
    required this.total,
    required this.percent,
    required this.progress,
    required this.isCompleted,
  });

  final String name;
  final String emoji;
  final int total;
  final int percent;
  final double progress;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  emoji.isEmpty ? '📚' : emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total từ vựng',
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isCompleted ? '✅ Hoàn thành' : '🔥 Đang học',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ',
                style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
              ),
              child: FractionallySizedBox(
                widthFactor: progress,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFE3B3), Colors.white],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Vocab row component
// ─────────────────────────────────────────────────────────────────────────────

class _VocabRow extends StatelessWidget {
  const _VocabRow({
    required this.entry,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  final FlashcardEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  Color _getStatusColor(String state) {
    return switch (state.toLowerCase()) {
      'mastered' => const Color(0xFF3CA45C), // Green
      'review' => const Color(0xFFFF8A1F), // Orange
      _ => const Color(0xFFF4511E), // Red (new/learning)
    };
  }

  String _getStatusLabel(String state) {
    return switch (state.toLowerCase()) {
      'mastered' => 'Thành thạo',
      'review' => 'Đang học',
      _ => 'Mới học',
    };
  }

  double _getCardProgress(FlashcardEntry card) {
    if (card.srsState == 'mastered') return 1.0;
    if (card.srsState == 'review') return 0.75;
    if (card.srsState == 'learning') return 0.4;
    return 0.1;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(entry.srsState);
    final statusLabel = _getStatusLabel(entry.srsState);
    final cardProgress = _getCardProgress(entry);

    return Material(
      color: Colors.white.withOpacity(0.85),
      borderOnForeground: true,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1814).withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6A00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: entry.imageUrl == null || entry.imageUrl!.isEmpty
                    ? Center(
                        child: Icon(
                          _iconForPartOfSpeech(entry.partOfSpeech),
                          color: const Color(0xFFFF6A00),
                          size: 22,
                        ),
                      )
                    : Image.network(
                        entry.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            _iconForPartOfSpeech(entry.partOfSpeech),
                            color: const Color(0xFFFF6A00),
                            size: 22,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.english,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1D1814),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      entry.translation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0x8C1D1814),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress Bar & Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: cardProgress,
                              backgroundColor: Colors.black.withOpacity(0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Action buttons
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onFavorite,
                icon: Icon(
                  entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: entry.isFavorite ? const Color(0xFFFFB300) : const Color(0x4D1D1814),
                  size: 24,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0x4D1D1814),
                  size: 22,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0x4D1D1814),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPartOfSpeech(String partOfSpeech) {
    return switch (partOfSpeech.toLowerCase()) {
      'noun' => Icons.category_rounded,
      'verb' => Icons.directions_run_rounded,
      'adjective' => Icons.auto_awesome_rounded,
      'adverb' => Icons.speed_rounded,
      'pronoun' => Icons.person_rounded,
      'preposition' => Icons.place_rounded,
      'conjunction' => Icons.link_rounded,
      _ => Icons.menu_book_rounded,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search box component
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: Color(0xFF1D1814),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm từ trong bộ...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Other screens components
// ─────────────────────────────────────────────────────────────────────────────

class _DeckError extends StatelessWidget {
  const _DeckError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Không tải được từ vựng\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.35),
        ),
      ),
    );
  }
}

class _DeckEmptyState extends StatelessWidget {
  const _DeckEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Chưa có từ nào trong bộ này.\nHãy thêm từ qua Snap & Learn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.35),
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
          top: 384,
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
