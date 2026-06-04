import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String _selectedPlanId = premiumPlans[1].id;
  bool _isStartingPayment = false;

  PremiumPlan get _selectedPlan {
    return premiumPlans.firstWhere((plan) => plan.id == _selectedPlanId);
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
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(_errorMessage(error), isError: true);
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
    return PremiumUpgradeView(
      selectedPlanId: _selectedPlanId,
      isStartingPayment: _isStartingPayment,
      onClose: _close,
      onPlanSelected: (plan) => setState(() => _selectedPlanId = plan.id),
      onStartPayment: _startPayment,
      onRestorePurchases: () => context.push(AppConstants.subscriptionRoute),
      onTermsPressed: () =>
          _showSnackBar('Điều khoản dịch vụ sẽ được cập nhật.'),
    );
  }
}
