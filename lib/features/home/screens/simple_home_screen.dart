import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class SimpleHomeScreen extends ConsumerWidget {
  const SimpleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsValueProvider);
    final user = FirebaseAuth.instance.currentUser;
    final name = _displayNameFor(user);
    final scanCount = NumberFormat.decimalPattern('en_US')
        .format(stats.totalPoints == 0 ? 450 : stats.totalPoints);

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                name: name,
                streak: stats.currentStreak == 0 ? 12 : stats.currentStreak,
              ),
              const SizedBox(height: 18),
              _AiPracticeCard(
                onTap: () => context.go(AppConstants.snapAndLearnRoute),
              ),
              const SizedBox(height: 12),
              _StatsMascotBlock(scanCount: scanCount),
              const SizedBox(height: 12),
              _VocabularyHeader(
                onSeeAll: () => context.go(AppConstants.flashcardsRoute),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  static String _displayNameFor(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.split('@').first.trim();
    if (email != null && email.isNotEmpty) return email;
    return '2DEV';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, $name!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _HomeColors.subtleBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tiếp tục hành trình',
                  style: TextStyle(
                    color: _HomeColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        _StreakCard(streak: streak),
      ],
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFDCC8), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: _HomeColors.primary,
                size: 18,
              ),
              const SizedBox(width: 3),
              Text(
                streak.toString(),
                style: const TextStyle(
                  color: _HomeColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'NGÀY LIÊN TIẾP',
            style: TextStyle(
              color: _HomeColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiPracticeCard extends StatelessWidget {
  const _AiPracticeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 84,
        padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1E9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFD7C8), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0DF15F36),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const _MilingoMark(),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trò chuyện cùng AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _HomeColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sẵn sàng luyện tập!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _HomeColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _HomeColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _HomeColors.primary.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
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
    );
  }
}

class _MilingoMark extends StatelessWidget {
  const _MilingoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFA32A), _HomeColors.primary],
          ).createShader(bounds),
          child: const Text(
            'M',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsMascotBlock extends StatelessWidget {
  const _StatsMascotBlock({required this.scanCount});

  final String scanCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _ScanStatCard(scanCount: scanCount),
          ),
          Positioned(
            right: 18,
            top: 0,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 32,
            top: 8,
            child: Image.asset(
              'assets/images/limabo.png',
              width: 138,
              height: 138,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStatCard extends StatelessWidget {
  const _ScanStatCard({required this.scanCount});

  final String scanCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 122,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4E1D9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/svg/camera-homescreen.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            scanCount,
            style: const TextStyle(
              color: _HomeColors.text,
              fontSize: 29,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Từ đã quét',
            style: TextStyle(
              color: _HomeColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyHeader extends StatelessWidget {
  const _VocabularyHeader({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Khám phá từ vựng',
                style: TextStyle(
                  color: _HomeColors.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 9),
              Text(
                'Học qua hình ảnh thực tế',
                style: TextStyle(
                  color: _HomeColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Padding(
            padding: EdgeInsets.only(bottom: 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: _HomeColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: _HomeColors.primary,
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeColors {
  static const background = Color(0xFFFFF8F4);
  static const primary = AppTheme.primaryColor;
  static const text = Color(0xFF20243A);
  static const mutedText = Color(0xFF8D8791);
  static const subtleBlue = Color(0xFF63708F);
}
