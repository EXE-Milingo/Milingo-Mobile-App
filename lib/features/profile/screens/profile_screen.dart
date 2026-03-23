import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 4),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ProfileTab(),
                  _PlaceholderTab(
                    icon: '🏅',
                    title: 'Thành tích',
                    subtitle: 'Hoàn thành các bài học để mở khóa thành tích.',
                  ),
                  _PlaceholderTab(
                    icon: '📊',
                    title: 'Bảng xếp hạng',
                    subtitle: 'Thi đua với bạn bè và leo lên bảng xếp hạng!',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Header ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Hồ sơ',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, size: 24),
            color: const Color(0xFF757575),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(3),
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'HỒ SƠ'),
            Tab(text: 'THÀNH TÍCH'),
            Tab(text: 'XẾP HẠNG'),
          ],
        ),
      ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
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
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go(AppConstants.homeRoute);
            case 1:
              context.push(AppConstants.snapAndLearnRoute);
            case 2:
              context.go(AppConstants.flashcardsRoute);
            case 3:
              break;
          }
        },
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
// Profile tab
// ─────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          _ProfileCard(),
          const SizedBox(height: 16),
          _StatsRow(),
          const SizedBox(height: 16),
          _ProficiencyCard(),
          const SizedBox(height: 20),
          Center(
            child: _UpgradePremiumButton(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _UpgradeModal(),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

// ── Profile info card ─────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarWidget(),
              const Spacer(),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name
          const Text(
            'Người dùng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'CEFR A1  •  Tự đánh giá',
            style: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0), height: 1),
          const SizedBox(height: 16),

          // Plan row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gói của bạn',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Miễn phí',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Nâng cấp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Avatar with camera overlay ────────────────────────────

class _AvatarWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('🦊', style: TextStyle(fontSize: 36)),
            ),
          ),
          // Camera badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF5F5F5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 13, color: Color(0xFF757575)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '0',
            label: 'Điểm',
            badgeEmoji: '⭐',
            badgeColor: const Color(0xFFFFF3E0),
            badgeIconColor: const Color(0xFFFFC107),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '10',
            label: 'Đá quý',
            badgeEmoji: '💎',
            badgeColor: const Color(0xFFEDE7F6),
            badgeIconColor: const Color(0xFF7C5CBF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '0',
            label: 'Streak',
            badgeEmoji: '🔥',
            badgeColor: const Color(0xFFFFEDE8),
            badgeIconColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.badgeEmoji,
    required this.badgeColor,
    required this.badgeIconColor,
  });

  final String value;
  final String label;
  final String badgeEmoji;
  final Color badgeColor;
  final Color badgeIconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      Text(badgeEmoji, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Proficiency card ──────────────────────────────────────

class _ProficiencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Năng lực của bạn',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tiếp tục học để mở khóa điểm số năng lực của bạn!',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProficiencyItem(label: 'Từ vựng', progress: 0.0),
              _ProficiencyItem(label: 'Phát âm', progress: 0.0),
              _ProficiencyItem(label: 'Ngữ pháp', progress: 0.0),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProficiencyItem extends StatelessWidget {
  const _ProficiencyItem({required this.label, required this.progress});

  final String label;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                color: const Color(0xFFF0F0F0),
              ),
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                color: AppTheme.primaryColor,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  progress == 0.0
                      ? '--'
                      : '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: progress == 0.0
                        ? const Color(0xFFBDBDBD)
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Achievements & Leaderboard placeholder tabs
// ─────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9E9E9E),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sắp ra mắt',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Upgrade Premium button
// ─────────────────────────────────────────────────────────

class _UpgradePremiumButton extends StatelessWidget {
  const _UpgradePremiumButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C1A0C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C1A0C).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/premium-icon.svg',
              width: 22,
              height: 22,
            ),
            const SizedBox(width: 10),
            const Text(
              'Nâng cấp Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Upgrade modal bottom sheet
// ─────────────────────────────────────────────────────────

class _UpgradeModal extends StatelessWidget {
  const _UpgradeModal();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF1C0E06),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  // Top bar: close + badge
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Text('⚡', style: TextStyle(fontSize: 13)),
                            SizedBox(width: 5),
                            Text(
                              'YÊU CẦU NÂNG CẤP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 34),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Lightning icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Mở khóa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'quyền truy cập\n',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        TextSpan(
                          text: 'PRO',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Quét vật thể không giới hạn, xây dựng vốn từ vựng nhanh hơn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),
                  Divider(color: Colors.white.withOpacity(0.1), height: 1),
                  const SizedBox(height: 20),

                  // Card 1 – exhausted scans
                  _UpgradeInfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.block_rounded,
                                color: Color(0xFFEF5350), size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Đã hết lượt quét miễn phí',
                                style: TextStyle(
                                  color: Color(0xFF9E9E9E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Còn 0 / 5',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress bar – full/red
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            backgroundColor:
                                Colors.white.withOpacity(0.1),
                            color: const Color(0xFFEF5350),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bạn đã dùng hết 5 lượt quét hôm nay. Nâng cấp hoặc xem quảng cáo để tiếp tục.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 2 – watch ad
                  _UpgradeInfoCard(
                    child: Row(
                      children: [
                        // Play button
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.primaryColor, width: 1.5),
                          ),
                          child: Icon(Icons.play_arrow_rounded,
                              color: AppTheme.primaryColor, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Xem quảng cáo 30s để thêm\n1 lượt quét',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '✦ MIỄN PHÍ',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '  •  KHÔNG THANH TOÁN',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.7),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white54, size: 22),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Upgrade PRO button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C1A0C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('⚡', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 10),
                          Text(
                            'Nâng cấp lên PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fine print
                  const Text(
                    'Bắt đầu miễn phí trong 7 ngày • Hủy bất kỳ lúc nào\nBy subscribing you agree to our Terms of Service & Privacy Policy.\nSubscription renews automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 11,
                      height: 1.6,
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

class _UpgradeInfoCard extends StatelessWidget {
  const _UpgradeInfoCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: child,
    );
  }
}
