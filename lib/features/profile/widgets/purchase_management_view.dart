import 'package:flutter/material.dart';

class PurchaseManagementData {
  const PurchaseManagementData({
    required this.plan,
    required this.benefits,
    required this.memberSince,
    required this.monthlyProgress,
    required this.actions,
    required this.cancelTitle,
    required this.cancelDescription,
  });

  final CurrentPurchasePlan plan;
  final List<PurchaseBenefit> benefits;
  final PurchaseInfoMetric memberSince;
  final PurchaseProgressMetric monthlyProgress;
  final List<PurchaseAccountAction> actions;
  final String cancelTitle;
  final String cancelDescription;
}

class CurrentPurchasePlan {
  const CurrentPurchasePlan({
    required this.name,
    required this.statusLabel,
    required this.expiryDate,
    required this.nextPaymentAmount,
    required this.daysRemainingLabel,
    required this.progress,
  });

  final String name;
  final String statusLabel;
  final String expiryDate;
  final String nextPaymentAmount;
  final String daysRemainingLabel;
  final double progress;
}

class PurchaseBenefit {
  const PurchaseBenefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class PurchaseInfoMetric {
  const PurchaseInfoMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class PurchaseProgressMetric {
  const PurchaseProgressMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;
}

class PurchaseAccountAction {
  const PurchaseAccountAction({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
}

class PurchaseManagementView extends StatelessWidget {
  const PurchaseManagementView({
    required this.data,
    super.key,
  });

  final PurchaseManagementData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PurchaseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CurrentPlanCard(plan: data.plan),
              const SizedBox(height: 32),
              const _SectionLabel('ĐẶC QUYỀN PREMIUM'),
              const SizedBox(height: 12),
              for (final benefit in data.benefits) ...[
                _BenefitTile(benefit: benefit),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _InfoMetricCard(metric: data.memberSince)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProgressMetricCard(metric: data.monthlyProgress),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _SectionLabel('QUẢN LÝ TÀI KHOẢN'),
              const SizedBox(height: 12),
              _AccountActionsCard(actions: data.actions),
              const SizedBox(height: 38),
              Center(
                child: Column(
                  children: [
                    Text(
                      data.cancelTitle,
                      style: const TextStyle(
                        color: _PurchaseColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 190,
                      child: Text(
                        data.cancelDescription,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _PurchaseColors.softText,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.plan});

  final CurrentPurchasePlan plan;

  @override
  Widget build(BuildContext context) {
    final progress = plan.progress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AE8673F),
            blurRadius: 28,
            offset: Offset(0, 14),
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
                        color: _PurchaseColors.text,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PurchaseColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.04,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: _PurchaseColors.primarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  plan.statusLabel,
                  style: const TextStyle(
                    color: _PurchaseColors.primary,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _PlanDetail(
                  label: 'Ngày hết hạn',
                  value: plan.expiryDate,
                ),
              ),
              Expanded(
                child: _PlanDetail(
                  label: 'Thanh toán lần tới',
                  value: plan.nextPaymentAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: const Color(0xFFFFDED7),
              color: _PurchaseColors.primary,
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              plan.daysRemainingLabel,
              style: const TextStyle(
                color: _PurchaseColors.text,
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanDetail extends StatelessWidget {
  const _PlanDetail({
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
            color: _PurchaseColors.mutedText,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _PurchaseColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: _PurchaseColors.mutedText,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.benefit});

  final PurchaseBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _IconBubble(icon: benefit.icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PurchaseColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PurchaseColors.mutedText,
                    fontSize: 9,
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

class _InfoMetricCard extends StatelessWidget {
  const _InfoMetricCard({required this.metric});

  final PurchaseInfoMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(17, 14, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricIcon(icon: metric.icon),
          const Spacer(),
          Text(
            metric.label,
            style: const TextStyle(
              color: _PurchaseColors.mutedText,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PurchaseColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  const _ProgressMetricCard({required this.metric});

  final PurchaseProgressMetric metric;

  @override
  Widget build(BuildContext context) {
    final progress = metric.progress.clamp(0.0, 1.0);

    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(17, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricIcon(icon: metric.icon),
          const Spacer(),
          Text(
            metric.label,
            style: const TextStyle(
              color: _PurchaseColors.mutedText,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            metric.value,
            style: const TextStyle(
              color: _PurchaseColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: const Color(0xFFFFDED7),
              color: _PurchaseColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountActionsCard extends StatelessWidget {
  const _AccountActionsCard({required this.actions});

  final List<PurchaseAccountAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (var index = 0; index < actions.length; index++) ...[
            _AccountActionRow(action: actions[index]),
            if (index != actions.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 45,
                endIndent: 15,
                color: Color(0xFFF3E7E3),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({required this.action});

  final PurchaseAccountAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap ?? () {},
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 42,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(action.icon, color: _PurchaseColors.text, size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PurchaseColors.text,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (action.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        action.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PurchaseColors.mutedText,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _PurchaseColors.softText,
                size: 18,
              ),
              const SizedBox(width: 13),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0EC),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _PurchaseColors.primary, size: 16),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: _PurchaseColors.primary, size: 15);
  }
}

class _PurchaseColors {
  static const background = Color(0xFFFFF7F4);
  static const primary = Color(0xFFFF4F2E);
  static const primarySoft = Color(0xFFFFE4DE);
  static const text = Color(0xFF2A1D19);
  static const mutedText = Color(0xFF8A6D65);
  static const softText = Color(0xFFE4A99C);
}
