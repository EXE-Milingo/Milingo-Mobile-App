import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/premium/widgets/payment_method_view.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({
    this.selectedPlanId,
    super.key,
  });

  final String? selectedPlanId;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  bool _isConfirming = false;

  PremiumPlan get _selectedPlan {
    return premiumPlans.firstWhere(
      (plan) => plan.id == widget.selectedPlanId,
      orElse: () => premiumPlans[1],
    );
  }

  Future<void> _confirmPayment(String methodId) async {
    setState(() => _isConfirming = true);

    try {
      final order = await ref.read(milingoApiServiceProvider).createPayOSOrder(
            planId: _selectedPlan.id,
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
      _showSnackBar(_errorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
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

  @override
  Widget build(BuildContext context) {
    return PaymentMethodView(
      plan: PaymentMethodPlanSummary.fromPremiumPlan(_selectedPlan),
      isConfirming: _isConfirming,
      initialMethodId: 'card',
      onClose: () => context.pop(),
      onChangePlan: () => context.pop(),
      onConfirmPayment: _confirmPayment,
    );
  }
}
