import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _ProfileColors.background,
      body: SafeArea(
        bottom: false,
        child: _ProfileContent(),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 4),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _displayNameFor(user);
    final memberSince = _memberSinceFor(user);
    final stats = ref.watch(userStatsValueProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      child: Column(
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 23),
          _MainAvatar(user: user),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            memberSince,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 25),
          _StatsRow(stats: stats),
          const SizedBox(height: 25),
          _PremiumButton(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _UpgradeModal(),
            ),
          ),
          const SizedBox(height: 25),
          const _SettingsCard(),
          const SizedBox(height: 32),
          const _LogoutButton(),
        ],
      ),
    );
  }

  static String _displayNameFor(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Milingo';
  }

  static String _memberSinceFor(User? user) {
    final createdAt = user?.metadata.creationTime;
    final year = createdAt?.year ?? DateTime.now().year;
    return 'Thành viên từ $year';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SmallAvatar(user: user),
          ),
          const Text(
            'Hồ sơ',
            style: TextStyle(
              color: _ProfileColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined),
              color: _ProfileColors.primary,
              iconSize: 21,
              splashRadius: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: 34,
                height: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return _AvatarImage(
      user: user,
      size: 30,
      borderWidth: 1.2,
      shadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}

class _MainAvatar extends StatelessWidget {
  const _MainAvatar({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    return _AvatarImage(
      user: user,
      size: 76,
      borderWidth: 3,
      shadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 14,
          offset: Offset(0, 7),
        ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.user,
    required this.size,
    required this.borderWidth,
    required this.shadow,
  });

  final User? user;
  final double size;
  final double borderWidth;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;

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
        child: photoUrl == null || photoUrl.isEmpty
            ? Image.asset(
                'assets/images/app-icon.png',
                fit: BoxFit.cover,
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/app-icon.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final UserStatsResponse stats;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('en_US');

    return Row(
      children: [
        Expanded(
          child: _StatBubble(
            icon: Icons.stacked_bar_chart_rounded,
            label: 'LƯỢT QUÉT',
            value: formatter.format(stats.totalPoints),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatBubble(
            icon: Icons.monetization_on_rounded,
            label: 'XU',
            value: formatter.format(stats.coins),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: _StatBubble(
            icon: Icons.workspace_premium_rounded,
            label: 'HẠNG',
            value: 'Vàng',
          ),
        ),
      ],
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F7C3B24),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _ProfileColors.primaryDark, size: 16),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileColors.softText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: _ProfileColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF56835),
                Color(0xFFFF8B22),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F56835),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                _PremiumBadge(),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nâng cấp Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: _ProfileColors.primary,
        size: 13,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D7C3B24),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          _SettingsItem(
            icon: Icons.manage_accounts_outlined,
            label: 'Cài đặt tài khoản',
          ),
          _SettingsItem(
            icon: Icons.flag_outlined,
            label: 'Mục tiêu ngôn ngữ',
          ),
          _SettingsItem(
            icon: Icons.palette_outlined,
            label: 'Giao diện ứng dụng',
          ),
          _SettingsItem(
            icon: Icons.receipt_long_outlined,
            label: 'Quản lý gói mua',
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 53,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _ProfileColors.iconBubble,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: _ProfileColors.icon,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ProfileColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: _ProfileColors.chevron,
                  size: 19,
                ),
              ],
            ),
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
  bool _isSigningOut = false;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;

    setState(() => _isSigningOut = true);

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
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 33,
      child: FilledButton.icon(
        onPressed: _isSigningOut ? null : _handleLogout,
        icon: _isSigningOut
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_rounded, size: 15),
        label: Text(_isSigningOut ? 'Đang đăng xuất...' : 'Đăng xuất'),
        style: FilledButton.styleFrom(
          backgroundColor: _ProfileColors.logoutBackground,
          foregroundColor: _ProfileColors.text,
          disabledBackgroundColor:
              _ProfileColors.logoutBackground.withValues(alpha: 0.7),
          disabledForegroundColor: _ProfileColors.text.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UpgradeModal extends StatelessWidget {
  const _UpgradeModal();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7DAD4),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),
            const _PremiumBadge(),
            const SizedBox(height: 14),
            const Text(
              'Nâng cấp Premium',
              style: TextStyle(
                color: _ProfileColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mở khóa nhiều lượt quét hơn và tiếp tục học không gián đoạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfileColors.mutedText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _ProfileColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tiếp tục'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileColors {
  static const background = Color(0xFFFFF9F6);
  static const primary = AppTheme.primaryColor;
  static const primaryDark = Color(0xFFC6491F);
  static const text = Color(0xFF221914);
  static const mutedText = Color(0xFF8E7167);
  static const softText = Color(0xFF9C8178);
  static const iconBubble = Color(0xFFF0EAE8);
  static const icon = Color(0xFF907972);
  static const chevron = Color(0xFFE6B1A2);
  static const logoutBackground = Color(0xFFFFDED6);
}
