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
const _kDark = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF8F8F8F);
const _kBorder = Color(0xFFE8E2DE);
const _kSoft = Color(0xFFFFEDE7);

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
                onTabSelected: _selectTab,
                onCreateDeck: () => _showCreateDeckSheet(context, asyncState.hasValue),
              ),
              _SearchBox(
                controller: _searchController,
                hintText: _tabIndex == 0 ? 'Tìm kiếm bộ từ...' : 'Tìm kiếm từ vựng...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncState.when(
                  loading: () => const _LoadingState(),
                  error: (error, _) => _ErrorState(
                    message: error.toString(),
                    onRetry: () => ref.read(flashcardProvider.notifier).refresh(),
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
    required this.onTabSelected,
    required this.onCreateDeck,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCreateDeck;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Thư viện',
                  style: TextStyle(
                    color: _kDark,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Tạo bộ từ',
                onPressed: onCreateDeck,
                icon: const Icon(Icons.add_rounded, color: _kDark, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kTabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;
                return _TabPill(
                  label: _kTabs[index],
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
      color: selected ? Colors.transparent : const Color(0xFFFFEEE9),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? _kAccent : Colors.transparent,
          width: selected ? 1.8 : 0,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _kDark : const Color(0xFF5E5A58),
              fontSize: 14,
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
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: _kDark, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFB8B3B0), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB8B3B0), size: 24),
          filled: true,
          fillColor: _kSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

class _FlashcardTabBody extends StatelessWidget {
  const _FlashcardTabBody({
    required this.tabIndex,
    required this.query,
    required this.state,
  });

  final int tabIndex;
  final String query;
  final FlashcardState state;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        itemCount: decks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _DeckLibraryRow(
          deck: decks[index],
          onTap: () => _openDeck(context, decks[index]),
        ),
      );
    }

    final vocabItems = _filteredVocab();
    if (vocabItems.isEmpty) {
      return _EmptyState(
        icon: _emptyIconForTab(),
        title: _emptyTitleForTab(),
        message: _emptyMessageForTab(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: vocabItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = vocabItems[index];
        return _VocabLibraryRow(
          entry: item.entry,
          deckName: item.deck.name,
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
        for (final entry in deck.cards) _DeckVocabItem(deck: deck, entry: entry),
    ];

    final tabFiltered = switch (tabIndex) {
      1 => all,
      2 => const <_DeckVocabItem>[],
      3 => const <_DeckVocabItem>[],
      4 => all,
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

  String _emptyTitleForTab() {
    return switch (tabIndex) {
      2 => 'Chưa có từ yêu thích',
      3 => 'Chưa có từ đã học',
      4 => 'Chưa có từ chưa học',
      _ => 'Chưa có từ vựng',
    };
  }

  String _emptyMessageForTab() {
    return switch (tabIndex) {
      2 => 'Khi có dữ liệu yêu thích từ API, các từ sẽ xuất hiện ở đây.',
      3 => 'Khi có tiến độ học từng từ từ API, các từ sẽ xuất hiện ở đây.',
      4 => 'Mở một bộ từ để tải danh sách từ vựng.',
      _ => 'Mở một bộ từ để tải danh sách từ vựng.',
    };
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

class _DeckLibraryRow extends StatelessWidget {
  const _DeckLibraryRow({
    required this.deck,
    required this.onTap,
  });

  final DeckData deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = deck.total;

    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 78),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Học phần  ·  $count thuật ngữ',
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4BFBC), size: 26),
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
  });

  final FlashcardEntry entry;
  final String deckName;
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
              _IconTile(
                child: Icon(_iconForPartOfSpeech(entry.partOfSpeech), color: _kAccent, size: 26),
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
                      '${entry.translation}  ·  $deckName',
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
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4BFBC), size: 26),
            ],
          ),
        ),
      ),
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
        color: _kSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: _kAccent));
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
              style: TextStyle(color: _kDark, fontSize: 17, fontWeight: FontWeight.w800),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(color: _kSoft, shape: BoxShape.circle),
              child: Icon(icon, color: _kAccent, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kDark, fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted, fontSize: 13, height: 1.35),
            ),
          ],
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
              style: TextStyle(color: _kDark, fontSize: 20, fontWeight: FontWeight.w900),
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
                      color: _selectedEmoji == emoji ? _kAccent : const Color(0xFFE8E8E8),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Tạo bộ từ', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
