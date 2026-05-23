import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF8F8F8F);
const _kBorder = Color(0xFFE8E2DE);
const _kSoft = Color(0xFFFFEDE7);

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeckHeader(deck: widget.deck),
              _SearchBox(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _kAccent),
                  ),
                  error: (error, _) => _DeckError(message: error.toString()),
                  data: (state) {
                    final deck = _findDeck(state);
                    final entries = _filteredEntries(deck?.cards ?? const []);

                    if (entries.isEmpty) {
                      return const _DeckEmptyState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _VocabRow(
                          entry: entry,
                          onTap: () => context.push(
                            AppConstants.vocabDetailRoute,
                            extra: VocabDetailArg(
                              deckId: widget.deck.id,
                              deckName: widget.deck.name,
                              entry: entry,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.deck});

  final DeckArg deck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 18, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _kDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text(
              deck.emoji.isEmpty ? '📚' : deck.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deck.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${deck.total} thuật ngữ',
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
            color: _kDark, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm từ trong bộ...',
          hintStyle: const TextStyle(color: Color(0xFFB8B3B0), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFB8B3B0), size: 24),
          filled: true,
          fillColor: _kSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _VocabRow extends StatelessWidget {
  const _VocabRow({
    required this.entry,
    required this.onTap,
  });

  final FlashcardEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _kSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: entry.imageUrl == null || entry.imageUrl!.isEmpty
                    ? Icon(_iconForPartOfSpeech(entry.partOfSpeech),
                        color: _kAccent, size: 26)
                    : Image.network(
                        entry.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          _iconForPartOfSpeech(entry.partOfSpeech),
                          color: _kAccent,
                          size: 26,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.english,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.translation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFC4BFBC), size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckError extends StatelessWidget {
  const _DeckError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Không tải được từ vựng\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kMuted, fontSize: 14, height: 1.35),
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
        padding: EdgeInsets.all(28),
        child: Text(
          'Chưa có từ nào trong bộ này.\nHãy thêm từ qua Snap & Learn.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kMuted, fontSize: 14, height: 1.35),
        ),
      ),
    );
  }
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
