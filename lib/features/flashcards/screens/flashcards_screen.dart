import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1F1B18);
const _kMuted = Color(0xFF8E817A);
const _kSubtle = Color(0xFFB8ADA6);
const _kBorder = Color(0xFFF0E4DE);
const _kSoft = Color(0xFFFFEDE7);
const _kWarm = Color(0xFFFFF2EC);
const _kStar = Color(0xFFFFC84B);

const _kTabs = [
  'Tất cả bộ',
  'Tất cả từ vựng',
  'Từ vựng yêu thích',
  'Từ đã học',
  'Từ chưa học',
];

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  final _searchController = TextEditingController();
  int _tabIndex = 0;
  String _query = '';
  bool _requestedAllCards = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() => _tabIndex = index);
    if (index > 0 && !_requestedAllCards) {
      _requestedAllCards = true;
      ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(flashcardProvider);
    final data = asyncState.valueOrNull;
    final totalDecks = data?.decks.length ?? 0;
    final totalWords =
        data?.decks.fold<int>(0, (sum, deck) => sum + deck.total) ?? 0;
    final dueWords = data?.decks.fold<int>(
          0,
          (sum, deck) =>
              sum + deck.cards.where((entry) => entry.isNewForStudy).length,
        ) ??
        0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LibraryHeader(
                selectedIndex: _tabIndex,
                totalDecks: totalDecks,
                totalWords: totalWords,
                dueWords: dueWords,
                isLoading: asyncState.isLoading && data == null,
                onTabSelected: _selectTab,
                onCreateDeck: () =>
                    _showCreateDeckSheet(context, asyncState.hasValue),
              ),
              _SearchBox(
                controller: _searchController,
                hintText: _tabIndex == 0
                    ? 'Tìm kiếm bộ từ...'
                    : 'Tìm kiếm từ vựng...',
                onChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncState.when(
                  loading: () => const _LoadingState(),
                  error: (error, _) => _ErrorState(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(flashcardProvider.notifier).refresh(),
                  ),
                  data: (data) => _FlashcardTabBody(
                    tabIndex: _tabIndex,
                    query: _query,
                    state: data,
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

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.selectedIndex,
    required this.totalDecks,
    required this.totalWords,
    required this.dueWords,
    required this.isLoading,
    required this.onTabSelected,
    required this.onCreateDeck,
  });

  final int selectedIndex;
  final int totalDecks;
  final int totalWords;
  final int dueWords;
  final bool isLoading;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thư viện',
                      style: TextStyle(
                        color: _kDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sắp xếp bộ từ, lưu lại từ hay và ôn tập nhanh.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _kMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _CreateDeckButton(onPressed: onCreateDeck),
            ],
          ),
          const SizedBox(height: 18),
          _LibraryStatsStrip(
            selectedIndex: selectedIndex,
            totalDecks: totalDecks,
            totalWords: totalWords,
            dueWords: dueWords,
            isLoading: isLoading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                return _TabPill(
                  label: _tabLabel(index),
                  selected: selected,
                  onTap: () => onTabSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateDeckButton extends StatelessWidget {
  const _CreateDeckButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kAccent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

String _tabLabel(int index) {
  return switch (index) {
    0 => 'Bộ từ',
    1 => 'Tất cả từ',
    2 => 'Đến hạn',
    3 => 'Đang học',
    4 => 'Đã vững',
    _ => 'Từ vựng',
  };
}

class _LibraryStatsStrip extends StatelessWidget {
  const _LibraryStatsStrip({
    required this.selectedIndex,
    required this.totalDecks,
    required this.totalWords,
    required this.dueWords,
    required this.isLoading,
  });

  final int selectedIndex;
  final int totalDecks;
  final int totalWords;
  final int dueWords;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatPill(
              icon: Icons.folder_copy_rounded,
              label: 'Bộ từ',
              value: isLoading ? '-' : '$totalDecks',
              selected: selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _StatPill(
              icon: Icons.menu_book_rounded,
              label: 'Từ vựng',
              value: isLoading ? '-' : '$totalWords',
              selected: selectedIndex == 1,
            ),
          ),
          Expanded(
            child: _StatPill(
              icon: Icons.bolt_rounded,
              label: 'Yêu thích',
              value: isLoading ? '-' : '$dueWords',
              selected: selectedIndex == 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _kWarm : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: selected ? _kAccent : _kSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : _kAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _statLabel(icon, label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
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

String _statLabel(IconData icon, String fallback) {
  if (icon == Icons.folder_copy_rounded) return 'Bộ';
  if (icon == Icons.menu_book_rounded) return 'Từ';
  if (icon == Icons.bolt_rounded) return 'Đến hạn';
  return fallback;
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
      color: selected ? _kAccent : _kWarm,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? _kAccent : _kBorder,
          width: 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
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
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
            color: _kDark, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB8B3B0), fontSize: 15),
          prefixIcon:
              const Icon(Icons.search_rounded, color: _kSubtle, size: 23),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _kMuted,
                    size: 20,
                  ),
                ),
          filled: true,
          fillColor: _kSurface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _kAccent, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _FlashcardTabBody extends ConsumerWidget {
  const _FlashcardTabBody({
    required this.tabIndex,
    required this.query,
    required this.state,
  });

  final int tabIndex;
  final String query;
  final FlashcardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tabIndex == 0) {
      final decks = _filteredDecks();
      if (decks.isEmpty) {
        return const _EmptyState(
          icon: Icons.style_rounded,
          title: 'Chưa có bộ từ',
          message: 'Tạo bộ từ mới hoặc lưu từ qua Snap & Learn.',
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _DeckLibraryRow(
          deck: decks[index],
          onFavorite: () => _toggleDeckFavorite(context, ref, decks[index]),
          onTap: () => _openDeck(context, decks[index]),
        ),
      );
    }

    final vocabItems = _filteredVocab();
    if (vocabItems.isEmpty) {
      return _EmptyState(
        icon: _emptyIconForTab(),
        title: _emptyTitleForSrsTab(tabIndex),
        message: _emptyMessageForSrsTab(tabIndex),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      itemCount: vocabItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = vocabItems[index];
        return _VocabLibraryRow(
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
    if (trimmed.isEmpty) return state.decks;
    return state.decks.where((deck) {
      return deck.name.toLowerCase().contains(trimmed);
    }).toList();
  }

  List<_DeckVocabItem> _filteredVocab() {
    final trimmed = query.trim().toLowerCase();
    final all = [
      for (final deck in state.decks)
        for (final entry in deck.cards)
          _DeckVocabItem(deck: deck, entry: entry),
    ];

    final tabFiltered = switch (tabIndex) {
      1 => all,
      2 => all.where((item) => item.entry.isNewForStudy).toList(),
      3 => all.where((item) => item.entry.isLearning).toList(),
      4 => all
          .where((item) => item.entry.isReviewing || item.entry.isMastered)
          .toList(),
      _ => all,
    };

    if (trimmed.isEmpty) return tabFiltered;
    return tabFiltered.where((item) {
      return item.entry.english.toLowerCase().contains(trimmed) ||
          item.entry.translation.toLowerCase().contains(trimmed) ||
          item.deck.name.toLowerCase().contains(trimmed);
    }).toList();
  }

  IconData _emptyIconForTab() {
    return switch (tabIndex) {
      2 => Icons.star_border_rounded,
      3 => Icons.check_circle_outline_rounded,
      4 => Icons.school_outlined,
      _ => Icons.menu_book_rounded,
    };
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
    _DeckVocabItem item,
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
    _DeckVocabItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ khỏi tất cả từ vựng?'),
        content:
            Text('Xóa "${item.entry.english}" khỏi deck ${item.deck.name}.'),
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
        learned: deck.cards.length,
        emoji: deck.emoji,
      ),
    );
  }
}

class _DeckVocabItem {
  const _DeckVocabItem({required this.deck, required this.entry});

  final DeckData deck;
  final FlashcardEntry entry;
}

String _emptyTitleForSrsTab(int tabIndex) {
  return switch (tabIndex) {
    2 => 'Chưa có từ đến hạn',
    3 => 'Chưa có từ đang học',
    4 => 'Chưa có từ đã ôn',
    _ => 'Chưa có từ vựng',
  };
}

String _emptyMessageForSrsTab(int tabIndex) {
  return switch (tabIndex) {
    2 => 'Các thẻ mới hoặc đến lịch ôn sẽ xuất hiện ở đây.',
    3 => 'Những thẻ đang củng cố sẽ xuất hiện ở đây.',
    4 => 'Những thẻ ôn tập và đã vững sẽ xuất hiện ở đây.',
    _ => 'Mở một bộ từ hoặc lưu từ từ Chụp để bắt đầu.',
  };
}

class _DeckLibraryRow extends StatelessWidget {
  const _DeckLibraryRow({
    required this.deck,
    required this.onTap,
    required this.onFavorite,
  });

  final DeckData deck;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final count = deck.total;
    final loadedCount = deck.cards.length;
    final progress =
        count == 0 ? 0.0 : (loadedCount / count).clamp(0.0, 1.0).toDouble();

    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconTile(
                child: Text(
                  deck.emoji.isEmpty ? '📚' : deck.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        const _MetaChip(
                          icon: Icons.layers_rounded,
                          label: 'Học phần',
                        ),
                        _MetaChip(
                          icon: Icons.menu_book_rounded,
                          label: '$count thuật ngữ',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: progress,
                        backgroundColor: _kSoft,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_kAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _RoundIconAction(
                tooltip: deck.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích deck',
                onPressed: onFavorite,
                icon: deck.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: deck.isFavorite ? _kStar : _kSubtle,
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded,
                  color: _kSubtle, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabLibraryRow extends StatelessWidget {
  const _VocabLibraryRow({
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
    final partOfSpeech = entry.partOfSpeech.trim();

    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.07),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconTile(
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.translation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.collections_bookmark_rounded,
                          label: deckName,
                        ),
                        _SrsMetaChip(entry: entry),
                        if (partOfSpeech.isNotEmpty)
                          _MetaChip(
                            icon: _iconForPartOfSpeech(partOfSpeech),
                            label: partOfSpeech,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RoundIconAction(
                tooltip: entry.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích từ',
                onPressed: onFavorite,
                icon: entry.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: entry.isFavorite ? _kStar : _kSubtle,
              ),
              _RoundIconAction(
                tooltip: 'Xóa từ',
                onPressed: onDelete,
                icon: Icons.delete_outline_rounded,
                color: _kSubtle,
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _kSubtle, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _kWarm,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kAccent, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SrsMetaChip extends StatelessWidget {
  const _SrsMetaChip({required this.entry});

  final FlashcardEntry entry;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _srsChipData(entry);

    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

(String, IconData, Color) _srsChipData(FlashcardEntry entry) {
  return switch (entry.srsState) {
    'learning' => ('Đang học', Icons.sync_rounded, const Color(0xFFE19A2B)),
    'review' => ('Ôn tập', Icons.event_available_rounded, _kAccent),
    'mastered' => ('Đã vững', Icons.verified_rounded, const Color(0xFF2EAD62)),
    _ => ('Mới', Icons.bolt_rounded, _kAccent),
  };
}

class _RoundIconAction extends StatelessWidget {
  const _RoundIconAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: _kWarm,
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0EB), Color(0xFFFFE2D6)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _kWarm,
              borderRadius: BorderRadius.circular(16),
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
                    color: _kWarm,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 210,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _kWarm,
                    borderRadius: BorderRadius.circular(99),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _kAccent, size: 38),
            const SizedBox(height: 10),
            const Text(
              'Không tải được thư viện',
              style: TextStyle(
                  color: _kDark, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              child: const Text('Thử lại'),
            ),
          ],
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: _kWarm,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kAccent, size: 32),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tạo bộ từ',
              style: TextStyle(
                  color: _kDark, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final emoji in emojiOptions)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _selectedEmoji == emoji,
                    selectedColor: _kSoft,
                    checkmarkColor: _kAccent,
                    side: BorderSide(
                      color: _selectedEmoji == emoji
                          ? _kAccent
                          : const Color(0xFFE8E8E8),
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tạo bộ từ',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
