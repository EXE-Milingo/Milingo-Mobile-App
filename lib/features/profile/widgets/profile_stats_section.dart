import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:milingo/features/leaderboard/providers/leaderboard_provider.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';
import 'package:milingo/features/profile/widgets/profile_view_data.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({
    required this.data,
    super.key,
  });

  final ProfileViewData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  width: width,
                  assetPath: 'assets/svg/new-profile/profile-star-icon.svg',
                  iconColor: const Color(0xFFFF6A00),
                  iconBackground: const Color(0x1AFF6A00),
                  emoji: '🔥',
                  value: _formatNumber(data.currentStreak),
                  label: 'Chuỗi ngày',
                  colors: const [Color(0xFFFFF1E6), Color(0xFFFFE2CC)],
                ),
                _MetricCard(
                  width: width,
                  assetPath: 'assets/svg/new-profile/star.svg',
                  iconColor: const Color(0xFFFFB300),
                  iconBackground: const Color(0x1AFFB300),
                  emoji: '⭐',
                  value: _formatCompact(data.totalPoints),
                  label: 'Tổng XP',
                  colors: const [Color(0xFFFFF6E0), Color(0xFFFFE9C2)],
                ),
                _MetricCard(
                  width: width,
                  assetPath: 'assets/svg/new-profile/profile-word-learn.svg',
                  iconColor: const Color(0xFFFF6A00),
                  iconBackground: const Color(0x1AFF6A00),
                  emoji: '📚',
                  value: _formatNumber(data.wordsLearned),
                  label: 'Từ đã học',
                  colors: const [Color(0xFFE9F7EC), Color(0xFFD4F0DC)],
                ),
                _MetricCard(
                  width: width,
                  assetPath: 'assets/svg/new-profile/profile-trophy.svg',
                  iconColor: const Color(0xFFFF6A00),
                  iconBackground: const Color(0x1AFF6A00),
                  emoji: '🏆',
                  value: '',
                  label: 'Thành tích',
                  colors: const [Color(0xFFFFE9E0), Color(0xFFFFD6C8)],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        const _RankCard(),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.assetPath,
    required this.iconColor,
    required this.iconBackground,
    required this.emoji,
    required this.value,
    required this.label,
    required this.colors,
  });

  final double width;
  final String assetPath;
  final Color iconColor;
  final Color iconBackground;
  final String emoji;
  final String value;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 98,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ProfileSvgIcon(
                  assetPath,
                  size: 14,
                  color: iconColor,
                ),
              ),
              const Spacer(),
              Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _StatsColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _StatsColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends ConsumerWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardNotifierProvider);

    return leaderboardAsync.when(
      loading: () =>
          _buildCard(rank: '#', subtitle: 'Đang tải...', progress: 0.0),
      error: (err, stack) =>
          _buildCard(rank: '#', subtitle: 'Lỗi tải xếp hạng', progress: 0.0),
      data: (state) {
        final currentUser = state.currentUser;
        if (currentUser == null) {
          return _buildCard(
              rank: '#', subtitle: 'Chưa có xếp hạng', progress: 0.0);
        }
        final points = currentUser.totalPoints;
        final progress = (points % 1000) / 1000.0;
        final nextMilestone = ((points / 1000).floor() + 1) * 1000;
        final xpNeeded = nextMilestone - points;

        return _buildCard(
          rank: '#${currentUser.rank}',
          subtitle:
              '${_formatCompact(points)} XP · Còn ${_formatCompact(xpNeeded)} XP để thăng cấp',
          progress: progress,
        );
      },
    );
  }

  Widget _buildCard({
    required String rank,
    required String subtitle,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      height: 122,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: _StatsColors.orange.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            bottom: -22,
            child: Opacity(
              opacity: 0.20,
              child: ProfileSvgIcon(
                'assets/svg/new-profile/profile-trophy.svg',
                size: 96,
                color: Colors.white,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                rank,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BẢNG XẾP HẠNG',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 56,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.black.withValues(alpha: 0.20),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(num value) {
  return NumberFormat.decimalPattern('vi_VN').format(value);
}

String _formatCompact(int value) {
  if (value >= 1000) {
    final k = value / 1000;
    final formatted = k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1);
    return '${formatted}k';
  }
  return _formatNumber(value);
}

class _StatsColors {
  static const text = Color(0xFF1D1814);
  static const muted = Color(0x8C1D1814);
  static const orange = Color(0xFFFF6A00);
}
