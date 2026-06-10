import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:milingo/core/network/milingo_models.dart';

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.priceText,
    required this.unit,
    required this.features,
    this.badge,
    this.showStar = false,
    this.accentColor = _PremiumColors.orange,
  });

  factory PremiumPlan.fromApi(SubscriptionPlanResponse plan) {
    final formattedPrice = NumberFormat.decimalPattern('en_US')
        .format(plan.amount)
        .replaceAll(',', '.');
    final unit = switch (plan.durationDays) {
      7 => '/ Tuần',
      30 => '/ tháng',
      365 => '/ Năm',
      _ => '/ ${plan.durationDays} ngày',
    };

    return PremiumPlan(
      id: plan.planId,
      name: plan.planName,
      priceText: '$formattedPriceđ',
      unit: unit,
      features: _premiumFeatures,
      badge: switch (plan.planId) {
        'pro' => 'PHỔ BIẾN NHẤT',
        'ultra' => 'PHỔ BIẾN',
        _ => null,
      },
      showStar: plan.planId == 'ultra',
      accentColor: plan.planId == 'ultra'
          ? _PremiumColors.lightOrange
          : _PremiumColors.orange,
    );
  }

  final String id;
  final String name;
  final String priceText;
  final String unit;
  final List<String> features;
  final String? badge;
  final bool showStar;
  final Color accentColor;
}

const premiumPlans = [
  PremiumPlan(
    id: 'plus',
    name: 'Gói Plus',
    priceText: '59.000đ',
    unit: '/ Tuần',
    features: _premiumFeatures,
  ),
  PremiumPlan(
    id: 'pro',
    name: 'Gói Pro',
    priceText: '139.000đ',
    unit: '/ tháng',
    badge: 'PHỔ BIẾN NHẤT',
    features: _premiumFeatures,
  ),
  PremiumPlan(
    id: 'ultra',
    name: 'Gói Ultra',
    priceText: '510.000đ',
    unit: '/ Năm',
    badge: 'PHỔ BIẾN',
    showStar: true,
    accentColor: _PremiumColors.lightOrange,
    features: _premiumFeatures,
  ),
];

const _premiumFeatures = [
  'Quét không giới hạn',
  'Trò chuyện cùng AI',
  'Tính năng ôn tập đa dạng',
  'Không quảng cáo',
  'Hỗ trợ đa ngôn ngữ',
  'Luyện phát âm cùng AI',
];

class PremiumUpgradeView extends StatelessWidget {
  const PremiumUpgradeView({
    required this.plans,
    required this.selectedPlanId,
    required this.isStartingPayment,
    required this.onClose,
    required this.onPlanSelected,
    required this.onStartPayment,
    required this.onRestorePurchases,
    required this.onTermsPressed,
    super.key,
  });

  final List<PremiumPlan> plans;
  final String selectedPlanId;
  final bool isStartingPayment;
  final VoidCallback onClose;
  final ValueChanged<PremiumPlan> onPlanSelected;
  final VoidCallback onStartPayment;
  final VoidCallback onRestorePurchases;
  final VoidCallback onTermsPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PremiumColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PremiumTopBar(onClose: onClose),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.paddingOf(context).bottom + 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PremiumHero(),
                      const SizedBox(height: 40),
                      _PremiumPlanList(
                        plans: plans,
                        selectedPlanId: selectedPlanId,
                        onPlanSelected: onPlanSelected,
                      ),
                      const SizedBox(height: 48),
                      _PremiumActionArea(
                        isStartingPayment: isStartingPayment,
                        onStartPayment: onStartPayment,
                        onRestorePurchases: onRestorePurchases,
                        onTermsPressed: onTermsPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumColors {
  static const background = Color(0xFFFDF8F6);
  static const text = Color(0xFF1C1B1B);
  static const muted = Color(0xFF765753);
  static const soft = Color(0xFFFFF1EC);
  static const orange = Color(0xFFFF4B00);
  static const lightOrange = Color(0xFFFF7E48);
  static const subtleBorder = Color(0x26E5BEB2);
  static const footerLink = Color(0xFFA33D19);
}

class _PremiumTopBar extends StatelessWidget {
  const _PremiumTopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: _PremiumColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _HeaderIconButton(onPressed: onClose),
          const Expanded(
            child: Text(
              'Nâng cấp Premium',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _PremiumColors.text,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.close_rounded,
            color: _PremiumColors.muted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PremiumGlyph(),
        SizedBox(height: 24),
        Text(
          'Nâng cấp Premium',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            height: 40 / 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Mở khóa toàn bộ tiềm năng học tập\ncùng Milingo AI.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
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
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _PremiumColors.soft,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _PremiumColors.orange.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/svg/premium-icon.svg',
        width: 24,
        height: 32,
        colorFilter: const ColorFilter.mode(
          _PremiumColors.orange,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class _PremiumPlanList extends StatelessWidget {
  const _PremiumPlanList({
    required this.plans,
    required this.selectedPlanId,
    required this.onPlanSelected,
  });

  final List<PremiumPlan> plans;
  final String selectedPlanId;
  final ValueChanged<PremiumPlan> onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final plan in plans) ...[
          _PremiumPlanCard(
            plan: plan,
            selected: plan.id == selectedPlanId,
            onTap: () => onPlanSelected(plan),
          ),
          if (plan != plans.last) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _PremiumPlanCard extends StatelessWidget {
  const _PremiumPlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? _PremiumColors.orange : plan.accentColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _PremiumColors.orange
                  : _PremiumColors.subtleBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFAC2D03).withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PlanHeading(plan: plan, accent: accent),
                  const SizedBox(height: 8),
                  _PlanPrice(plan: plan),
                  const SizedBox(height: 24),
                  _FeatureList(features: plan.features, accent: accent),
                ],
              ),
              if (plan.badge != null)
                Positioned(
                  right: -24,
                  top: -28,
                  child: _PlanBadge(text: plan.badge!, color: accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanHeading extends StatelessWidget {
  const _PlanHeading({required this.plan, required this.accent});

  final PremiumPlan plan;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            plan.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: plan.badge == null ? Colors.black : accent,
              fontSize: 20,
              height: 28 / 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        if (plan.showStar) ...[
          const SizedBox(width: 4),
          Icon(Icons.stars_rounded, color: accent, size: 15),
        ],
      ],
    );
  }
}

class _PlanPrice extends StatelessWidget {
  const _PlanPrice({required this.plan});

  final PremiumPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              plan.priceText,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 30,
                height: 36 / 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          plan.unit,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList({required this.features, required this.accent});

  final List<String> features;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final feature in features) ...[
          _FeatureLine(text: feature, accent: accent),
          if (feature != features.last) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, color: accent, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PremiumActionArea extends StatelessWidget {
  const _PremiumActionArea({
    required this.isStartingPayment,
    required this.onStartPayment,
    required this.onRestorePurchases,
    required this.onTermsPressed,
  });

  final bool isStartingPayment;
  final VoidCallback onStartPayment;
  final VoidCallback onRestorePurchases;
  final VoidCallback onTermsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 68,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF9C31), Color(0xFFF46036)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A2F2C).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: isStartingPayment ? null : onStartPayment,
              iconAlignment: IconAlignment.end,
              icon: isStartingPayment
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(isStartingPayment ? 'Đang mở PayOS' : 'Bắt đầu ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: _PremiumColors.background,
                disabledForegroundColor:
                    _PremiumColors.background.withValues(alpha: 0.72),
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  height: 28 / 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: [
            _FooterTextButton(
              text: 'Khôi phục gói mua',
              onPressed: onRestorePurchases,
            ),
            _FooterTextButton(
              text: 'Điều khoản dịch vụ',
              onPressed: onTermsPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterTextButton extends StatelessWidget {
  const _FooterTextButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _PremiumColors.footerLink,
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      child: Text(text),
    );
  }
}
