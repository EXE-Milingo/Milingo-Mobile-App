import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';

const _subBg = Color(0xFFFFF7F3);
const _subSurface = Colors.white;
const _subInk = Color(0xFF211A16);
const _subMuted = Color(0xFF7B6D66);
const _subLine = Color(0xFFF0DFD8);
const _subOrange = AppTheme.primaryColor;
const _subSoftOrange = Color(0xFFFFECE6);

class SubscriptionManagementScreen extends ConsumerStatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  ConsumerState<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends ConsumerState<SubscriptionManagementScreen> {
  SubscriptionOverviewResponse? _overview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubscription());
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final overview =
          await ref.read(milingoApiServiceProvider).getSubscriptionOverview();
      if (!mounted) return;
      setState(() => _overview = overview);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is MilingoApiException
            ? e.message
            : 'Chưa thể tải trạng thái gói đăng kí.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    final active = overview?.isPremium == true;
    final benefits =
        overview?.benefits ?? const <SubscriptionBenefitResponse>[];

    return Scaffold(
      backgroundColor: _subBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _subOrange,
          onRefresh: _loadSubscription,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _SubHeader(
                title: 'Quản lý gói đăng kí',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 18),
              _CurrentPlanCard(
                overview: overview,
                isLoading: _isLoading,
                error: _error,
                onRetry: _loadSubscription,
              ),
              const SizedBox(height: 22),
              const _SectionTitle('Đặc quyền Premium'),
              const SizedBox(height: 12),
              if (benefits.isEmpty)
                const _BenefitTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Chưa có dữ liệu đặc quyền',
                  subtitle: 'Backend chưa trả quyền lợi cho gói này.',
                )
              else
                for (var i = 0; i < benefits.length; i++) ...[
                  _BenefitTile(
                    icon: _benefitIcon(benefits[i].icon),
                    title: benefits[i].title,
                    subtitle: benefits[i].subtitle,
                  ),
                  if (i != benefits.length - 1) const SizedBox(height: 10),
                ],
              const SizedBox(height: 18),
              _MemberStats(overview: overview),
              const SizedBox(height: 22),
              const _SectionTitle('Quản lý tài khoản'),
              const SizedBox(height: 12),
              _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Thay đổi gói cước',
                    onTap: () => context.push(AppConstants.premiumRoute),
                  ),
                  _SettingsItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Lịch sử thanh toán',
                    onTap: () => context.push(AppConstants.paymentHistoryRoute),
                  ),
                  _SettingsItem(
                    icon: Icons.credit_card_rounded,
                    title: 'Phương thức thanh toán',
                    subtitle: _paymentMethodLabel(overview?.source),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: active ? _showCancelUnavailable : null,
                child: const Text('Hủy đăng kí Milingo Premium'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khi hủy, các đặc quyền vẫn còn hiệu lực đến cuối kỳ thanh toán.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC9A9A0),
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng hủy tự động chưa khả dụng.'),
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _subOrange,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _subInk,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.overview,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final SubscriptionOverviewResponse? overview;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isActive = overview?.isPremium == true;
    final planName = isLoading && overview == null
        ? 'Đang tải'
        : overview?.planName ?? 'Gói miễn phí';
    final statusLabel = isLoading
        ? 'Đang tải'
        : isActive
            ? 'Đang hoạt động'
            : 'Chưa kích hoạt';
    final endDate = overview?.expiresAt == null
        ? 'Chưa có'
        : DateFormat('dd/MM/yyyy').format(overview!.expiresAt!.toLocal());
    final progress = ((overview?.monthlyProgressPercent ?? 0) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final remainingDays = overview?.remainingDays;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _subSurface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _subOrange.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GÓI HIỆN TẠI',
                      style: TextStyle(
                        color: _subMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      planName,
                      style: const TextStyle(
                        color: _subInk,
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? _subSoftOrange : const Color(0xFFF7F0ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? _subOrange : _subMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _PlanMeta(
                  label: 'Ngày hết hạn',
                  value: isActive ? endDate : 'Chưa có',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _PlanMeta(
                  label: 'Thanh toán lần tới',
                  value: _formatMoney(overview?.nextPaymentAmount ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: isActive ? progress : 0,
              minHeight: 4,
              backgroundColor: const Color(0xFFF5E8E1),
              valueColor: const AlwaysStoppedAnimation<Color>(_subOrange),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              remainingDays == null
                  ? 'Chưa có ngày hết hạn'
                  : 'Còn lại $remainingDays ngày',
              style: const TextStyle(
                color: _subMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: _subOrange,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Thử lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _subOrange,
                side: const BorderSide(color: _subOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanMeta extends StatelessWidget {
  const _PlanMeta({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _subMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _subInk,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _subMuted,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _subSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _subSoftOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _subOrange, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _subInk,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _subMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberStats extends StatelessWidget {
  const _MemberStats({required this.overview});

  final SubscriptionOverviewResponse? overview;

  @override
  Widget build(BuildContext context) {
    final progress = ((overview?.monthlyProgressPercent ?? 0) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final progressText = '${overview?.monthlyProgressPercent ?? 0}%';

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.shield_outlined,
            label: 'THÀNH VIÊN TỪ',
            value: _formatMemberSince(overview?.memberSince),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.flash_on_rounded,
            label: 'TIẾN ĐỘ GÓI',
            value: progressText,
            progress: progress,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _subSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _subOrange, size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: _subMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _subInk,
              fontSize: 18,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: const Color(0xFFF5E8E1),
                valueColor: const AlwaysStoppedAnimation<Color>(_subOrange),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _subSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _SettingsRow(item: items[i]),
            if (i != items.length - 1)
              const Divider(
                height: 1,
                indent: 18,
                endIndent: 18,
                color: _subLine,
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: _subInk, size: 20),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _subInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                        color: _subMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _subMuted),
          ],
        ),
      ),
    );
  }
}

IconData _benefitIcon(String icon) {
  return switch (icon) {
    'scan' => Icons.all_inclusive_rounded,
    'ai' => Icons.psychology_rounded,
    'ads' => Icons.block_rounded,
    _ => Icons.workspace_premium_rounded,
  };
}

String _formatMoney(int amount) {
  if (amount <= 0) return 'Chưa có';
  return '${NumberFormat.decimalPattern('vi_VN').format(amount)}đ';
}

String _formatMemberSince(DateTime? date) {
  if (date == null) return 'Chưa có';
  final local = date.toLocal();
  return 'Tháng ${local.month},\n${local.year}';
}

String _paymentMethodLabel(String? source) {
  return switch (source) {
    'payos' => 'PayOS',
    'google_play' => 'Google Play',
    _ => 'PayOS hoặc Google Play',
  };
}
