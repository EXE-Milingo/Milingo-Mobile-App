import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      height: 116,
      padding: const EdgeInsets.all(17),
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
            color: const Color(0xFF1D1814).withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: ProfileSvgIcon(
                    assetPath,
                    size: 20,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _StatsColors.text,
              fontSize: 24,
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

class _RankCard extends StatelessWidget {
  const _RankCard();

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Text(
                '#',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bảng xếp hạng',
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
                    SizedBox(height: 3),
                    Text(
                      '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
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
                value: 0,
                minHeight: 10,
                backgroundColor: Colors.black.withValues(alpha: 0.20),
                color: Colors.white,
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
