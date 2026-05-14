import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class SimpleHomeScreen extends ConsumerStatefulWidget {
  const SimpleHomeScreen({super.key});
  @override
  ConsumerState<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}
class _SimpleHomeScreenState extends ConsumerState<SimpleHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildWeeklyStreak()),
            SliverToBoxAdapter(child: _buildDailyBanner()),
            SliverToBoxAdapter(child: _buildSectionTitle('Tính năng chính')),
            SliverToBoxAdapter(
              child: _FeatureCard(
                emoji: '📸',
                emojiBackground: const Color(0xFFFFEDE8),
                title: 'Snap & Learn',
                subtitle: 'Chụp ảnh và học từ vựng với AI',
                buttonLabel: 'Bắt đầu',
                buttonColor: AppTheme.primaryColor,
                onTap: () => context.push(AppConstants.snapAndLearnRoute),
                onButtonTap: () =>
                    context.push(AppConstants.snapAndLearnRoute),
                isHighlighted: true,
              ),
            ),
            SliverToBoxAdapter(
              child:             _FeatureCard(
                emoji: '🃏',
                emojiBackground: const Color(0xFFFFEDE8),
                title: 'Flashcards',
                subtitle: 'Ôn tập từ vựng theo cách hiệu quả nhất',
                buttonLabel: 'Ôn tập',
                buttonColor: AppTheme.secondaryColor,
                onTap: () => context.go(AppConstants.flashcardsRoute),
                onButtonTap: () => context.go(AppConstants.flashcardsRoute),
              ),
            ),
            SliverToBoxAdapter(
              child: _FeatureCard(
                emoji: '🏆',
                emojiBackground: const Color(0xFFFFF3E0),
                title: 'Gamification',
                subtitle: 'Streaks, điểm số và bảng xếp hạng',
                buttonLabel: 'Khám phá',
                buttonColor: AppTheme.accentColor,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gamification – Coming soon!')),
                ),
                onButtonTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gamification – Coming soon!')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
      // Lấy stats thật từ provider
      final stats = ref.watch(userStatsValueProvider);

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            SvgPicture.asset('assets/svg/milingo-logo.svg', width: 32, height: 32),
            const SizedBox(width: 8),
            Text(
              'MiLingo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const Spacer(),
            _StatChip(
              icon: Icons.local_fire_department_rounded,
              value: stats.currentStreak.toString(),
              color: const Color(0xFFFF6B35),
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.diamond_rounded,
              value: stats.coins.toString(),
              color: const Color(0xFF7C5CBF),
            ),
            const SizedBox(width: 8),
            _StatChip(
              icon: Icons.emoji_events_rounded,
              value: stats.totalPoints.toString(),
              color: const Color(0xFFFFC107),
            ),
          ],
        ),
      );
    }

  // ── Weekly streak row ──────────────────────────────────────
  Widget _buildWeeklyStreak() {
      final stats = ref.watch(userStatsValueProvider);
      final today = DateTime.now().weekday; // 1=Mon … 7=Sun
      const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

      // Tính ngày học gần nhất từ backend
      DateTime? lastStudy;
      if (stats.lastStudyDate != null) {
        lastStudy = DateTime.tryParse(stats.lastStudyDate!);
      }

      final todayDate = DateTime.now();
      final todayOnly = DateTime(todayDate.year, todayDate.month, todayDate.day);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i + 1 == today;

              // isPast = ngày đó trong tuần này đã qua VÀ user có streak chứng tỏ đã học
              // Logic đơn giản: nếu có streak >= N thì N ngày gần nhất đều "đã học"
              final dayOfWeek = i + 1; // 1=Mon
              final daysAgoFromToday = today - dayOfWeek; // số ngày trước hôm nay
              bool isPast = false;

              if (daysAgoFromToday > 0 && stats.currentStreak > 0) {
                // Ngày đó trong quá khứ tuần này và streak đủ dài
                isPast = daysAgoFromToday <= stats.currentStreak;
              } else if (daysAgoFromToday == 0 && lastStudy != null) {
                // Hôm nay — check xem đã học chưa
                final lastStudyOnly = DateTime(lastStudy.year, lastStudy.month, lastStudy.day);
                isPast = lastStudyOnly == todayOnly;
              }

              return _DayCircle(
                label: days[i],
                isToday: isToday,
                isPast: isPast,
              );
            }),
          ),
        ),
      );
    }

  // ── Daily banner ───────────────────────────────────────────
  Widget _buildDailyBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.85),
              AppTheme.primaryColor,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '0/2 bài học miễn phí hôm nay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Nâng cấp',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ngay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Text('🌍', style: TextStyle(fontSize: 44)),
          ],
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────
// Stat chip in header
// ─────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Day circle for weekly streak
// ─────────────────────────────────────────────────────────

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.isToday,
    required this.isPast,
  });
  final String label;
  final bool isToday;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday
                ? AppTheme.primaryColor
                : isPast
                    ? AppTheme.primaryColor.withOpacity(0.15)
                    : const Color(0xFFF5F5F5),
            border: isToday
                ? null
                : Border.all(
                    color: isPast
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : const Color(0xFFE8E8E8),
                    width: 1.5,
                  ),
          ),
          child: Center(
            child: Icon(
              isPast || isToday
                  ? Icons.local_fire_department_rounded
                  : Icons.water_drop_outlined,
              size: 18,
              color: isToday
                  ? Colors.white
                  : isPast
                      ? AppTheme.primaryColor
                      : const Color(0xFFBDBDBD),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
            color: isToday ? AppTheme.primaryColor : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Feature card (Coach card style)
// ─────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.emojiBackground,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
    required this.onButtonTap,
    this.isHighlighted = false,
  });

  final String emoji;
  final Color emojiBackground;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;
  final VoidCallback onButtonTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isHighlighted
                ? Border.all(color: AppTheme.primaryColor.withOpacity(0.4), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: isHighlighted
                    ? AppTheme.primaryColor.withOpacity(0.12)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9E9E9E),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // CTA button
                    GestureDetector(
                      onTap: onButtonTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 9),
                        decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          buttonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Emoji illustration
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: emojiBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
