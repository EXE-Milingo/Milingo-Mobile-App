import 'package:flutter/material.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';

class PaymentMethodPlanSummary {
  const PaymentMethodPlanSummary({
    required this.planLabel,
    required this.totalLabel,
  });

  factory PaymentMethodPlanSummary.fromPremiumPlan(PremiumPlan plan) {
    final duration = switch (plan.id) {
      'plus' => '1 Tuần',
      'pro' => '1 Tháng',
      'ultra' => '1 Năm',
      _ => plan.unit.replaceAll('/', '').trim(),
    };

    return PaymentMethodPlanSummary(
      planLabel: 'Milingo Premium - $duration',
      totalLabel: plan.priceText,
    );
  }

  final String planLabel;
  final String totalLabel;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String id;
  final String title;
  final IconData icon;
  final String? subtitle;
}

const _paymentMethods = [
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

class PaymentMethodView extends StatefulWidget {
  const PaymentMethodView({
    required this.plan,
    required this.isConfirming,
    required this.onClose,
    required this.onChangePlan,
    required this.onConfirmPayment,
    this.initialMethodId,
    super.key,
  });

  final PaymentMethodPlanSummary plan;
  final bool isConfirming;
  final VoidCallback onClose;
  final VoidCallback onChangePlan;
  final ValueChanged<String> onConfirmPayment;
  final String? initialMethodId;

  @override
  State<PaymentMethodView> createState() => _PaymentMethodViewState();
}

class _PaymentMethodViewState extends State<PaymentMethodView> {
  late String _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _selectedMethodId = widget.initialMethodId ?? _paymentMethods[1].id;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _PaymentColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _PaymentHeader(onClose: widget.onClose),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 56, 32, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 512),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PaymentTitle(),
                      const SizedBox(height: 32),
                      _SelectedPlanCard(
                        plan: widget.plan,
                        onChangePlan: widget.onChangePlan,
                      ),
                      const SizedBox(height: 32),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 20),
                        child: Text(
                          'TÙY CHỌN THANH TOÁN',
                          style: TextStyle(
                            color: _PaymentColors.muted,
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      for (final method in _paymentMethods) ...[
                        _PaymentMethodTile(
                          method: method,
                          selected: method.id == _selectedMethodId,
                          onTap: () {
                            setState(() => _selectedMethodId = method.id);
                          },
                        ),
                        if (method != _paymentMethods.last)
                          const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      const _AddPaymentMethodButton(),
                      const SizedBox(height: 64),
                      const _SecurityBadge(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32, 16, 32, bottomPadding + 30),
              child: _ConfirmPaymentButton(
                totalLabel: widget.plan.totalLabel,
                isConfirming: widget.isConfirming,
                onPressed: widget.isConfirming
                    ? null
                    : () => widget.onConfirmPayment(_selectedMethodId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentColors {
  static const background = Color(0xFFFDF8F6);
  static const text = Color(0xFF1C1B1B);
  static const muted = Color(0xFF765753);
  static const secondaryMuted = Color(0xFF78716C);
  static const orange = Color(0xFFE4502E);
  static const line = Color(0xFFE7E5E4);
  static const softLine = Color(0xFFF5F5F4);
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 24),
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: _PaymentColors.orange,
            iconSize: 24,
            tooltip: 'Đóng',
          ),
        ),
      ),
    );
  }
}

class _PaymentTitle extends StatelessWidget {
  const _PaymentTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phương thức thanh toán',
          style: TextStyle(
            color: _PaymentColors.text,
            fontSize: 30,
            height: 36 / 30,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Lựa chọn phương thức thanh toán an toàn và bảo mật.',
          style: TextStyle(
            color: _PaymentColors.muted,
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

class _SelectedPlanCard extends StatelessWidget {
  const _SelectedPlanCard({
    required this.plan,
    required this.onChangePlan,
  });

  final PaymentMethodPlanSummary plan;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PaymentColors.softLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -21,
            top: -21,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFAC2D03).withValues(alpha: 0.05),
                    const Color(0xFFAC2D03).withValues(alpha: 0),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(96),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GÓI ĐÃ CHỌN',
                          style: TextStyle(
                            color: _PaymentColors.orange,
                            fontSize: 10,
                            height: 15 / 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.planLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _PaymentColors.text,
                            fontSize: 18,
                            height: 28 / 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onChangePlan,
                    style: TextButton.styleFrom(
                      foregroundColor: _PaymentColors.orange,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(56, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: const Text('Thay đổi'),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: _PaymentColors.softLine),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng thanh toán',
                      style: TextStyle(
                        color: _PaymentColors.muted,
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    plan.totalLabel,
                    style: const TextStyle(
                      color: _PaymentColors.text,
                      fontSize: 20,
                      height: 28 / 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodOption method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _PaymentColors.orange : _PaymentColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _PaymentColors.softLine,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  method.icon,
                  size: 20,
                  color: const Color(0xFF57534E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PaymentColors.text,
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    if (method.subtitle != null)
                      Text(
                        method.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PaymentColors.secondaryMuted,
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                        ),
                      ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _PaymentColors.orange : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? _PaymentColors.orange
                        : const Color(0xFFD6D3D1),
                    width: 2,
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

class _AddPaymentMethodButton extends StatelessWidget {
  const _AddPaymentMethodButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Thêm phương thức mới'),
        style: TextButton.styleFrom(
          foregroundColor: _PaymentColors.orange,
          padding: const EdgeInsets.all(8),
          textStyle: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: _PaymentColors.secondaryMuted,
        ),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Thanh toán được mã hóa 256-bit an toàn tuyệt đối',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _PaymentColors.secondaryMuted,
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmPaymentButton extends StatelessWidget {
  const _ConfirmPaymentButton({
    required this.totalLabel,
    required this.isConfirming,
    required this.onPressed,
  });

  final String totalLabel;
  final bool isConfirming;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF09933), Color(0xFFF46337)],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isConfirming ? 'Đang mở PayOS' : 'Xác nhận thanh toán',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              if (isConfirming)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                Text(
                  totalLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
