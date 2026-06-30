import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(leaderboardNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(leaderboardNotifierProvider.notifier).refresh(),
          color: const Color(0xFFFF6A00),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      // Back Button
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Colors.black.withValues(alpha: 0.10),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.pop(),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(Icons.arrow_back_rounded,
                                color: Color(0xFF1D1814), size: 21),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Title
                      Column(
                        children: [
                          const Text(
                            'Bảng xếp hạng tuần',
                            style: TextStyle(
                              color: Color(0xFF1D1814),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Thi đua cùng cộng đồng Milingo',
                            style: TextStyle(
                              color: const Color(0xFF1D1814)
                                  .withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Placeholder to balance the back button
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),

              // Main Content
              stateAsync.when(
                data: (state) {
                  final users = state.users;
                  final currentUser = state.currentUser;

                  // Podium Top 3
                  final gold = users.isNotEmpty ? users[0] : null;
                  final silver = users.length > 1 ? users[1] : null;
                  final bronze = users.length > 2 ? users[2] : null;

                  // Remaining users starting from rank 4
                  final listUsers =
                      users.length > 3 ? users.sublist(3) : <LeaderboardUser>[];

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList.list(
                      children: [
                        // User progress card
                        if (currentUser != null) ...[
                          _UserRankProgressCard(user: currentUser),
                          const SizedBox(height: 24),
                        ],

                        // Podium section
                        if (users.isNotEmpty) ...[
                          _LeaderboardScreenPodium(
                            gold: gold,
                            silver: silver,
                            bronze: bronze,
                          ),
                          const SizedBox(height: 28),
                        ],

                        // Full list title
                        if (listUsers.isNotEmpty || state.hasMore) ...[
                          const Text(
                            'Xếp hạng đầy đủ',
                            style: TextStyle(
                              color: Color(0xFF1D1814),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // List of users rank 4+
                        ...listUsers.map((user) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RankRow(
                                user: user,
                                isMe: currentUser != null &&
                                    user.id == currentUser.id,
                              ),
                            )),

                        // Loading / Load More button
                        if (state.hasMore) ...[
                          const SizedBox(height: 8),
                          if (state.isLoadingMore)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                            )
                          else
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => ref
                                      .read(
                                          leaderboardNotifierProvider.notifier)
                                      .loadMore(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFF6A00),
                                    side: const BorderSide(
                                        color: Color(0xFFFF6A00)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Xem thêm',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Không thể tải bảng xếp hạng.',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref
                                .read(leaderboardNotifierProvider.notifier)
                                .refresh(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6A00),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNumber(num value) {
    return NumberFormat.decimalPattern('vi_VN').format(value);
  }
}

class _UserRankProgressCard extends StatelessWidget {
  const _UserRankProgressCard({required this.user});

  final LeaderboardUser user;

  @override
  Widget build(BuildContext context) {
    // Logic to determine level or promotion threshold
    // Let's compute progress dynamically
    final points = user.totalPoints;

    // Find next rank milestone: e.g. next multiple of 1000 XP
    final nextMilestone = ((points / 1000).floor() + 1) * 1000;
    final xpNeeded = nextMilestone - points;
    final progress = (points % 1000) / 1000.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF9A3D), Color(0xFFFF6A00)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A00).withValues(alpha: 0.32),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy icon background
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: const Text(
              '🏆',
              style: TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(width: 16),
          // Stats and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Giải Vàng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hạng của bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${user.rank} · ${NumberFormat.decimalPattern('vi_VN').format(points)} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${NumberFormat.decimalPattern('vi_VN').format(xpNeeded)} XP để lên hạng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Top 10',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.20),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
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

class _LeaderboardScreenPodium extends StatelessWidget {
  const _LeaderboardScreenPodium({
    required this.gold,
    required this.silver,
    required this.bronze,
  });

  final LeaderboardUser? gold;
  final LeaderboardUser? silver;
  final LeaderboardUser? bronze;

  @override
  Widget build(BuildContext context) {
    final localGold = gold;
    final localSilver = silver;
    final localBronze = bronze;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd
          if (localSilver != null)
            Expanded(
              child: _ScreenPodiumSpot(
                user: localSilver,
                rank: 2,
                podiumHeight: 70,
                colors: const [Color(0xFFFFD8B8), Color(0xFFFFB98A)],
              ),
            )
          else
            const Expanded(child: SizedBox()),

          // 1st
          if (localGold != null)
            Expanded(
              child: _ScreenPodiumSpot(
                user: localGold,
                rank: 1,
                podiumHeight: 92,
                colors: const [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
              ),
            )
          else
            const Expanded(child: SizedBox()),

          // 3rd
          if (localBronze != null)
            Expanded(
              child: _ScreenPodiumSpot(
                user: localBronze,
                rank: 3,
                podiumHeight: 56,
                colors: const [Color(0xFFFFD8B8), Color(0xFFFFB98A)],
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _ScreenPodiumSpot extends StatelessWidget {
  const _ScreenPodiumSpot({
    required this.user,
    required this.rank,
    required this.podiumHeight,
    required this.colors,
  });

  final LeaderboardUser user;
  final int rank;
  final double podiumHeight;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final avatarName = user.displayName;
    final pointsText =
        NumberFormat.decimalPattern('vi_VN').format(user.totalPoints);

    final isTop1 = rank == 1;
    final double width = isTop1 ? 90.0 : 70.0;
    final double height = isTop1 ? 120.0 : 75.6;
    final double avatarSize = isTop1 ? 80.0 : 62.0;
    final double avatarLeft = isTop1 ? 5.0 : 4.0;
    final double avatarTop = isTop1 ? 27.0 : 4.0;

    final svgPath = 'assets/svg/ranking/top$rank.svg';

    Widget avatarWidget;
    final photoUrl = user.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.runes.length <= 2 && photoUrl.runes.first > 127) {
        // Emoji avatar
        avatarWidget = Center(
          child: Text(
            photoUrl,
            style: TextStyle(fontSize: isTop1 ? 36 : 28),
          ),
        );
      } else {
        // Network avatar image
        avatarWidget = Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _ScreenAvatarFallback(name: avatarName, isTop1: isTop1),
        );
      }
    } else {
      avatarWidget = _ScreenAvatarFallback(name: avatarName, isTop1: isTop1);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              // Avatar
              Positioned(
                left: avatarLeft,
                top: avatarTop,
                width: avatarSize,
                height: avatarSize,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF6F7FB),
                  ),
                  child: ClipOval(
                    child: avatarWidget,
                  ),
                ),
              ),
              // SVG Ring
              Positioned.fill(
                child: SvgPicture.asset(
                  svgPath,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          avatarName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1F2430),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$pointsText XP',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFF6A00),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        // Podium block
        Container(
          width: 80,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScreenAvatarFallback extends StatelessWidget {
  const _ScreenAvatarFallback({
    required this.name,
    required this.isTop1,
  });

  final String name;
  final bool isTop1;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'M' : name.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFFFFE2CC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFFFF6A00),
          fontSize: isTop1 ? 24 : 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.user,
    required this.isMe,
  });

  final LeaderboardUser user;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final avatarName = isMe ? 'Bạn' : user.displayName;
    final pointsText =
        NumberFormat.decimalPattern('vi_VN').format(user.totalPoints);

    // Static/Deterministic trend for aesthetic completeness (matching Figma design)
    String trendText = '●';
    Color trendColor = const Color(0x591D1814);
    if (user.rank % 3 == 0) {
      trendText = '▲ 1';
      trendColor = const Color(0xFF22C55E);
    } else if (user.rank % 4 == 0) {
      trendText = '▼ 2';
      trendColor = const Color(0xFFEF4444);
    }

    Widget avatarWidget;
    final photoUrl = user.photoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.runes.length <= 2 && photoUrl.runes.first > 127) {
        // Emoji avatar
        avatarWidget = Center(
          child: Text(
            photoUrl,
            style: const TextStyle(fontSize: 20),
          ),
        );
      } else {
        // Network avatar image
        avatarWidget = Image.network(
          photoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _RowAvatarFallback(name: avatarName),
        );
      }
    } else {
      avatarWidget = _RowAvatarFallback(name: avatarName);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFFFFECE0)
            : Colors.white.withValues(alpha: 0.85),
        border:
            Border.all(color: isMe ? const Color(0xFFFF8A1F) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isMe)
            BoxShadow(
              color: const Color(0xFFFF6A00).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          else
            BoxShadow(
              color: const Color(0xFF1D1814).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '${user.rank}',
              style: TextStyle(
                color: isMe ? const Color(0xFFFF4D1A) : const Color(0x801D1814),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? const Color(0xFFFFD8C2) : const Color(0xFFF3F1EE),
            ),
            child: ClipOval(
              child: avatarWidget,
            ),
          ),
          const SizedBox(width: 14),
          // Display Name
          Expanded(
            child: Text(
              avatarName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1D1814),
                fontSize: 14,
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          // Trend Arrow
          Text(
            trendText,
            style: TextStyle(
              color: trendColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          // XP points
          Text(
            pointsText,
            style: TextStyle(
              color: isMe ? const Color(0xFFFF4D1A) : const Color(0xFF1D1814),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowAvatarFallback extends StatelessWidget {
  const _RowAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'M' : name.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFFFFE2CC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFFFF6A00),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
