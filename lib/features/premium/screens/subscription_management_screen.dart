import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_models.dart';
import 'package:milingo/features/premium/providers/subscription_provider.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(subscriptionOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F6),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _GlowBackground(),
            overviewAsync.when(
              data: (overview) => _buildContent(context, ref, overview),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
              ),
              error: (err, stack) => _buildError(context, ref, err),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    SubscriptionOverviewResponse overview,
  ) {
    return RefreshIndicator(
      color: const Color(0xFFFF6A00),
      onRefresh: () => ref.refresh(subscriptionOverviewProvider.future),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildCurrentPlanCard(overview),
            const SizedBox(height: 32),
            const _SectionTitle(text: 'Đặc quyền Premium'),
            const SizedBox(height: 12),
            _buildBenefitsGrid(),
            const SizedBox(height: 32),
            const _SectionTitle(text: 'Quản lý tài khoản'),
            const SizedBox(height: 12),
            _buildManagementList(context, overview),
            const SizedBox(height: 40),
            _buildFooterActions(context, overview),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => context.pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: ProfileSvgIcon(
                    'assets/svg/new-profile/account-back.svg',
                    size: 22,
                    color: Color(0xFF1D1814),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Quản lý gói đăng kí',
            style: TextStyle(
              color: Color(0xFF1D1814),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanCard(SubscriptionOverviewResponse overview) {
    final active = overview.isPremium;
    final planName = overview.planName;
    final endDate = overview.expiresAt == null
        ? 'Vô thời hạn'
        : DateFormat('dd/MM/yyyy').format(overview.expiresAt!.toLocal());
    final progress =
        ((overview.monthlyProgressPercent) / 100).clamp(0.0, 1.0).toDouble();
    final remainingDays = overview.remainingDays;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1C1B1B).withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overview.source == 'payos'
                    ? 'Gói mua gần nhất'.toUpperCase()
                    : 'GÓI HIỆN TẠI',
                style: const TextStyle(
                  color: Color(0xFF9A8E84),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                planName,
                style: const TextStyle(
                  color: Color(0xFF1D1814),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 1,
                color: const Color(0xFFF0DFD8),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ngày hết hạn',
                          style: TextStyle(
                            color: Color(0xFF9A8E84),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active ? endDate : 'Chưa có',
                          style: const TextStyle(
                            color: Color(0xFF1D1814),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overview.source == 'payos'
                              ? 'Gói mua gần nhất'
                              : 'Thanh toán lần tới',
                          style: const TextStyle(
                            color: Color(0xFF9A8E84),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active
                              ? _formatMoney(
                                  overview.source == 'payos'
                                      ? overview.lastPaymentAmount
                                      : overview.nextPaymentAmount,
                                )
                              : 'Chưa có',
                          style: const TextStyle(
                            color: Color(0xFF1D1814),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF5E8E1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    remainingDays == null
                        ? 'Chưa có thông tin hết hạn'
                        : 'Còn lại $remainingDays ngày',
                    style: const TextStyle(
                      color: Color(0xFF9A8E84),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsGrid() {
    final list = [
      _BenefitItem(
        svgPath: 'assets/svg/camera-homescreen.svg',
        title: 'Lượt quét không giới hạn',
      ),
      _BenefitItem(
        svgPath: 'assets/svg/new-ai-tutor.svg',
        title: 'Trò chuyện cùng AI không giới hạn',
      ),
      _BenefitItem(
        svgPath: 'assets/svg/streak.svg',
        title: 'Trải nghiệm không quảng cáo',
      ),
    ];

    return Column(
      children: list.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF1ED),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item.svgPath,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFFF4B00),
                      BlendMode.srcIn,
                    ),
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManagementList(
    BuildContext context,
    SubscriptionOverviewResponse overview,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildManagementRow(
            icon: Icons.swap_horiz_rounded,
            title: 'Thay đổi gói cước',
            onTap: () => context.push(AppConstants.premiumRoute),
          ),
          const Divider(
              height: 1, color: Color(0xFFF0DFD8), indent: 20, endIndent: 20),
          _buildManagementRow(
            icon: Icons.receipt_long_rounded,
            title: 'Lịch sử thanh toán',
            onTap: () => context.push(AppConstants.paymentHistoryRoute),
          ),
          const Divider(
              height: 1, color: Color(0xFFF0DFD8), indent: 20, endIndent: 20),
          _buildManagementRow(
            icon: Icons.credit_card_rounded,
            title: 'Phương thức thanh toán',
            subtitle: _paymentMethodLabel(overview.source),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildManagementRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1D1814), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1D1814),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF9A8E84),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB8A8A0),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(
    BuildContext context,
    SubscriptionOverviewResponse overview,
  ) {
    if (overview.isPremium && overview.source == 'payos') {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'PayOS là giao dịch một lần và không tự động gia hạn. '
          'Bạn có thể mua thêm thời gian bất cứ lúc nào.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9A8E84),
            fontSize: 11,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (overview.isPremium) {
      return Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng hủy tự động chưa khả dụng.'),
                  ),
                );
              },
              child: const Text(
                'Hủy đăng ký Milingo Premium',
                style: TextStyle(
                  color: Color(0xFFAC2D03),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Khi hủy, các đặc quyền của bạn vẫn sẽ duy trì cho đến hết kỳ hạn thanh toán hiện tại.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF9A8E84),
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4D1A).withValues(alpha: 0.24),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(AppConstants.premiumRoute),
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Text(
                  'Nâng cấp Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Mở khóa tất cả các tính năng cao cấp ngay hôm nay.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF9A8E84),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF4D1A),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa thể tải trạng thái gói đăng kí.',
              style: TextStyle(
                color: Color(0xFF1D1814),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9A8E84),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(subscriptionOverviewProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9A8E84),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _BenefitItem {
  _BenefitItem({
    required this.svgPath,
    required this.title,
  });

  final String svgPath;
  final String title;
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -64,
          right: -80,
          child: _Glow(size: 288, color: Color(0x2EFF8A1F)),
        ),
        Positioned(
          top: 320,
          left: -96,
          child: _Glow(size: 256, color: Color(0x1AFF4D1A)),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

String _formatMoney(int amount) {
  if (amount <= 0) return 'Chưa có';
  return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
}

String _paymentMethodLabel(String? source) {
  return switch (source) {
    'payos' => 'PayOS',
    'google_play' => 'Google Play',
    _ => 'PayOS hoặc Google Play',
  };
}
