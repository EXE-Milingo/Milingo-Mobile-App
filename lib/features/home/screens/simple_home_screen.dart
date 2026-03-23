import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  int _selectedTab = 0;

  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        setState(() => _selectedTab = 0);
      case 1:
        context.push(AppConstants.snapAndLearnRoute);
      case 2:
        context.go(AppConstants.flashcardsRoute);
      case 3:
        context.go(AppConstants.profileRoute);
    }
  }

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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Logo + app name
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
          // Stats chips
          _StatChip(
            icon: Icons.local_fire_department_rounded,
            value: '0',
            color: const Color(0xFFFF6B35),
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.diamond_rounded,
            value: '10',
            color: const Color(0xFF7C5CBF),
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.emoji_events_rounded,
            value: '0',
            color: const Color(0xFFFFC107),
          ),
        ],
      ),
    );
  }

  // ── Weekly streak row ──────────────────────────────────────
  Widget _buildWeeklyStreak() {
    final today = DateTime.now().weekday; // 1=Mon … 7=Sun
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

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
            final isPast = i + 1 < today;
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

  // ── Bottom navigation ─────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: const Color(0xFFBDBDBD),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt_rounded),
            label: 'Snap & Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style_rounded),
            label: 'Flashcards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
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
