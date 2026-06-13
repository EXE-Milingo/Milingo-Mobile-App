import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
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
    final dueWords = _dueVocabulary(recentWords);
    final featuredWord = recentWords.isEmpty ? null : recentWords.first;

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
                onNotificationTap: () =>
                    context.push(AppConstants.profileRoute),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(17, 14, 17, 112),
              sliver: SliverList.list(
                children: [
                  _JourneyCard(
                    streak: stats.currentStreak,
                    coins: stats.coins,
                    onTap: () => context.push(AppConstants.examRoute),
                  ),
                  const SizedBox(height: 17),
                  _QuickActionsGrid(
                    onReview: () => context.push(AppConstants.examRoute),
                    onScan: () => context.push(AppConstants.snapAndLearnRoute),
                    onFlashcards: () =>
                        context.go(AppConstants.flashcardsRoute),
                  ),
                  const SizedBox(height: 27),
                  _SectionHeader(
                    title: 'Nhiệm vụ hôm nay',
                    trailing: dueWords.isEmpty ? null : '${dueWords.length}',
                  ),
                  const SizedBox(height: 12),
                  _DailyMissionCard(
                    dueCount: dueWords.length,
                    totalWords: totalWords,
                    onTap: () => context.push(AppConstants.examRoute),
                  ),
                  const SizedBox(height: 30),
                  _ReviewFocusCard(
                    dueCount: dueWords.length,
                    word: featuredWord,
                    onTap: () => context.push(AppConstants.examRoute),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Top học viên tuần',
                    actionLabel: 'Xem tất cả',
                    onAction: () => context.go(AppConstants.leaderboardRoute),
                  ),
                  const SizedBox(height: 12),
                  const _LeaderboardEmptyCard(),
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
    required this.onNotificationTap,
  });

  final String name;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          const Text(
            '👋',
            style: TextStyle(fontSize: 24, height: 1.3),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()},',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                Text(
                  '$name!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationTap,
          ),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: _HomeColors.ink, size: 21),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.streak,
    required this.coins,
    required this.onTap,
  });

  final int streak;
  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A1F), Color(0xFFE93322)],
        ),
        boxShadow: [
          BoxShadow(
            color: _HomeColors.orange.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            const Positioned(
              left: -23,
              bottom: -48,
              child: _SoftCircle(size: 112),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tiếp tục hành trình',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Bạn đang học rất tốt! Cố lên nhé 🚀',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetricTile(
                          assetPath: 'assets/svg/new-streak.svg',
                          value: _formatNumber(streak),
                          label: 'Ngày streak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroMetricTile(
                          assetPath: 'assets/svg/new-coin.svg',
                          value: _formatNumber(coins),
                          label: 'Xu hiện có',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: _PrimaryHomeButton(
                      label: 'Học ngay',
                      onTap: onTap,
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
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.10),
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.assetPath,
    required this.value,
    required this.label,
  });

  final String assetPath;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SvgIcon(assetPath, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
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

class _PrimaryHomeButton extends StatelessWidget {
  const _PrimaryHomeButton({
    required this.label,
    required this.onTap,
    this.foreground = _HomeColors.orange,
    this.padding = const EdgeInsets.symmetric(vertical: 14),
  });

  final String label;
  final VoidCallback onTap;
  final Color foreground;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: foreground, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onReview,
    required this.onScan,
    required this.onFlashcards,
  });

  final VoidCallback onReview;
  final VoidCallback onScan;
  final VoidCallback onFlashcards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionTile(
              width: itemWidth,
              label: 'Ôn tập',
              assetPath: 'assets/svg/new-review.svg',
              colors: const [Color(0xFFFFF1E6), Color(0xFFFFE2CC)],
              onTap: onReview,
            ),
            _QuickActionTile(
              width: itemWidth,
              label: 'AI Tutor',
              assetPath: 'assets/svg/new-ai-tutor.svg',
              colors: const [Color(0xFFF0EAFF), Color(0xFFE2D6FF)],
            ),
            _QuickActionTile(
              width: itemWidth,
              label: 'Luyện phát âm',
              icon: Icons.mic_none_rounded,
              colors: const [Color(0xFFE9F7EC), Color(0xFFD4F0DC)],
            ),
            _QuickActionTile(
              width: itemWidth,
              label: 'Quét từ mới',
              icon: Icons.camera_alt_outlined,
              colors: const [Color(0xFFE8F1FF), Color(0xFFD5E6FF)],
              onTap: onScan,
              onLongPress: onFlashcards,
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.label,
    required this.colors,
    this.assetPath,
    this.icon,
    this.onTap,
    this.onLongPress,
  });

  final double width;
  final String label;
  final List<Color> colors;
  final String? assetPath;
  final IconData? icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return SizedBox(
      width: width,
      height: 78,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D1814).withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                  spreadRadius: -12,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: assetPath != null
                      ? _SvgIcon(assetPath!, size: 21)
                      : Icon(
                          icon,
                          color: enabled
                              ? _HomeColors.orange
                              : _HomeColors.mutedText,
                          size: 21,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xFF1D1814)
                          : _HomeColors.mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _HomeColors.title,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: _HomeColors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          )
        else if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: _HomeColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _DailyMissionCard extends StatelessWidget {
  const _DailyMissionCard({
    required this.dueCount,
    required this.totalWords,
    required this.onTap,
  });

  final int dueCount;
  final int totalWords;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasMission = dueCount > 0;
    final progress = totalWords == 0
        ? 0.0
        : ((totalWords - dueCount).clamp(0, totalWords) / totalWords);
    final progressLabel =
        totalWords == 0 ? '' : '${_formatNumber((progress * 100).round())}%';

    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: hasMission ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1814).withValues(alpha: 0.12),
                blurRadius: 34,
                offset: const Offset(0, 16),
                spreadRadius: -14,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _HomeColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('🎯', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasMission
                              ? 'Thử thách hôm nay'
                              : 'Không có nhiệm vụ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _HomeColors.title,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.5,
                          ),
                        ),
                        Text(
                          hasMission
                              ? '${_formatNumber(dueCount)} từ cần ôn'
                              : 'Dữ liệu nhiệm vụ đang trống',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _HomeColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasMission)
                    const _RewardBadges()
                  else
                    const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      totalWords == 0
                          ? ''
                          : '${_formatNumber(totalWords - dueCount)} / ${_formatNumber(totalWords)} từ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      color: _HomeColors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F1F1),
                  color: _HomeColors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardBadges extends StatelessWidget {
  const _RewardBadges();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _RewardBadge(label: '+ XP'),
        SizedBox(height: 5),
        _RewardBadge(label: '+ Xu', soft: true),
      ],
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({
    required this.label,
    this.soft = false,
  });

  final String label;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: soft
            ? const Color(0xFFFFF4D6)
            : _HomeColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: soft ? const Color(0xFFC47A00) : _HomeColors.orange,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

class _ReviewFocusCard extends StatelessWidget {
  const _ReviewFocusCard({
    required this.dueCount,
    required this.word,
    required this.onTap,
  });

  final int dueCount;
  final _RecentVocabularyItem? word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            const Positioned(
              right: -32,
              bottom: -48,
              child: _SoftCircle(size: 112),
            ),
            Positioned(
              right: -4,
              bottom: 0,
              top: 20,
              child: _FlashcardPreview(word: word),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 134, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SvgIcon(
                          'assets/svg/new-review.svg',
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ôn tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dueCount > 0
                        ? '${_formatNumber(dueCount)} từ cần ôn'
                        : 'Chưa có từ cần ôn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    dueCount > 0
                        ? 'Củng cố trí nhớ của bạn hôm nay'
                        : 'Dữ liệu ôn tập đang trống',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  _PrimaryHomeButton(
                    label: 'Bắt đầu ôn ngay',
                    foreground: const Color(0xFF6D28D9),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardPreview extends StatelessWidget {
  const _FlashcardPreview({required this.word});

  final _RecentVocabularyItem? word;

  @override
  Widget build(BuildContext context) {
    final title = word?.entry.english.trim() ?? '';
    final translation = word?.entry.translation.trim() ?? '';
    final pronunciation = word?.entry.pronunciation.trim() ?? '';

    return SizedBox(
      width: 150,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -18,
            top: 10,
            child: Transform.rotate(
              angle: 0.26,
              child: _StackedCard(color: Colors.white.withValues(alpha: 0.40)),
            ),
          ),
          Positioned(
            right: -4,
            top: 22,
            child: Transform.rotate(
              angle: 0.14,
              child: _StackedCard(color: Colors.white.withValues(alpha: 0.60)),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 132,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3E8FF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title.isEmpty ? '' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1D1814),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          pronunciation.isEmpty ? '' : '/$pronunciation/',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (pronunciation.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.volume_up_rounded,
                          color: Color(0xFF7C3AED),
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedCard extends StatelessWidget {
  const _StackedCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.50)),
      ),
    );
  }
}

class _LeaderboardEmptyCard extends StatelessWidget {
  const _LeaderboardEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFFFFB300),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa có dữ liệu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomeColors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Dữ liệu đang được cập nhật.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _HomeColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
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

class _SvgIcon extends StatelessWidget {
  const _SvgIcon(
    this.assetPath, {
    this.size = 20,
    this.color,
  });

  final String assetPath;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
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

List<_RecentVocabularyItem> _dueVocabulary(List<_RecentVocabularyItem> items) {
  return items.where((item) => _isDueForReview(item.entry)).toList();
}

bool _isDueForReview(FlashcardEntry entry) {
  final nextReviewAt = DateTime.tryParse(entry.srsNextReviewAt ?? '');
  if (nextReviewAt == null) {
    return entry.isNewForStudy || entry.isLearning || entry.isReviewing;
  }

  return !nextReviewAt.isAfter(DateTime.now());
}

DateTime _createdAtOf(FlashcardEntry entry) {
  return DateTime.tryParse(entry.createdAt) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatNumber(num value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}

class _HomeColors {
  static const background = Color(0xFFFFF8F4);
  static const ink = Color(0xFF0A0A0A);
  static const title = Color(0xFF1F2430);
  static const secondaryText = Color(0xFF64748B);
  static const mutedText = Color(0xFF9AA0AB);
  static const orange = Color(0xFFFF6A00);
}
