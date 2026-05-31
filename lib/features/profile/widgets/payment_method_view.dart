import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

class PaymentPlanSummary {
  const PaymentPlanSummary({
    required this.planLabel,
    required this.totalLabel,
    required this.buttonTotalLabel,
  });

  final String planLabel;
  final String totalLabel;
  final String buttonTotalLabel;
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
  final String? subtitle;
  final IconData icon;
}

class PaymentMethodView extends StatefulWidget {
  const PaymentMethodView({
    required this.plan,
    required this.methods,
    required this.onClose,
    this.onChangePlan,
    this.initialMethodId,
    super.key,
  });

  final PaymentPlanSummary plan;
  final List<PaymentMethodOption> methods;
  final VoidCallback onClose;
  final VoidCallback? onChangePlan;
  final String? initialMethodId;

  @override
  State<PaymentMethodView> createState() => _PaymentMethodViewState();
}

class _PaymentMethodViewState extends State<PaymentMethodView> {
  late String? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    _selectedMethodId =
        widget.initialMethodId ?? widget.methods.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height,
      color: const Color(0xFFFFF9F6),
      child: SafeArea(
        child: Column(
          children: [
            _PaymentHeader(onClose: widget.onClose),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 42, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phương thức thanh toán',
                      style: TextStyle(
                        color: _PaymentColors.text,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Lựa chọn phương thức thanh toán an toàn và bảo mật.',
                      style: TextStyle(
                        color: _PaymentColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SelectedPlanCard(
                      plan: widget.plan,
                      onChangePlan: widget.onChangePlan,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'TÙY CHỌN THANH TOÁN',
                      style: TextStyle(
                        color: _PaymentColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final method in widget.methods) ...[
                      _PaymentMethodTile(
                        method: method,
                        selected: method.id == _selectedMethodId,
                        onTap: () {
                          setState(() => _selectedMethodId = method.id);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: _PaymentColors.primaryDark,
                        padding: EdgeInsets.zero,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Thêm phương thức mới'),
                    ),
                    const SizedBox(height: 42),
                    const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: _PaymentColors.mutedText,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Thanh toán được mã hóa 256-bit an toàn tuyệt đối',
                            style: TextStyle(
                              color: _PaymentColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _selectedMethodId == null ? null : () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _PaymentColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _PaymentColors.primary.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 9,
                    shadowColor:
                        _PaymentColors.primary.withValues(alpha: 0.28),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        widget.plan.buttonTotalLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
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

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          color: _PaymentColors.primary,
          iconSize: 24,
        ),
      ),
    );
  }
}

class _SelectedPlanCard extends StatelessWidget {
  const _SelectedPlanCard({
    required this.plan,
    required this.onChangePlan,
  });

  final PaymentPlanSummary plan;
  final VoidCallback? onChangePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F7C3B24),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
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
                        color: _PaymentColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      plan.planLabel,
                      style: const TextStyle(
                        color: _PaymentColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              if (onChangePlan != null)
                TextButton(
                  onPressed: onChangePlan,
                  style: TextButton.styleFrom(
                    foregroundColor: _PaymentColors.primaryDark,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(52, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: const Text('Thay đổi'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF5ECE8), height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: TextStyle(
                    color: _PaymentColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                plan.totalLabel,
                style: const TextStyle(
                  color: _PaymentColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _PaymentColors.primaryDark : const Color(0xFFECE1DC),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F1EF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                method.icon,
                color: const Color(0xFF6D6460),
                size: 18,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (method.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      method.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PaymentColors.mutedText,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _PaymentColors.primaryDark : Colors.white,
                border: Border.all(
                  color: selected
                      ? _PaymentColors.primaryDark
                      : const Color(0xFFD8CECA),
                  width: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentColors {
  static const primary = AppTheme.primaryColor;
  static const primaryDark = Color(0xFFC83A12);
  static const text = Color(0xFF241C19);
  static const mutedText = Color(0xFF9A7F77);
}
