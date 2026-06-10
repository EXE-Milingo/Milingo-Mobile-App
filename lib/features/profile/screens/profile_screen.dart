import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/profile/screens/account_settings_screen.dart';
import 'package:milingo/features/profile/screens/language_goal_screen.dart';
import 'package:milingo/features/profile/widgets/payment_method_view.dart';
import 'package:milingo/features/profile/widgets/restore_purchase_flow.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class _ProfileColors {
  static const background = Color(0xFFFDF8F6);
  static const primary = AppTheme.primaryColor;
  static const primaryDark = Color(0xFFAC2D03);
  static const text = Color(0xFF1C1B1B);
  static const mutedText = Color(0xFF765753);
  static const iconBubble = Color(0xFFEBE7E5);
  static const cardSurface = Color(0xFFFFF8F6);
  static const leaderSurface = Color(0xFFFFF1ED);
  static const leaderBorder = Color(0xFFE1BFB5);
  static const progressTrack = Color(0xFFEDD5CE);
  static const progressFill = Color(0xFFE4502E);
  static const badgeBg = Color(0xFFEDD5CE);
  static const rankText = Color(0xFF941C00);
  static const linkBlue = Color(0xFF003CA3);
  static const logoutBg = Color(0xFFFADCD2);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _ProfileColors.background,
      body: SafeArea(bottom: false, child: _ProfileContent()),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final stats = ref.watch(userStatsValueProvider);
    final leaderboard = _leaderboardSummaryFor(stats);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileHeader(user: user, profile: profile),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHero(
                  user: user,
                  profile: profile,
                  displayName: _displayNameFor(user, profile),
                  subtitle: _memberSinceLabel(user),
                ),
                const SizedBox(height: 19),
                _PremiumButton(
                  onTap: () => context.push(AppConstants.premiumRoute),
                ),
                const SizedBox(height: 19),
                _SettingsPanel(
                  stats: stats,
                  leaderboard: leaderboard,
                  onAccountSettings: () =>
                      _openAccountSettings(context, user, profile),
                  onLanguageGoal: () => _openLanguageGoal(context),
                  onTheme: () {},
                  onPurchases: () =>
                      context.push(AppConstants.subscriptionRoute),
                ),
                const SizedBox(height: 19),
                const _LogoutButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _displayNameFor(User? user, UserProfileResponse? profile) {
    final profileName = profile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;

    final firebaseName = user?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;

    final emailName = user?.email?.split('@').first.trim();
    if (emailName != null && emailName.isNotEmpty) return emailName;

    return 'Người dùng';
  }

  static String _memberSinceLabel(User? user) {
    final year = user?.metadata.creationTime?.year ?? DateTime.now().year;
    return 'Thành viên từ $year';
  }

  static _ProfileLeaderboardSummary _leaderboardSummaryFor(
    UserStatsResponse stats,
  ) {
    final totalPoints = stats.totalPoints;
    final xpRemaining = _xpToNextLeague(totalPoints);
    final rank = ((100000 - totalPoints).clamp(0, 99999) ~/ 850) + 1;

    return _ProfileLeaderboardSummary(
      rankLabel: 'Hạng $rank',
      leagueLabel: _leagueFor(totalPoints),
      progressLabel: xpRemaining == 0
          ? 'Bạn đang ở hạng cao nhất'
          : 'Còn $xpRemaining XP để thăng hạng',
      nextLeagueLabel: xpRemaining == 0
          ? _leagueFor(totalPoints)
          : _leagueFor(totalPoints + xpRemaining),
      progress: _leagueProgress(totalPoints),
    );
  }

  static String _leagueFor(int xp) {
    if (xp >= 5000) return 'Giải Kim Cương';
    if (xp >= 2400) return 'Giải Bạch Kim';
    if (xp >= 1000) return 'Giải Vàng';
    if (xp >= 400) return 'Giải Bạc';
    return 'Giải Đồng';
  }

  static int _xpToNextLeague(int xp) {
    const thresholds = [400, 1000, 2400, 5000];
    for (final threshold in thresholds) {
      if (xp < threshold) return threshold - xp;
    }
    return 0;
  }

  static double _leagueProgress(int xp) {
    const thresholds = [0, 400, 1000, 2400, 5000];
    if (xp >= thresholds.last) return 1;

    for (var i = 1; i < thresholds.length; i++) {
      if (xp < thresholds[i]) {
        final lower = thresholds[i - 1];
        final upper = thresholds[i];
        return ((xp - lower) / (upper - lower)).clamp(0, 1).toDouble();
      }
    }

    return 0;
  }

  static void _openAccountSettings(
    BuildContext context,
    User? user,
    UserProfileResponse? profile,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AccountSettingsScreen(profile: _accountProfile(user, profile)),
      ),
    );
  }

  static void _openLanguageGoal(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LanguageGoalScreen(),
      ),
    );
  }

  static AccountSettingsProfile _accountProfile(
    User? user,
    UserProfileResponse? profile,
  ) {
    final name = _displayNameFor(user, profile);
    final parts = name.split(RegExp(r'\s+'));

    return AccountSettingsProfile(
      displayName: name,
      email: profile?.email.trim().isNotEmpty == true
          ? profile!.email
          : (user?.email ?? ''),
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
  }
}

class _ProfileLeaderboardSummary {
  const _ProfileLeaderboardSummary({
    required this.rankLabel,
    required this.leagueLabel,
    required this.progressLabel,
    required this.nextLeagueLabel,
    required this.progress,
  });

  final String rankLabel;
  final String leagueLabel;
  final String progressLabel;
  final String nextLeagueLabel;
  final double progress;
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.profile});

  final User? user;
  final UserProfileResponse? profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _AvatarImage(
              user: user,
              profile: profile,
              size: 40,
              borderWidth: 0,
              shadow: const [
                BoxShadow(
                  color: Color(0x1AAC2D03),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            const Text(
              'Hồ sơ',
              style: TextStyle(
                color: _ProfileColors.primaryDark,
                fontSize: 18,
                height: 28 / 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: const _ProfileSvgIcon(
                'assets/svg/profile/settings.svg',
                width: 24,
                height: 24,
                color: _ProfileColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.profile,
    required this.displayName,
    required this.subtitle,
  });

  final User? user;
  final UserProfileResponse? profile;
  final String displayName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 168,
              height: 168,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33AC2D03),
                    blurRadius: 32,
                    spreadRadius: -10,
                  ),
                ],
              ),
            ),
            _AvatarImage(
              user: user,
              profile: profile,
              size: 112,
              borderWidth: 4,
              shadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 25,
                  offset: Offset(0, 20),
                ),
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 8),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ProfileColors.text,
            fontSize: 24,
            height: 32 / 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ProfileColors.mutedText,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _PremiumButton extends StatelessWidget {
  const _PremiumButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEF9831), Color(0xFFE3492D)],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x331C1917),
                blurRadius: 50,
                offset: Offset(0, 25),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Row(
            children: [
              Transform.rotate(
                angle: 0.2,
                child: const _ProfileSvgIcon(
                  'assets/svg/premium-icon.svg',
                  width: 30,
                  height: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nâng cấp Premium',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const _ProfileSvgIcon(
                'assets/svg/profile/chevron-right.svg',
                width: 8,
                height: 12,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.stats,
    required this.leaderboard,
    required this.onAccountSettings,
    required this.onLanguageGoal,
    required this.onTheme,
    required this.onPurchases,
  });

  final UserStatsResponse stats;
  final _ProfileLeaderboardSummary leaderboard;
  final VoidCallback onAccountSettings;
  final VoidCallback onLanguageGoal;
  final VoidCallback onTheme;
  final VoidCallback onPurchases;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 32, sigmaY: 32),
        child: Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              _StatsBentoGrid(stats: stats),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                child: _LeaderboardCard(summary: leaderboard, onTap: () {}),
              ),
              const SizedBox(height: 16),
              _SettingsTile(
                assetPath: 'assets/svg/profile_setting.svg',
                label: 'Cài đặt tài khoản',
                onTap: onAccountSettings,
              ),
              _SettingsTile(
                assetPath: 'assets/svg/flag.svg',
                label: 'Mục tiêu ngôn ngữ',
                onTap: onLanguageGoal,
              ),
              _SettingsTile(
                assetPath: 'assets/svg/theme.svg',
                label: 'Giao diện ứng dụng',
                onTap: onTheme,
              ),
              _SettingsTile(
                assetPath: 'assets/svg/purchase.svg',
                label: 'Quản lý gói mua',
                onTap: onPurchases,
                emphasized: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsBentoGrid extends StatelessWidget {
  const _StatsBentoGrid({required this.stats});

  final UserStatsResponse stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: const _ProfileSvgIcon(
              'assets/svg/streak.svg',
              width: 20,
              height: 22.5,
            ),
            value: stats.currentStreak.toString(),
            label: 'CHUỖI NGÀY',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Image.asset(
              'assets/svg/xp.png',
              width: 25,
              height: 25,
            ),
            value: _formatXp(stats.totalPoints),
            label: 'TỔNG XP',
          ),
        ),
      ],
    );
  }

  static String _formatXp(int value) {
    if (value >= 1000) {
      final k = value / 1000;
      final formatted =
          k % 1 == 0 ? k.toInt().toString() : k.toStringAsFixed(1);
      return '${formatted}k';
    }

    return value.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _ProfileColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D251814),
            blurRadius: 16,
            offset: Offset(8, 8),
          ),
          BoxShadow(
            color: Color(0xCCFFFFFF),
            blurRadius: 16,
            offset: Offset(-8, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileColors.rankText,
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  const _LeaderboardCard({required this.summary, required this.onTap});

  final _ProfileLeaderboardSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: _ProfileColors.leaderSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _ProfileColors.leaderBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _ProfileColors.progressFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: _ProfileSvgIcon(
                        'assets/svg/rank.svg',
                        width: 18,
                        height: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bảng xếp hạng tuần',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _ProfileColors.rankText,
                            fontSize: 18,
                            height: 28 / 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              summary.rankLabel,
                              style: const TextStyle(
                                color: _ProfileColors.text,
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _ProfileColors.badgeBg,
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                summary.leagueLabel,
                                style: const TextStyle(
                                  color: _ProfileColors.text,
                                  fontSize: 12,
                                  height: 16 / 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const _ProfileSvgIcon(
                    'assets/svg/profile/chevron-right.svg',
                    width: 8,
                    height: 12,
                    color: _ProfileColors.progressFill,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    summary.nextLeagueLabel,
                    style: const TextStyle(
                      color: _ProfileColors.linkBlue,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(9999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: summary.progress,
                  backgroundColor: _ProfileColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _ProfileColors.progressFill,
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.assetPath,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _ProfileColors.iconBubble,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _ProfileSvgIcon(
                    assetPath,
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ProfileColors.text,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const _ProfileSvgIcon(
                'assets/svg/right-arrow.svg',
                width: 7,
                height: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerStatefulWidget {
  const _LogoutButton();

  @override
  ConsumerState<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends ConsumerState<_LogoutButton> {
  bool _busy = false;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await FirebaseAuth.instance.signOut();
      ref.invalidate(userStatsProvider);
      if (mounted) context.go(AppConstants.authRoute);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Không thể đăng xuất. Vui lòng thử lại.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: _busy ? null : _handleLogout,
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: _ProfileColors.logoutBg,
          disabledBackgroundColor: _ProfileColors.logoutBg,
          foregroundColor: _ProfileColors.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const _ProfileSvgIcon(
                'assets/svg/logout.svg',
                width: 15,
                height: 15,
                color: _ProfileColors.text,
              ),
        label: Text(_busy ? 'Đang đăng xuất...' : 'Đăng xuất'),
      ),
    );
  }
}

class _UpgradeModal extends ConsumerStatefulWidget {
  const _UpgradeModal();

  @override
  ConsumerState<_UpgradeModal> createState() => _UpgradeModalState();
}

class _UpgradeModalState extends ConsumerState<_UpgradeModal> {
  bool _yearly = false;
  bool _showTerms = false;
  bool _showRestore = false;
  PaymentPlanSummary? _paymentPlan;

  static const _paymentMethods = [
    PaymentMethodOption(
      id: 'apple_pay',
      title: 'Apple Pay',
      icon: Icons.phone_iphone_rounded,
    ),
    PaymentMethodOption(
      id: 'card',
      title: 'Thẻ Visa/Mastercard',
      subtitle: '**** **** **** 4242',
      icon: Icons.credit_card_rounded,
    ),
    PaymentMethodOption(
      id: 'momo',
      title: 'Ví MoMo',
      icon: Icons.account_balance_wallet_outlined,
    ),
    PaymentMethodOption(
      id: 'bank_qr',
      title: 'QR Ngân hàng',
      icon: Icons.qr_code_2_rounded,
    ),
  ];

  static const _restorePackages = [
    RestorePurchasePackage(
      name: 'Gói Pro Năm',
      expiryLabel: 'Hết hạn: 24/12/2024',
      status: RestorePurchaseStatus.restorable,
      storeLabel: 'Google Play',
    ),
    RestorePurchasePackage(
      name: 'Gói Plus Tháng',
      expiryLabel: 'Hết hạn: 15/08/2023',
      status: RestorePurchaseStatus.expired,
      storeLabel: 'Google Play',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_showRestore) {
      return RestorePurchaseFlow(
        packages: _restorePackages,
        onBack: () => setState(() => _showRestore = false),
        onManageAccount: () => Navigator.of(context).pop(),
      );
    }

    if (_showTerms) {
      return _TermsOfServiceView(
        onBack: () => setState(() => _showTerms = false),
      );
    }

    final paymentPlan = _paymentPlan;
    if (paymentPlan != null) {
      return PaymentMethodView(
        plan: paymentPlan,
        methods: _paymentMethods,
        initialMethodId: 'card',
        onClose: () => setState(() => _paymentPlan = null),
        onChangePlan: () => setState(() => _paymentPlan = null),
        onConfirmPayment: _confirmPayment,
      );
    }

    return Container(
      height: MediaQuery.sizeOf(context).height,
      decoration: const BoxDecoration(
        color: _ProfileColors.background,
      ),
      child: SafeArea(
        child: Column(
          children: [
            _UpgradeTopBar(onClose: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    const _UpgradeHero(),
                    const SizedBox(height: 22),
                    _BillingToggle(
                      yearly: _yearly,
                      onChanged: (value) => setState(() => _yearly = value),
                    ),
                    const SizedBox(height: 26),
                    _PlanCard(
                      title: 'Gói Plus',
                      price: '59.000đ',
                      suffix: '/tuần',
                      cta: 'Chọn gói Plus',
                      onCtaTap: () => setState(
                        () => _paymentPlan = _buildPaymentPlan(
                          planId: 'plus',
                          planName: 'Milingo Plus',
                          totalPrice: 59000,
                          durationLabel: '1 Tuần',
                        ),
                      ),
                      features: const [
                        'Quét 100 vật thể/ngày',
                        'AI Tutor cơ bản',
                        'Không quảng cáo',
                      ],
                    ),
                    const SizedBox(height: 30),
                    _PlanCard(
                      title: _yearly ? 'Gói Ultra ✪' : 'Gói Pro',
                      price: _yearly ? '510.000đ' : '139.000đ',
                      suffix: _yearly ? '/năm' : '/tháng',
                      cta: null,
                      highlighted: true,
                      badge: _yearly ? 'PHỔ BIẾN NHẤT' : 'PHỔ BIẾN',
                      features: const [
                        'Quét không giới hạn',
                        'AI Tutor cá nhân hóa 24/7',
                        'Phân tích phát âm chuyên sâu',
                        'Chờ đội ngoại tuyến',
                      ],
                    ),
                    const SizedBox(height: 50),
                    _StartNowButton(
                      onTap: () => setState(
                        () => _paymentPlan = _buildPaymentPlan(
                          planId: _yearly ? 'ultra' : 'pro',
                          planName: _yearly ? 'Milingo Ultra' : 'Milingo Pro',
                          totalPrice: _yearly ? 510000 : 139000,
                          durationLabel: _yearly ? '1 Năm' : '1 Tháng',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _UpgradeLinks(
                      onRestoreTap: () => setState(() => _showRestore = true),
                      onTermsTap: () => setState(() => _showTerms = true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(
    PaymentMethodOption method,
    PaymentPlanSummary plan,
  ) async {
    if (method.id != 'bank_qr') {
      _showPaymentSnackBar(
        'Phương thức này chưa hỗ trợ. Hãy chọn QR Ngân hàng để thanh toán qua PayOS.',
        isError: true,
      );
      return;
    }

    try {
      final order = await ref.read(milingoApiServiceProvider).createPayOSOrder(
            planId: plan.planId,
            returnUrl: AppConstants.paymentReturnUrl,
            cancelUrl: AppConstants.paymentCancelUrl,
          );

      final checkoutUri = Uri.tryParse(order.checkoutUrl);
      if (checkoutUri == null || !checkoutUri.hasScheme) {
        throw const MilingoApiException('Link thanh toán không hợp lệ.');
      }

      final launched = await launchUrl(
        checkoutUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw const MilingoApiException('Không mở được PayOS checkout.');
      }
    } catch (error) {
      if (!mounted) return;
      _showPaymentSnackBar(_paymentErrorMessage(error), isError: true);
    }
  }

  String _paymentErrorMessage(Object error) {
    if (error is MilingoApiException) return error.message;
    return 'Không thể tạo thanh toán. Vui lòng thử lại.';
  }

  void _showPaymentSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? AppTheme.errorColor : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  PaymentPlanSummary _buildPaymentPlan({
    required String planId,
    required String planName,
    required int totalPrice,
    required String durationLabel,
  }) {
    final totalLabel = NumberFormat.decimalPattern('en_US').format(totalPrice);

    return PaymentPlanSummary(
      planId: planId,
      planLabel: '$planName - $durationLabel',
      totalLabel: '$totalLabel đ',
      buttonTotalLabel: '$totalLabel đ',
    );
  }
}

class _UpgradeTopBar extends StatelessWidget {
  const _UpgradeTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFF7B5E55),
              iconSize: 20,
            ),
          ),
          const Text(
            'Nâng cấp Premium',
            style: TextStyle(
              color: _ProfileColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.user,
    required this.profile,
    required this.size,
    required this.borderWidth,
    required this.shadow,
  });

  final User? user;
  final UserProfileResponse? profile;
  final double size;
  final double borderWidth;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final localPath = profile?.localAvatarPath;
    final profilePhoto = profile?.photoUrl?.trim();
    final firebasePhoto = user?.photoURL?.trim();
    final networkPhoto = profilePhoto?.isNotEmpty == true
        ? profilePhoto
        : firebasePhoto?.isNotEmpty == true
            ? firebasePhoto
            : null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
        boxShadow: shadow,
      ),
      child: ClipOval(
        child: localPath != null && localPath.isNotEmpty
            ? Image.file(
                io.File(localPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackAvatar(),
              )
            : networkPhoto == null
                ? _fallbackAvatar()
                : Image.network(
                    networkPhoto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackAvatar(),
                  ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Image.asset('assets/images/app-icon.png', fit: BoxFit.cover);
  }
}

class _ProfileSvgIcon extends StatelessWidget {
  const _ProfileSvgIcon(
    this.assetPath, {
    required this.width,
    required this.height,
    this.color,
  });

  final String assetPath;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class _UpgradeHero extends StatelessWidget {
  const _UpgradeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _ProfileColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        children: [
          _ProfileSvgIcon(
            'assets/svg/premium-icon.svg',
            width: 54,
            height: 54,
          ),
          SizedBox(height: 18),
          Text(
            'Mở khóa Milingo Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProfileColors.text,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Học nhanh hơn với quét không giới hạn, AI tutor cá nhân hóa và trải nghiệm không quảng cáo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ProfileColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.yearly,
    required this.onChanged,
  });

  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _BillingOption(
              label: 'Hàng tháng',
              selected: !yearly,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _BillingOption(
              label: 'Hàng năm',
              selected: yearly,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingOption extends StatelessWidget {
  const _BillingOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ProfileColors.text,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.suffix,
    required this.features,
    this.cta,
    this.onCtaTap,
    this.highlighted = false,
    this.badge,
  });

  final String title;
  final String price;
  final String suffix;
  final List<String> features;
  final String? cta;
  final VoidCallback? onCtaTap;
  final bool highlighted;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          decoration: BoxDecoration(
            color: highlighted ? _ProfileColors.background : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: highlighted
                ? Border.all(color: _ProfileColors.primary, width: 2)
                : null,
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: _ProfileColors.primary.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: highlighted
                      ? _ProfileColors.primary
                      : _ProfileColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: _ProfileColors.text,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 2),
                    child: Text(
                      suffix,
                      style: const TextStyle(
                        color: _ProfileColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              for (final feature in features) ...[
                _PlanFeature(text: feature),
                const SizedBox(height: 11),
              ],
              if (cta != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: onCtaTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD8CF),
                      foregroundColor: _ProfileColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text(cta!),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (badge != null)
          Positioned(
            top: -1,
            right: 0,
            child: Container(
              height: 27,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _ProfileColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlanFeature extends StatelessWidget {
  const _PlanFeature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: _ProfileColors.primary,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _ProfileColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartNowButton extends StatelessWidget {
  const _StartNowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _ProfileColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
          elevation: 9,
          shadowColor: _ProfileColors.primary.withValues(alpha: 0.28),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bắt đầu ngay'),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _UpgradeLinks extends StatelessWidget {
  const _UpgradeLinks({
    required this.onRestoreTap,
    required this.onTermsTap,
  });

  final VoidCallback onRestoreTap;
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onRestoreTap,
          child: const Text(
            'Khôi phục gói mua',
            style: TextStyle(
              color: _ProfileColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 24),
        GestureDetector(
          onTap: onTermsTap,
          child: const Text(
            'Điều khoản dịch vụ',
            style: TextStyle(
              color: _ProfileColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TermsOfServiceView extends StatelessWidget {
  const _TermsOfServiceView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      color: _ProfileColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _TermsHeader(onBack: onBack),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, 32, 14, 28),
                child: _TermsCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsHeader extends StatelessWidget {
  const _TermsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFFFC8B8), width: 1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: _ProfileColors.primary,
              iconSize: 22,
            ),
          ),
          const Text(
            'Điều khoản dịch vụ',
            style: TextStyle(
              color: _ProfileColors.primaryDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFBFAF), width: 1),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CẬP NHẬT LẦN CUỐI: 30/06/2026',
            style: TextStyle(
              color: _ProfileColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chào mừng bạn đến với\nnền tảng của chúng tôi',
            style: TextStyle(
              color: _ProfileColors.text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Vui lòng đọc kỹ Điều khoản Dịch vụ này trước khi truy cập hoặc sử dụng dịch vụ của chúng tôi. Bằng cách sử dụng nền tảng của chúng tôi, bạn đồng ý bị ràng buộc bởi các điều khoản này, thiết lập một môi trường công nghệ tiên tiến, đáng tin cậy cho tất cả người dùng.',
            style: _TermsTextStyles.body,
          ),
          SizedBox(height: 22),
          Divider(color: Color(0xFFFFC8B8), height: 1),
          SizedBox(height: 26),
          _TermsSection(
            icon: Icons.verified_user_outlined,
            title: '1. Chấp nhận các điều khoản',
            child: _TermsInsetBox(
              children: [
                Text(
                  'Bằng cách đăng ký và/hoặc sử dụng Dịch vụ theo bất kỳ cách nào, bao gồm nhưng không giới hạn ở việc truy cập hoặc duyệt Trang web, bạn đồng ý với các Điều khoản Dịch vụ này và tất cả các quy tắc, chính sách và thủ tục hoạt động khác mà chúng tôi có thể công bố theo thời gian trên Trang web.',
                  style: _TermsTextStyles.body,
                ),
                SizedBox(height: 14),
                Text(
                  'Các Điều khoản Dịch vụ này áp dụng cho tất cả người dùng Dịch vụ, bao gồm cả người dùng đồng thời là người đóng góp nội dung, thông tin và các tài liệu hoặc dịch vụ khác, dù đã đăng ký hay chưa.',
                  style: _TermsTextStyles.body,
                ),
              ],
            ),
          ),
          SizedBox(height: 28),
          _TermsSection(
            icon: Icons.note_add_outlined,
            title: '2. Nội dung người dùng',
            child: _TermsTimelineText(),
          ),
          SizedBox(height: 28),
          _TermsSection(
            icon: Icons.gpp_good_outlined,
            title: '3. Chính sách bảo mật',
            child: _PrivacyPolicyText(),
          ),
          SizedBox(height: 30),
          _TermsSupportBox(),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: _ProfileColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _TermsInsetBox extends StatelessWidget {
  const _TermsInsetBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFD2C6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TermsTimelineText extends StatelessWidget {
  const _TermsTimelineText();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 2),
      padding: const EdgeInsets.only(left: 28),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFFFFC8B8), width: 1),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tất cả nội dung được người dùng thêm vào, tạo ra, tải lên, gửi đi, phân phối hoặc đăng tải lên Dịch vụ, cho dù được đăng công khai hay truyền tải riêng tư, đều thuộc trách nhiệm duy nhất của người đã tạo ra Nội dung Người dùng đó.',
            style: _TermsTextStyles.body,
          ),
          SizedBox(height: 22),
          Text(
            'Bạn vẫn giữ quyền sở hữu hoàn toàn đối với tài sản trí tuệ của mình.',
            style: _TermsTextStyles.body,
          ),
          SizedBox(height: 22),
          Text(
            'Chúng tôi yêu cầu giấy phép để lưu trữ và hiển thị nội dung của bạn một cách an toàn.',
            style: _TermsTextStyles.body,
          ),
          SizedBox(height: 22),
          Text(
            'Nội dung không được vi phạm bất kỳ quy định bảo vệ dữ liệu quốc tế nào.',
            style: _TermsTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        style: _TermsTextStyles.body,
        children: [
          TextSpan(
            text:
                'Để biết thông tin về cách chúng tôi thu thập, sử dụng và tiết lộ thông tin cá nhân của bạn, vui lòng xem lại ',
          ),
          TextSpan(
            text: 'Chính sách Bảo mật toàn diện',
            style: TextStyle(
              color: _ProfileColors.primary,
              fontWeight: FontWeight.w900,
              decoration: TextDecoration.underline,
              decorationColor: _ProfileColors.primary,
            ),
          ),
          TextSpan(
            text:
                ' của chúng tôi. Việc bạn sử dụng Dịch vụ cho thấy bạn đồng ý với các hoạt động dữ liệu được nêu trong Chính sách Bảo mật.',
          ),
        ],
      ),
    );
  }
}

class _TermsSupportBox extends StatelessWidget {
  const _TermsSupportBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDE7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn cần hỗ trợ?',
            style: TextStyle(
              color: _ProfileColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vui lòng liên hệ với đội ngũ pháp lý của chúng tôi để được làm rõ bất kỳ điều khoản nào.',
            style: TextStyle(
              color: _ProfileColors.mutedText,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: SizedBox(
              width: 150,
              height: 36,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _ProfileColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Liên hệ bộ phận hỗ trợ'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsTextStyles {
  static const body = TextStyle(
    color: Color(0xFF6F5148),
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
}
