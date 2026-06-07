import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/gamification/providers/user_stats_provider.dart';
import 'package:milingo/features/profile/widgets/account_settings_view.dart';
import 'package:milingo/features/profile/widgets/language_goal_view.dart';
import 'package:milingo/features/profile/widgets/payment_method_view.dart';
import 'package:milingo/features/profile/widgets/purchase_management_view.dart';
import 'package:milingo/features/profile/widgets/restore_purchase_flow.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

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
          _SettingsCard(
            onAccountTap: () => _openAccountSettings(context, user),
            onLanguageGoalTap: () => _openLanguageGoals(context),
            onPurchaseTap: () => _openPurchaseManagement(context, user),
          ),
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

  static void _openAccountSettings(BuildContext context, User? user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountSettingsView(
          profile: _accountProfileFor(user),
        ),
      ),
    );
  }

  static AccountSettingsProfile _accountProfileFor(User? user) {
    final displayName = _displayNameFor(user);
    final email = user?.email?.trim();
    final parts = displayName.split(RegExp(r'\s+'));
    final firstName = parts.isEmpty ? displayName : parts.first;
    final lastName = parts.length <= 1 ? '' : parts.sublist(1).join(' ');

    return AccountSettingsProfile(
      displayName: displayName,
      email: email == null || email.isEmpty ? 'user@example.com' : email,
      firstName: firstName,
      lastName: lastName,
    );
  }

  static void _openLanguageGoals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LanguageGoalView(
          data: _languageGoalData(),
        ),
      ),
    );
  }

  static LanguageGoalData _languageGoalData() {
    return const LanguageGoalData(
      activeLanguageName: 'Tiếng Anh',
      activeLanguageFlag: 'assets/images/uk.png',
      vocabularyCountLabel: '1.2k',
      languages: [
        LanguageGoalOption(
          code: 'fr',
          label: 'PHÁP',
          flag: 'assets/images/france.png',
        ),
        LanguageGoalOption(
          code: 'en',
          label: 'ANH (Đang\nhọc)',
          flag: 'assets/images/uk.png',
          selected: true,
        ),
        LanguageGoalOption(
          code: 'jp',
          label: 'NHẬT',
          flag: 'assets/images/jp.png',
        ),
      ],
      goals: [
        WeeklyLanguageGoal(
          title: 'Học 50 từ mới',
          progressLabel: '42 / 50 từ',
          progress: 0.84,
          icon: Icons.volume_up_rounded,
          iconBackground: Color(0xFFFFD8CB),
          iconColor: Color(0xFFF25F36),
          completed: true,
        ),
        WeeklyLanguageGoal(
          title: 'Hoàn thành 3 AR scans',
          progressLabel: '1 / 3 scans',
          progress: 0.33,
          icon: Icons.center_focus_strong_rounded,
          iconBackground: Color(0xFFDDF1FF),
          iconColor: Color(0xFF177BC6),
        ),
      ],
    );
  }

  static void _openPurchaseManagement(BuildContext context, User? user) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PurchaseManagementView(
          data: _purchaseManagementData(user),
        ),
      ),
    );
  }

  static PurchaseManagementData _purchaseManagementData(User? user) {
    final createdAt = user?.metadata.creationTime;
    final memberSince = createdAt == null
        ? 'Tháng 8,\n2023'
        : 'Tháng ${createdAt.month},\n${createdAt.year}';

    return PurchaseManagementData(
      plan: const CurrentPurchasePlan(
        name: 'Gói Premium\nNăm',
        statusLabel: 'ĐANG HOẠT\nĐỘNG',
        expiryDate: '15 Tháng 12, 2024',
        nextPaymentAmount: '1.200.000đ',
        daysRemainingLabel: 'Còn lại 124 ngày',
        progress: 0.63,
      ),
      benefits: const [
        PurchaseBenefit(
          icon: Icons.scanner_rounded,
          title: 'Lượt quét không giới hạn',
          description: 'Phân tích vật thể AR liên tục',
        ),
        PurchaseBenefit(
          icon: Icons.workspace_premium_rounded,
          title: 'Học cùng AI chuyên sâu',
          description: 'Lộ trình cá nhân hóa 1:1',
        ),
        PurchaseBenefit(
          icon: Icons.block_rounded,
          title: 'Trải nghiệm không quảng cáo',
          description: 'Tập trung hoàn toàn vào việc học tập',
        ),
      ],
      memberSince: PurchaseInfoMetric(
        icon: Icons.verified_user_outlined,
        label: 'THÀNH VIÊN TỪ',
        value: memberSince,
      ),
      monthlyProgress: const PurchaseProgressMetric(
        icon: Icons.bolt_rounded,
        label: 'TIẾN ĐỘ THÁNG',
        value: '84%',
        progress: 0.84,
      ),
      actions: const [
        PurchaseAccountAction(
          icon: Icons.swap_horiz_rounded,
          title: 'Thay đổi gói cước',
        ),
        PurchaseAccountAction(
          icon: Icons.receipt_long_outlined,
          title: 'Lịch sử thanh toán',
        ),
        PurchaseAccountAction(
          icon: Icons.payment_rounded,
          title: 'Phương thức thanh toán',
          subtitle: 'Google Pay **** 9210',
        ),
      ],
      cancelTitle: 'Hủy đăng ký Milingo Premium',
      cancelDescription:
          'Khi hủy, các đặc quyền của bạn vẫn sẽ duy trì cho đến hết kỳ hạn thanh toán hiện tại.',
    );
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
  const _SettingsCard({
    required this.onAccountTap,
    required this.onLanguageGoalTap,
    required this.onPurchaseTap,
  });

  final VoidCallback onAccountTap;
  final VoidCallback onLanguageGoalTap;
  final VoidCallback onPurchaseTap;

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
      child: Column(
        children: [
          _SettingsItem(
            icon: Icons.manage_accounts_outlined,
            label: 'Cài đặt tài khoản',
            onTap: onAccountTap,
          ),
          _SettingsItem(
            icon: Icons.flag_outlined,
            label: 'Mục tiêu ngôn ngữ',
            onTap: onLanguageGoalTap,
          ),
          const _SettingsItem(
            icon: Icons.palette_outlined,
            label: 'Giao diện ứng dụng',
          ),
          _SettingsItem(
            icon: Icons.receipt_long_outlined,
            label: 'Quản lý gói mua',
            onTap: onPurchaseTap,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
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
                      price: _yearly ? '79.000đ' : '99.000đ',
                      suffix: '/tháng',
                      cta: 'Chọn gói Plus',
                      onCtaTap: () => setState(
                        () => _paymentPlan = _buildPaymentPlan(
                          planId: _yearly ? 'plus_yearly' : 'plus_monthly',
                          planName: 'Milingo Plus',
                          monthlyPrice: _yearly ? 79000 : 99000,
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
                      title: _yearly ? 'Gói Pro ✪' : 'Gói Pro',
                      price: _yearly ? '111.000đ' : '139.000đ',
                      suffix: '/tháng',
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
                          planId: _yearly ? 'pro_yearly' : 'pro_monthly',
                          planName: 'Milingo Premium',
                          monthlyPrice: _yearly ? 111000 : 139000,
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
    required int monthlyPrice,
  }) {
    final months = _yearly ? 12 : 1;
    final total = monthlyPrice * months;
    final durationLabel = _yearly ? '12 Tháng' : '1 Tháng';
    final totalLabel = NumberFormat.decimalPattern('en_US').format(total);

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

class _UpgradeHero extends StatelessWidget {
  const _UpgradeHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _UpgradeMedal(),
        SizedBox(height: 20),
        Text(
          'Nâng cấp Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ProfileColors.text,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Mở khóa toàn bộ tiềm năng học tập\ncùng Milingo AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ProfileColors.text,
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UpgradeMedal extends StatelessWidget {
  const _UpgradeMedal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _ProfileColors.primary.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: _ProfileColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
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
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFFFDDD4),
        borderRadius: BorderRadius.circular(27),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: _BillingOption(
              label: 'Hàng\ntháng',
              selected: !yearly,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _BillingOption(
              label: 'Hàng\nnăm',
              selected: yearly,
              onTap: () => onChanged(true),
            ),
          ),
          Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ProfileColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'TIẾT KIỆM 20%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 4),
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
