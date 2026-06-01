import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFF8F2EF);
const _kSurface = Colors.white;
const _kInk = Color(0xFF1F1E1D);
const _kMuted = Color(0xFF8B8581);
const _kSubtle = Color(0xFFB6B0AC);
const _kLine = Color(0xFFE8E1DD);
const _kSoft = Color(0xFFF0EBE8);
const _kAccent = AppTheme.primaryColor;
const _kAccentSoft = Color(0xFFFFECE6);
const _kPanel = Color(0xFFEEECEB);
const _kGreen = Color(0xFF21A67A);
const _kAmber = Color(0xFFE5A122);
const _kStar = Color(0xFFFFC84B);

enum _LibraryFilter {
  allDecks('Tất cả bộ'),
  allWords('Tất cả từ'),
  favoriteDecks('Bộ yêu thích'),
  favoriteWords('Từ yêu thích'),
  newWords('Từ chưa học'),
  learningWords('Từ đang học'),
  learnedWords('Từ đã học');

  const _LibraryFilter(this.label);

  final String label;

  bool get showsDecks =>
      this == _LibraryFilter.allDecks || this == _LibraryFilter.favoriteDecks;
}

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final _searchController = TextEditingController();
  _LibraryFilter _filter = _LibraryFilter.allDecks;
  String _query = '';
  bool _requestedAllCards = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectFilter(_LibraryFilter filter) {
    setState(() => _filter = filter);
    if (!filter.showsDecks && !_requestedAllCards) {
      _requestedAllCards = true;
      ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
    }
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
              _LibraryTopBar(
                onCreateDeck: () =>
                    _showCreateDeckSheet(context, asyncState.hasValue),
              ),
              _SearchField(
                controller: _searchController,
                hintText: 'Tìm từ đã lưu...',
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 14),
              _FilterRail(
                selected: _filter,
                onSelected: _selectFilter,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: asyncState.when(
                  loading: () => const _LoadingState(),
                  error: (error, _) => _ErrorState(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(flashcardProvider.notifier).refresh(),
                  ),
                  data: (state) => _LibraryBody(
                    filter: _filter,
                    query: _query,
                    state: state,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      ),
    );
  }

  void _showCreateDeckSheet(BuildContext context, bool canCreate) {
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải danh sách bộ từ.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateDeckSheet(),
    );
  }
}

class _LibraryTopBar extends StatelessWidget {
  const _LibraryTopBar({required this.onCreateDeck});

  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 20),
      child: Row(
        children: [
          const SizedBox(width: 52, height: 52),
          const Expanded(
            child: Center(
              child: _TitlePill(label: 'Từ vựng'),
            ),
          ),
          _CreateButton(onPressed: onCreateDeck),
        ],
      ),
    );
  }
}

class _TitlePill extends StatelessWidget {
  const _TitlePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _kInk,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: _kAccent, size: 28),
        ),
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.selected,
    required this.onSelected,
  });

  final _LibraryFilter selected;
  final ValueChanged<_LibraryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _kLine),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _LibraryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = _LibraryFilter.values[index];
          return _FilterChip(
            label: filter.label,
            selected: selected == filter,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kSurface : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 106, minHeight: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kInk : _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: _kSubtle,
                  size: 28,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                      strutStyle: const StrutStyle(
                        fontSize: 15,
                        height: 1,
                        forceStrutHeight: true,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          color: _kSubtle,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints.tightFor(width: 30, height: 30),
                    padding: EdgeInsets.zero,
                    onPressed: onClear,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _kMuted,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody({
    required this.filter,
    required this.query,
    required this.state,
  });

  final _LibraryFilter filter;
  final String query;
  final FlashcardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filter.showsDecks) {
      final decks = _filteredDecks();
      if (decks.isEmpty) {
        return _EmptyState(
          icon: filter == _LibraryFilter.favoriteDecks
              ? Icons.star_border_rounded
              : Icons.folder_open_rounded,
          title: filter == _LibraryFilter.favoriteDecks
              ? 'Chưa có bộ yêu thích'
              : 'Chưa có bộ từ',
          message: filter == _LibraryFilter.favoriteDecks
              ? 'Đánh dấu các bộ quan trọng để truy cập nhanh.'
              : 'Tạo bộ từ mới hoặc lưu từ qua Snap & Learn.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) => _DeckRow(
          deck: decks[index],
          onFavorite: () => _toggleDeckFavorite(context, ref, decks[index]),
          onTap: () => _openDeck(context, decks[index]),
        ),
      );
    }

    final words = _filteredWords();
    if (words.isEmpty) {
      return _EmptyState(
        icon: _emptyIconForFilter(filter),
        title: _emptyTitleForFilter(filter),
        message: 'Không có từ phù hợp với bộ lọc hiện tại.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 28),
      itemCount: words.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final item = words[index];
        return _WordRow(
          entry: item.entry,
          deckName: item.deck.name,
          onFavorite: () => _toggleCardFavorite(context, ref, item),
          onDelete: () => _confirmDeleteCard(context, ref, item),
          onTap: () => context.push(
            AppConstants.vocabDetailRoute,
            extra: VocabDetailArg(
              deckId: item.deck.id,
              deckName: item.deck.name,
              entry: item.entry,
            ),
          ),
        );
      },
    );
  }

  List<DeckData> _filteredDecks() {
    final trimmed = query.trim().toLowerCase();
    final decks = switch (filter) {
      _LibraryFilter.favoriteDecks =>
        state.decks.where((deck) => deck.isFavorite).toList(),
      _ => state.decks,
    };

    if (trimmed.isEmpty) return decks;
    return decks.where((deck) {
      return deck.name.toLowerCase().contains(trimmed);
    }).toList();
  }

  List<_DeckWordItem> _filteredWords() {
    final trimmed = query.trim().toLowerCase();
    final words = _allVocab(state);
    final filtered = switch (filter) {
      _LibraryFilter.favoriteWords =>
        words.where((item) => item.entry.isFavorite).toList(),
      _LibraryFilter.newWords =>
        words.where((item) => item.entry.isNewForStudy).toList(),
      _LibraryFilter.learningWords =>
        words.where((item) => item.entry.isLearning).toList(),
      _LibraryFilter.learnedWords => words.where((item) {
          return item.entry.isReviewing || item.entry.isMastered;
        }).toList(),
      _ => words,
    };

    if (trimmed.isEmpty) return filtered;
    return filtered.where((item) {
      return item.entry.english.toLowerCase().contains(trimmed) ||
          item.entry.translation.toLowerCase().contains(trimmed) ||
          item.deck.name.toLowerCase().contains(trimmed);
    }).toList();
  }

  Future<void> _toggleDeckFavorite(
    BuildContext context,
    WidgetRef ref,
    DeckData deck,
  ) async {
    try {
      await ref
          .read(flashcardProvider.notifier)
          .setDeckFavorite(deck.id, !deck.isFavorite);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được yêu thích: $error')),
      );
    }
  }

  Future<void> _toggleCardFavorite(
    BuildContext context,
    WidgetRef ref,
    _DeckWordItem item,
  ) async {
    try {
      await ref.read(flashcardProvider.notifier).setCardFavorite(
            item.deck.id,
            item.entry.id,
            !item.entry.isFavorite,
          );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được yêu thích: $error')),
      );
    }
  }

  Future<void> _confirmDeleteCard(
    BuildContext context,
    WidgetRef ref,
    _DeckWordItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ?'),
        content: Text('Xóa "${item.entry.english}" khỏi "${item.deck.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _kAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(flashcardProvider.notifier)
          .deleteCard(item.deck.id, item.entry.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa từ.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được từ: $error')),
      );
    }
  }

  void _openDeck(BuildContext context, DeckData deck) {
    context.push(
      AppConstants.deckRoute,
      extra: DeckArg(
        id: deck.id,
        name: deck.name,
        nameVi: deck.name,
        total: deck.total,
        learned: deck.cards.where((entry) => !entry.isNewForStudy).length,
        emoji: deck.emoji,
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({
    required this.deck,
    required this.onTap,
    required this.onFavorite,
  });

  final DeckData deck;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final learnedCount = deck.cards.where((entry) {
      return entry.isLearning || entry.isReviewing || entry.isMastered;
    }).length;
    final progress = deck.total == 0
        ? 0.0
        : (learnedCount / deck.total).clamp(0.0, 1.0).toDouble();

    return _ListCard(
      onTap: onTap,
      child: Row(
        children: [
          _DeckCover(emoji: deck.emoji),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${deck.total} thẻ',
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                _ProgressLine(progress: progress),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            tooltip: deck.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích bộ',
            icon: deck.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: deck.isFavorite ? _kStar : _kSubtle,
            onPressed: onFavorite,
          ),
          const Icon(Icons.chevron_right_rounded, color: _kSubtle, size: 26),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.entry,
    required this.deckName,
    required this.onTap,
    required this.onFavorite,
    required this.onDelete,
  });

  final FlashcardEntry entry;
  final String deckName;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _statusData(entry);

    return _ListCard(
      onTap: onTap,
      child: Row(
        children: [
          _WordCover(entry: entry),
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
                    color: _kInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entry.translation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MiniBadge(label: deckName, color: _kMuted),
                    _MiniBadge(label: status.label, color: status.color),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CircleAction(
            tooltip: entry.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích từ',
            icon: entry.isFavorite
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: entry.isFavorite ? _kStar : _kSubtle,
            onPressed: onFavorite,
          ),
          _CircleAction(
            tooltip: 'Xóa từ',
            icon: Icons.delete_outline_rounded,
            color: _kSubtle,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 126),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DeckCover extends StatelessWidget {
  const _DeckCover({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final value = emoji.trim();
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: value.isEmpty
            ? const Icon(Icons.folder_rounded, color: _kSubtle, size: 34)
            : Text(value, style: const TextStyle(fontSize: 32)),
      ),
    );
  }
}

class _WordCover extends StatelessWidget {
  const _WordCover({required this.entry});

  final FlashcardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: entry.imageUrl == null || entry.imageUrl!.isEmpty
          ? Icon(
              _iconForPartOfSpeech(entry.partOfSpeech),
              color: _kSubtle,
              size: 34,
            )
          : Image.network(
              entry.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                _iconForPartOfSpeech(entry.partOfSpeech),
                color: _kAccent,
                size: 25,
              ),
            ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 5,
        value: progress,
        color: _kAccent,
        backgroundColor: _kSoft,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: _kSoft,
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
    );
  }
}

class _Island extends StatelessWidget {
  const _Island({
    required this.child,
    required this.margin,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25324A).withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(19),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _kSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  width: 220,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _kSoft,
                    borderRadius: BorderRadius.circular(999),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _Island(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: _kAccent, size: 38),
              const SizedBox(height: 12),
              const Text(
                'Không tải được thư viện',
                style: TextStyle(
                  color: _kInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(backgroundColor: _kAccent),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 34),
        child: _Island(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: _kAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kAccent, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kInk,
                  fontSize: 18,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateDeckSheet extends ConsumerStatefulWidget {
  const _CreateDeckSheet();

  @override
  ConsumerState<_CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<_CreateDeckSheet> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedEmoji = '📚';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(flashcardProvider.notifier).addDeck(
            name,
            _selectedEmoji,
            description: description.isEmpty ? null : description,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được bộ từ: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    const emojiOptions = ['📚', '⭐', '🧠', '✏️', '🔥'];

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _kLine,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tạo bộ từ',
              style: TextStyle(
                color: _kInk,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final emoji in emojiOptions)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _selectedEmoji == emoji,
                    selectedColor: _kAccentSoft,
                    checkmarkColor: _kAccent,
                    side: BorderSide(
                      color: _selectedEmoji == emoji ? _kAccent : _kLine,
                    ),
                    onSelected: (_) => setState(() => _selectedEmoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tên bộ từ',
                hintText: 'Từ vựng du lịch',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Không bắt buộc',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tạo bộ từ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckWordItem {
  const _DeckWordItem({
    required this.deck,
    required this.entry,
  });

  final DeckData deck;
  final FlashcardEntry entry;
}

class _StatusData {
  const _StatusData(this.label, this.color);

  final String label;
  final Color color;
}

List<_DeckWordItem> _allVocab(FlashcardState state) {
  return [
    for (final deck in state.decks)
      for (final entry in deck.cards) _DeckWordItem(deck: deck, entry: entry),
  ];
}

_StatusData _statusData(FlashcardEntry entry) {
  if (entry.isLearning) return const _StatusData('Đang học', _kAmber);
  if (entry.isReviewing) return const _StatusData('Đã học', _kGreen);
  if (entry.isMastered) return const _StatusData('Đã học', _kGreen);
  return const _StatusData('Chưa học', _kAccent);
}

IconData _emptyIconForFilter(_LibraryFilter filter) {
  return switch (filter) {
    _LibraryFilter.favoriteWords => Icons.star_border_rounded,
    _LibraryFilter.newWords => Icons.fiber_new_rounded,
    _LibraryFilter.learningWords => Icons.sync_rounded,
    _LibraryFilter.learnedWords => Icons.verified_outlined,
    _ => Icons.style_rounded,
  };
}

String _emptyTitleForFilter(_LibraryFilter filter) {
  return switch (filter) {
    _LibraryFilter.favoriteWords => 'Chưa có từ yêu thích',
    _LibraryFilter.newWords => 'Không có từ chưa học',
    _LibraryFilter.learningWords => 'Không có từ đang học',
    _LibraryFilter.learnedWords => 'Không có từ đã học',
    _ => 'Chưa có từ vựng',
  };
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
    _ => Icons.style_rounded,
  };
}
