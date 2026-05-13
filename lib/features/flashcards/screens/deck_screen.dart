import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/widgets/vocab_card.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Design tokens ─────────────────────────────────────────
const _kBg     = Color(0xFFFFF8F4);
const _kDark   = Color(0xFF1A1A1A);

// ── Helper: convert FlashcardEntry → VocabItem for VocabCard ──
VocabItem _entryToVocabItem(FlashcardEntry entry, {bool isNew = false}) {
  // Pick a sensible emoji based on partOfSpeech, fallback to 📝
  const _posEmoji = {
    'noun': '📦', 'verb': '🏃', 'adjective': '✨', 'adverb': '💨',
    'pronoun': '👤', 'preposition': '📍', 'conjunction': '🔗',
  };
  final emoji = _posEmoji[entry.partOfSpeech.toLowerCase()] ?? '📝';

  return VocabItem(
    word: entry.english,
    reading: '${entry.translation} (${entry.pronunciation})',
    emoji: emoji,
    isNew: isNew,
  );
}

// ── Screen ────────────────────────────────────────────────

class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key, required this.deck});
  final DeckArg deck;

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  int _filterIndex = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Ghi nhận học flashcard hôm nay — idempotent, an toàn khi gọi nhiều lần
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userStatsProvider.notifier).recordStudy();
      // Load cards for this deck from the API
      ref.read(flashcardProvider.notifier).loadCardsForDeck(widget.deck.id);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Get VocabItem list from the real flashcard state
  List<VocabItem> get _filtered {
    // Get the current deck's cards from the provider
    final flashcardState = ref.read(flashcardProvider).valueOrNull ??
        FlashcardState(decks: const []);
    final deck = flashcardState.decks
        .where((d) => d.id == widget.deck.id)
        .toList();
    final entries = deck.isNotEmpty ? deck.first.cards : <FlashcardEntry>[];

    // Convert FlashcardEntry → VocabItem
    final all = entries.asMap().entries.map((e) {
      // Mark the first 3 items as "new" for visual indicator
      return _entryToVocabItem(e.value, isNew: e.key < 3);
    }).toList();

    List<VocabItem> list;
    switch (_filterIndex) {
      case 1: // Recent — show last 3 added
        list = all.length > 3 ? all.sublist(all.length - 3) : all;
      case 2: // Saved — all non-new
        list = all.where((v) => !v.isNew).toList();
      default:
        list = all;
    }
    if (_query.isNotEmpty) {
      list = list
          .where((v) =>
              v.word.toLowerCase().contains(_query.toLowerCase()) ||
              v.reading.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so UI rebuilds when cards load
    final asyncState = ref.watch(flashcardProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: asyncState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF25F36)),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Không tải được thẻ\n$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                data: (_) => Column(
                  children: [
                    _buildSearchBar(),
                    _buildFilterTabs(),
                    const SizedBox(height: 4),
                    Expanded(child: _buildVocabList()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _kDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          // Pill-shaped title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
            ),
            child: const Text(
              'Thẻ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kDark,
              ),
            ),
          ),
          const Spacer(),
          // Plus icon (add word)
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
              ),
              child: const Icon(Icons.add_rounded,
                  color: _kDark, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Tìm từ đã lưu...',
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFBDBDBD), size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Filter tabs ─────────────────────────────────────────
  Widget _buildFilterTabs() {
    const labels = ['Tất cả', 'Gần đây', 'Đã lưu'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == _filterIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Vocab list ──────────────────────────────────────────
  Widget _buildVocabList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có từ nào trong bộ thẻ này\nHãy thêm từ qua Snap & Learn!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => VocabCard(item: items[i]),
    );
  }
}

