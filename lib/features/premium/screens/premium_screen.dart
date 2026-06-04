import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlanId = premiumPlans[1].id;

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
      isStartingPayment: false,
      onClose: _close,
      onPlanSelected: (plan) => setState(() => _selectedPlanId = plan.id),
      onStartPayment: () {
        context.push(
          AppConstants.paymentMethodRoute,
          extra: _selectedPlanId,
        );
      },
      onRestorePurchases: () => context.push(AppConstants.subscriptionRoute),
      onTermsPressed: () {},
    );
  }
}
