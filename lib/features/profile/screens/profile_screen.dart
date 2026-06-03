import 'dart:io' as io;
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/profile/widgets/account_settings_view.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

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
                  onLanguageGoal: () {},
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
            AccountSettingsView(profile: _accountProfile(user, profile)),
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
                width: 18,
                height: 18,
              ),
        label: const Text('Đăng xuất'),
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
