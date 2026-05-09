import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/widgets/vocab_card.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Per-deck sample data ──────────────────────────────────

const _kSampleVocab = <String, List<VocabItem>>{
  'nouns': [
    VocabItem(word: 'Pen',       reading: 'コーヒーカップ (Kōhī kappu)',   emoji: '✏️', isNew: true),
    VocabItem(word: 'Cat',       reading: '観葉植物 (Kanyōshokubutsu)',   emoji: '🐱'),
    VocabItem(word: 'Laptop',    reading: 'ノートパソコン (Nōto pasokon)', emoji: '💻'),
    VocabItem(word: 'Headphones',reading: 'ヘッドホン (Heddohon)',        emoji: '🎧'),
    VocabItem(word: 'Book',      reading: '本 (Hon)',                     emoji: '📖'),
    VocabItem(word: 'Chair',     reading: '椅子 (Isu)',                   emoji: '🪑'),
    VocabItem(word: 'Table',     reading: 'テーブル (Tēburu)',            emoji: '🪵'),
  ],
  'nha-bep': [
    VocabItem(word: 'Knife',     reading: '包丁 (Hōchō)',               emoji: '🔪', isNew: true),
    VocabItem(word: 'Spoon',     reading: 'スプーン (Supūn)',            emoji: '🥄'),
    VocabItem(word: 'Pan',       reading: 'フライパン (Furaipan)',        emoji: '🍳'),
    VocabItem(word: 'Cup',       reading: 'コップ (Koppu)',              emoji: '☕'),
    VocabItem(word: 'Plate',     reading: '皿 (Sara)',                   emoji: '🍽️'),
    VocabItem(word: 'Pot',       reading: '鍋 (Nabe)',                   emoji: '🫕'),
    VocabItem(word: 'Oven',      reading: 'オーブン (Ōbun)',             emoji: '🔥'),
  ],
  'thien-nhien': [
    VocabItem(word: 'Tree',      reading: '木 (Ki)',                     emoji: '🌳', isNew: true),
    VocabItem(word: 'River',     reading: '川 (Kawa)',                   emoji: '🏞️'),
    VocabItem(word: 'Mountain',  reading: '山 (Yama)',                   emoji: '⛰️'),
    VocabItem(word: 'Flower',    reading: '花 (Hana)',                   emoji: '🌸'),
    VocabItem(word: 'Sun',       reading: '太陽 (Taiyō)',               emoji: '☀️'),
    VocabItem(word: 'Rain',      reading: '雨 (Ame)',                    emoji: '🌧️'),
  ],
  'thanh-pho': [
    VocabItem(word: 'Building',  reading: 'ビル (Biru)',                 emoji: '🏢', isNew: true),
    VocabItem(word: 'Bridge',    reading: '橋 (Hashi)',                  emoji: '🌉'),
    VocabItem(word: 'Station',   reading: '駅 (Eki)',                    emoji: '🚉'),
    VocabItem(word: 'Park',      reading: '公園 (Kōen)',                emoji: '🏞️'),
    VocabItem(word: 'Traffic',   reading: '交通 (Kōtsū)',               emoji: '🚦'),
  ],
  'quan-ca-phe': [
    VocabItem(word: 'Coffee',    reading: 'コーヒー (Kōhī)',             emoji: '☕', isNew: true),
    VocabItem(word: 'Tea',       reading: 'お茶 (Ocha)',                 emoji: '🍵'),
    VocabItem(word: 'Cake',      reading: 'ケーキ (Kēki)',              emoji: '🍰'),
    VocabItem(word: 'Menu',      reading: 'メニュー (Menyū)',            emoji: '📋'),
  ],
  'van-phong': [
    VocabItem(word: 'Pen',       reading: 'ペン (Pen)',                  emoji: '✏️', isNew: true),
    VocabItem(word: 'Laptop',    reading: 'ノートパソコン (Nōto pasokon)', emoji: '💻'),
    VocabItem(word: 'Desk',      reading: '机 (Tsukue)',                 emoji: '🪵'),
    VocabItem(word: 'Printer',   reading: 'プリンター (Purintā)',        emoji: '🖨️'),
    VocabItem(word: 'Chair',     reading: '椅子 (Isu)',                  emoji: '🪑'),
  ],
  'phong-ngu': [
    VocabItem(word: 'Bed',       reading: 'ベッド (Beddo)',              emoji: '🛏️', isNew: true),
    VocabItem(word: 'Pillow',    reading: '枕 (Makura)',                 emoji: '🛌'),
    VocabItem(word: 'Lamp',      reading: 'ランプ (Ranpu)',              emoji: '💡'),
    VocabItem(word: 'Curtain',   reading: 'カーテン (Kāten)',            emoji: '🪟'),
  ],
  'san-vuon': [
    VocabItem(word: 'Garden',    reading: '庭 (Niwa)',                   emoji: '🌿', isNew: true),
    VocabItem(word: 'Flower',    reading: '花 (Hana)',                   emoji: '🌸'),
    VocabItem(word: 'Grass',     reading: '草 (Kusa)',                   emoji: '🌱'),
    VocabItem(word: 'Fence',     reading: '柵 (Saku)',                   emoji: '🏡'),
    VocabItem(word: 'Hose',      reading: 'ホース (Hōsu)',              emoji: '🪴'),
  ],
  'duong-pho': [
    VocabItem(word: 'Car',       reading: '車 (Kuruma)',                 emoji: '🚗', isNew: true),
    VocabItem(word: 'Bus',       reading: 'バス (Basu)',                 emoji: '🚌'),
    VocabItem(word: 'Bicycle',   reading: '自転車 (Jitensha)',           emoji: '🚲'),
    VocabItem(word: 'Sidewalk',  reading: '歩道 (Hodō)',                emoji: '🚶'),
  ],
  'truong-hoc': [
    VocabItem(word: 'Teacher',   reading: '先生 (Sensei)',               emoji: '👩‍🏫', isNew: true),
    VocabItem(word: 'Student',   reading: '学生 (Gakusei)',              emoji: '🎓'),
    VocabItem(word: 'Book',      reading: '本 (Hon)',                    emoji: '📖'),
    VocabItem(word: 'Classroom', reading: '教室 (Kyōshitsu)',           emoji: '🏫'),
    VocabItem(word: 'Pencil',    reading: '鉛筆 (Enpitsu)',             emoji: '✏️'),
  ],
  'du-lich': [
    VocabItem(word: 'Airport',   reading: '空港 (Kūkō)',                emoji: '✈️', isNew: true),
    VocabItem(word: 'Hotel',     reading: 'ホテル (Hoteru)',             emoji: '🏨'),
    VocabItem(word: 'Map',       reading: '地図 (Chizu)',                emoji: '🗺️'),
    VocabItem(word: 'Camera',    reading: 'カメラ (Kamera)',             emoji: '📷'),
    VocabItem(word: 'Passport',  reading: 'パスポート (Pasupōto)',       emoji: '🛂'),
  ],
  'adjectives': [
    VocabItem(word: 'Beautiful', reading: '美しい (Utsukushii)',        emoji: '✨', isNew: true),
    VocabItem(word: 'Fast',      reading: '速い (Hayai)',               emoji: '⚡'),
    VocabItem(word: 'Tall',      reading: '高い (Takai)',               emoji: '📏'),
  ],
  'verbs': [
    VocabItem(word: 'Run',       reading: '走る (Hashiru)',             emoji: '🏃', isNew: true),
    VocabItem(word: 'Eat',       reading: '食べる (Taberu)',            emoji: '🍽️'),
    VocabItem(word: 'Sleep',     reading: '寝る (Neru)',                emoji: '😴'),
    VocabItem(word: 'Read',      reading: '読む (Yomu)',                emoji: '📚'),
  ],
  'pronouns': [
    VocabItem(word: 'I',         reading: '私 (Watashi)',               emoji: '👤', isNew: true),
    VocabItem(word: 'You',       reading: 'あなた (Anata)',             emoji: '🫵'),
    VocabItem(word: 'He',        reading: '彼 (Kare)',                  emoji: '👦'),
  ],
};

List<VocabItem> _vocabFor(String id) =>
    _kSampleVocab[id] ??
    [
      VocabItem(word: 'Word 1', reading: 'Sample reading', emoji: '📝', isNew: true),
      VocabItem(word: 'Word 2', reading: 'Sample reading', emoji: '📝'),
    ];

// ── Design tokens ─────────────────────────────────────────
const _kBg     = Color(0xFFFFF8F4);
const _kDark   = Color(0xFF1A1A1A);

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
    });
  }

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
      backgroundColor: _kBg,
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
      itemBuilder: (context, i) => VocabCard(item: items[i]),
    );
  }
}
