import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

// ── Mock vocab model ──────────────────────────────────────

class VocabItem {
  const VocabItem({
    required this.word,
    required this.reading,
    required this.emoji,
    this.isNew = false,
  });
  final String word;
  final String reading;
  final String emoji;
  final bool isNew;
}

// ── Per-deck sample data ──────────────────────────────────

const _kSampleVocab = <String, List<VocabItem>>{
  'nouns': [
    VocabItem(word: 'Pen',       reading: '鉛筆 (Enpitsu)',           emoji: '✏️', isNew: true),
    VocabItem(word: 'Cat',       reading: '猫 (Neko)',                emoji: '🐱'),
    VocabItem(word: 'Laptop',    reading: 'ノートパソコン (Nōto)',       emoji: '💻'),
    VocabItem(word: 'Headphones',reading: 'ヘッドホン (Heddohon)',      emoji: '🎧'),
    VocabItem(word: 'Book',      reading: '本 (Hon)',                  emoji: '📖'),
    VocabItem(word: 'Chair',     reading: '椅子 (Isu)',                emoji: '🪑'),
    VocabItem(word: 'Table',     reading: 'テーブル (Tēburu)',          emoji: '🪵'),
  ],
  'adjectives': [
    VocabItem(word: 'Beautiful', reading: '美しい (Utsukushii)',       emoji: '✨', isNew: true),
    VocabItem(word: 'Fast',      reading: '速い (Hayai)',              emoji: '⚡'),
    VocabItem(word: 'Tall',      reading: '高い (Takai)',              emoji: '📏'),
  ],
  'verbs': [
    VocabItem(word: 'Run',       reading: '走る (Hashiru)',            emoji: '🏃', isNew: true),
    VocabItem(word: 'Eat',       reading: '食べる (Taberu)',           emoji: '🍽️'),
    VocabItem(word: 'Sleep',     reading: '寝る (Neru)',               emoji: '😴'),
    VocabItem(word: 'Read',      reading: '読む (Yomu)',               emoji: '📚'),
  ],
  'pronouns': [
    VocabItem(word: 'I',         reading: '私 (Watashi)',              emoji: '👤', isNew: true),
    VocabItem(word: 'You',       reading: 'あなた (Anata)',            emoji: '🫵'),
    VocabItem(word: 'He',        reading: '彼 (Kare)',                 emoji: '👦'),
  ],
};

List<VocabItem> _vocabFor(String id) =>
    _kSampleVocab[id] ??
    [
      VocabItem(word: 'Word 1', reading: 'Sample reading', emoji: '📝', isNew: true),
      VocabItem(word: 'Word 2', reading: 'Sample reading', emoji: '📝'),
    ];

// ── Deck model (mirrors flashcards_screen._Deck) ──────────

class DeckArg {
  const DeckArg({
    required this.id,
    required this.name,
    required this.nameVi,
    required this.total,
    required this.learned,
    required this.emoji,
  });
  final String id;
  final String name;
  final String nameVi;
  final int total;
  final int learned;
  final String emoji;
}

// ── Screen ────────────────────────────────────────────────

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, required this.deck});
  final DeckArg deck;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  int _filterIndex = 0;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VocabItem> get _filtered {
    final all = _vocabFor(widget.deck.id);
    List<VocabItem> list;
    switch (_filterIndex) {
      case 1: // Recent
        list = all.take(3).toList();
      case 2: // Saved
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildFilterTabs(),
                  const SizedBox(height: 4),
                  Expanded(child: _buildVocabList()),
                ],
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
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: Color(0xFF424242)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Text(
            widget.deck.nameVi,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
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
              'Không tìm thấy từ nào',
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
      itemBuilder: (context, i) => _VocabCard(item: items[i]),
    );
  }
}

// ── Vocab card ────────────────────────────────────────────

class _VocabCard extends StatelessWidget {
  const _VocabCard({required this.item});
  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji icon box
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 26)),
                ),
              ),
              if (item.isNew)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Word + reading
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.reading,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Play button
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.play_arrow_rounded,
                  color: AppTheme.primaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
