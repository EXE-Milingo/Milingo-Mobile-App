import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    required this.billText,
    required this.features,
    required this.icon,
    this.badge,
  });

  final String id;
  final String name;
  final int price;
  final String unit;
  final String billText;
  final List<String> features;
  final IconData icon;
  final String? badge;
}

const _bg = Color(0xFFFFF7F3);
const _surface = Colors.white;
const _ink = Color(0xFF201A17);
const _muted = Color(0xFF746760);
const _line = Color(0xFFF0DFD8);
const _orange = AppTheme.primaryColor;
const _softOrange = Color(0xFFFFE1D8);
const _buttonOrange = Color(0xFFFF8A1F);

const _plans = [
  PremiumPlan(
    id: 'plus_monthly',
    name: 'Gói Plus',
    price: 99000,
    unit: '/ tháng',
    billText: 'Thanh toán 99.000đ/tháng',
    icon: Icons.workspace_premium_rounded,
    features: [
      'Quét 100 vật thể mỗi ngày',
      'Trò chuyện cùng AI',
      'Tính năng ôn tập đa dạng',
      'Không quảng cáo',
      'Hỗ trợ đa ngôn ngữ',
    ],
  ),
  PremiumPlan(
    id: 'pro_monthly',
    name: 'Gói Pro',
    price: 139000,
    unit: '/ tháng',
    billText: 'Thanh toán 139.000đ/tháng',
    badge: 'Phổ biến nhất',
    icon: Icons.auto_awesome_rounded,
    features: [
      'Quét không giới hạn',
      'Trò chuyện cùng AI',
      'Tính năng ôn tập đa dạng',
      'Không quảng cáo',
      'Hỗ trợ đa ngôn ngữ',
    ],
  ),
  PremiumPlan(
    id: 'pro_yearly',
    name: 'Gói Pro',
    price: 1332000,
    unit: '/ năm',
    billText: 'Thanh toán 1.332.000đ/năm',
    badge: 'Phổ biến',
    icon: Icons.bolt_rounded,
    features: [
      'Quét không giới hạn',
      'Trò chuyện cùng AI',
      'Tính năng ôn tập đa dạng',
      'Không quảng cáo',
      'Hỗ trợ đa ngôn ngữ',
    ],
  ),
];

final _vndFormatter = NumberFormat.decimalPattern('vi_VN');

String _vnd(int amount) => '${_vndFormatter.format(amount)}đ';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String _selectedPlanId = 'pro_monthly';
  bool _isStartingPayment = false;

  PremiumPlan get _selectedPlan {
    return _plans.firstWhere((plan) => plan.id == _selectedPlanId);
  }

  Future<void> _startPayment() async {
    final plan = _selectedPlan;
    setState(() => _isStartingPayment = true);

    try {
      final order = await ref.read(milingoApiServiceProvider).createPayOSOrder(
            planId: plan.id,
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
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_errorMessage(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isStartingPayment = false);
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is MilingoApiException) return error.message;
    return 'Không thể tạo thanh toán. Vui lòng thử lại.';
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  void _close() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(AppConstants.profileRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PremiumTopBar(onClose: _close),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                children: [
                  const _PremiumIntro(),
                  const SizedBox(height: 22),
                  ..._plans.map(
                    (plan) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PlanCard(
                        plan: plan,
                        selected: plan.id == _selectedPlanId,
                        onTap: () => setState(() => _selectedPlanId = plan.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _CheckoutBar(
              plan: _selectedPlan,
              isLoading: _isStartingPayment,
              bottomPadding: bottomPadding,
              onPressed: _startPayment,
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumTopBar extends StatelessWidget {
  const _PremiumTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            child: IconButton(
              tooltip: 'Đóng',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: _muted,
            ),
          ),
          const Text(
            'Nâng cấp Premium',
            style: TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumIntro extends StatelessWidget {
  const _PremiumIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 10),
        _PremiumGlyph(),
        SizedBox(height: 22),
        Text(
          'Nâng cấp Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: 28,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Mở khóa toàn bộ tiềm năng học tập\ncùng Milingo AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PremiumGlyph extends StatelessWidget {
  const _PremiumGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium_rounded,
        color: _orange,
        size: 20,
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _orange : _line,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanIcon(icon: plan.icon),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                plan.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected ? _orange : _ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: _orange,
                                size: 15,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          plan.billText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan.badge != null)
                    _Badge(
                      text: plan.badge!,
                      highlighted: selected,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _PriceLine(plan: plan),
              const SizedBox(height: 18),
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FeatureLine(text: feature),
                ),
              ),
              if (!selected) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: _softOrange,
                      foregroundColor: _ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: Text('Chọn ${plan.name}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanIcon extends StatelessWidget {
  const _PlanIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _softOrange,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: _orange, size: 20),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.highlighted,
  });

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted ? _orange : const Color(0xFFFFF0EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: highlighted ? Colors.white : _orange,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.plan});

  final PremiumPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _vnd(plan.price),
              maxLines: 1,
              style: const TextStyle(
                color: _ink,
                fontSize: 27,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            plan.unit,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: _orange, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _ink,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.plan,
    required this.isLoading,
    required this.bottomPadding,
    required this.onPressed,
  });

  final PremiumPlan plan;
  final bool isLoading;
  final double bottomPadding;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _bg,
        boxShadow: [
          BoxShadow(
            color: _bg.withValues(alpha: 0.95),
            blurRadius: 18,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, bottomPadding + 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onPressed,
                icon: isLoading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(isLoading ? 'Đang mở PayOS' : 'Bắt đầu ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonOrange,
                  disabledBackgroundColor: _buttonOrange.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Khôi phục gói mua',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  'Điều khoản dịch vụ',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
