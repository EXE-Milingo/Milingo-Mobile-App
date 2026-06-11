import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class SimpleHomeScreen extends ConsumerStatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  ConsumerState<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends ConsumerState<SimpleHomeScreen> {
  bool _requestedCards = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCardsOnce());
  }

  Future<void> _loadCardsOnce() async {
    if (!mounted || _requestedCards) return;

    final flashcards = ref.read(flashcardProvider).valueOrNull;
    final hasServerCards =
        flashcards?.decks.any((deck) => deck.total > 0) ?? false;
    if (!hasServerCards) return;

    _requestedCards = true;
    await ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<FlashcardState>>(flashcardProvider, (_, __) {
      _loadCardsOnce();
    });

    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(userStatsValueProvider);
    final flashcards = ref.watch(flashcardStateProvider);
    final name = _displayNameFor(
      profile?.displayName,
      user?.displayName,
      user?.email,
    );
    final totalWords =
        flashcards.decks.fold<int>(0, (sum, deck) => sum + deck.total);
    final recentWords = _recentVocabulary(flashcards);

    return Scaffold(
      backgroundColor: _HomeColors.background,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                name: name,
                streak: stats.currentStreak,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              sliver: SliverList.list(
                children: [
                  _HeroCameraCard(
                    onTap: () => context.push(AppConstants.snapAndLearnRoute),
                  ),
                  const SizedBox(height: 24),
                  _StatsRow(
                    scannedWords: totalWords,
                    coins: stats.coins,
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Tiếp tục học',
                    actionLabel: 'Xem tất cả',
                    onAction: () => context.push(AppConstants.examRoute),
                  ),
                  const SizedBox(height: 12),
                  _ContinueLearningCard(
                    totalWords: totalWords,
                    onTap: () => context.push(AppConstants.examRoute),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Từ vựng gần đây',
                    actionLabel: 'Xem tất cả',
                    onAction: () => context.go(AppConstants.flashcardsRoute),
                  ),
                  const SizedBox(height: 12),
                  _RecentVocabularySection(
                    items: recentWords,
                    onOpen: (item) => context.push(
                      AppConstants.vocabDetailRoute,
                      extra: VocabDetailArg(
                        deckId: item.deckId,
                        deckName: item.deckName,
                        entry: item.entry,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _displayNameFor(
    String? profileName,
    String? firebaseName,
    String? email,
  ) {
    final candidates = [
      profileName,
      firebaseName,
      email?.split('@').first,
    ];
    for (final candidate in candidates) {
      final trimmed = candidate?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return 'Milingo';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.streak,
  });

  final String name;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _HomeColors.header,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                Text(
                  '$name 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StreakPill(streak: streak),
          const SizedBox(width: 12),
          _AvatarInitial(name: name),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDBC8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: _HomeColors.orange.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: _HomeColors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            streak.toString(),
            style: const TextStyle(
              color: Color(0xFF321200),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'M' : name.trim()[0].toUpperCase();

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFDEE1F8),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF606376),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}

class _HeroCameraCard extends StatelessWidget {
  const _HeroCameraCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          height: 226,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF7A00),
                Color(0xFF994700),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF994700).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -48,
                top: -48,
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: -10,
                bottom: -12,
                child: Image.asset(
                  'assets/images/limabo_home.png',
                  width: 148,
                  height: 148,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ReadyDot(),
                        SizedBox(width: 8),
                        Text(
                          'SẴN SÀNG',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Học cùng Limabo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(
                    width: 212,
                    child: Text(
                      'Phân tích hình ảnh và học từ vựng ngay lập tức.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFFFDBC8),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF994700).withValues(alpha: 0.20),
                          blurRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.camera_alt_rounded,
                          color: _HomeColors.darkOrange,
                          size: 17,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Bắt đầu chụp',
                          style: TextStyle(
                            color: _HomeColors.darkOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
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
}

class _ReadyDot extends StatelessWidget {
  const _ReadyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFA8E05F),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.scannedWords,
    required this.coins,
  });

  final int scannedWords;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.photo_camera_rounded,
            iconColor: const Color(0xFF5A5D70),
            iconBackground: const Color(0xFFEEF0FF),
            title: 'Từ đã quét',
            value: '${_formatNumber(scannedWords)} từ',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            iconColor: _HomeColors.orange,
            iconBackground: const Color(0xFFFFDBC8),
            title: _formatNumber(coins),
            value: 'Xu',
            titleLarge: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    this.titleLarge = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final bool titleLarge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HomeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomeColors.text,
                    fontSize: titleLarge ? 18 : 14,
                    fontWeight: titleLarge ? FontWeight.w500 : FontWeight.w800,
                    height: titleLarge ? 1.15 : 1.4,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomeColors.brown,
                    fontSize: titleLarge ? 12 : 13,
                    fontWeight: FontWeight.w400,
                    height: titleLarge ? 1.15 : 1.5,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF5A5D70),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.totalWords,
    required this.onTap,
  });

  final int totalWords;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = totalWords == 0 ? 0.0 : (totalWords.clamp(0, 12) / 12);
    final label = totalWords == 0
        ? 'Chưa có từ nào'
        : '${_formatNumber(totalWords.clamp(0, 12))} / 12 từ';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _HomeColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEE1F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Color(0xFF5A5D70),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ôn tập hôm nay',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _HomeColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: _HomeColors.border,
                        color: const Color(0xFF5A5D70),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.brown,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A5D70),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A5D70).withValues(alpha: 0.30),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentVocabularySection extends StatelessWidget {
  const _RecentVocabularySection({
    required this.items,
    required this.onOpen,
  });

  final List<_RecentVocabularyItem> items;
  final ValueChanged<_RecentVocabularyItem> onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyVocabularyCard();

    return SizedBox(
      height: 134,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          return _RecentVocabularyCard(
            item: item,
            accent: _recentAccent(index),
            onTap: () => onOpen(item),
          );
        },
      ),
    );
  }
}

class _RecentVocabularyCard extends StatelessWidget {
  const _RecentVocabularyCard({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  final _RecentVocabularyItem item;
  final _RecentAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.entry.english.trim().isEmpty
        ? item.entry.translation
        : item.entry.english;
    final subtitle = item.entry.translation.trim().isEmpty
        ? item.deckName
        : item.entry.translation;

    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _HomeColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: accent.foreground,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyVocabularyCard extends StatelessWidget {
  const _EmptyVocabularyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _HomeColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/nothing.png',
            width: 96,
            height: 96,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa có từ gần đây',
                  style: TextStyle(
                    color: _HomeColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Chụp một vật cùng Limabo để lưu từ mới ở đây.',
                  style: TextStyle(
                    color: _HomeColors.brown,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
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

class _RecentVocabularyItem {
  const _RecentVocabularyItem({
    required this.deckId,
    required this.deckName,
    required this.entry,
    required this.index,
  });

  final String deckId;
  final String deckName;
  final FlashcardEntry entry;
  final int index;
}

class _RecentAccent {
  const _RecentAccent(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

List<_RecentVocabularyItem> _recentVocabulary(FlashcardState state) {
  final items = <_RecentVocabularyItem>[];
  var index = 0;

  for (final deck in state.decks) {
    for (final entry in deck.cards) {
      items.add(
        _RecentVocabularyItem(
          deckId: deck.id,
          deckName: deck.name,
          entry: entry,
          index: index++,
        ),
      );
    }
  }

  items.sort((a, b) {
    final byDate = _createdAtOf(b.entry).compareTo(_createdAtOf(a.entry));
    if (byDate != 0) return byDate;
    return b.index.compareTo(a.index);
  });

  return items.take(8).toList(growable: false);
}

DateTime _createdAtOf(FlashcardEntry entry) {
  return DateTime.tryParse(entry.createdAt) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

_RecentAccent _recentAccent(int index) {
  const accents = [
    _RecentAccent(Color(0xFFE3F2FD), Color(0xFF1E88E5)),
    _RecentAccent(Color(0xFFE8F5E9), Color(0xFF43A047)),
    _RecentAccent(Color(0xFFFFDBC8), Color(0xFFE36F2C)),
  ];
  return accents[index % accents.length];
}

String _formatNumber(num value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}

class _HomeColors {
  static const background = Color(0xFFF5F3F3);
  static const header = Color(0xFFFBF9F9);
  static const border = Color(0xFFE4E2E2);
  static const text = Color(0xFF1B1C1C);
  static const brown = Color(0xFF584235);
  static const orange = Color(0xFFFF7A00);
  static const darkOrange = Color(0xFF994700);
}
