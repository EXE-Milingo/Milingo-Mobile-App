import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/premium/widgets/payment_method_view.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({
    this.selectedPlan,
    this.selectedPlanId,
    super.key,
  });

  final PremiumPlan? selectedPlan;
  final String? selectedPlanId;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  bool _isConfirming = false;

  PremiumPlan get _selectedPlan {
    final selectedPlan = widget.selectedPlan;
    if (selectedPlan != null) return selectedPlan;
    return premiumPlans.firstWhere(
      (plan) => plan.id == widget.selectedPlanId,
      orElse: () => premiumPlans[1],
    );
  }

  Future<void> _confirmPayment(String methodId) async {
    setState(() => _isConfirming = true);
    var createNewOrder = false;

    try {
      final order = await ref.read(milingoApiServiceProvider).createPayOSOrder(
            planId: _selectedPlan.id,
          );
      if (!mounted) return;
      if (order.isPaid) {
        context.go(
          '${AppConstants.paymentSuccessRoute}?orderCode=${order.orderCode}',
        );
        return;
      }
      if (order.qrCode.isEmpty || order.accountNumber.isEmpty) {
        throw const MilingoApiException('Không nhận được mã QR thanh toán.');
      }
      createNewOrder =
          await context.push<bool>(AppConstants.paymentQrRoute, extra: order) ==
              true;
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(_errorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
    if (createNewOrder && mounted) {
      await _confirmPayment(methodId);
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

  @override
  Widget build(BuildContext context) {
    return PaymentMethodView(
      plan: PaymentMethodPlanSummary.fromPremiumPlan(_selectedPlan),
      isConfirming: _isConfirming,
      initialMethodId: 'bank_qr',
      onClose: () => context.pop(),
      onChangePlan: () => context.pop(),
      onConfirmPayment: _confirmPayment,
    );
  }
}
