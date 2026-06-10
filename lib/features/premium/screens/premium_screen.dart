import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  List<PremiumPlan> _plans = premiumPlans;
  String _selectedPlanId = premiumPlans[1].id;

  PremiumPlan get _selectedPlan {
    return _plans.firstWhere(
      (plan) => plan.id == _selectedPlanId,
      orElse: () => _plans.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final response =
          await ref.read(milingoApiServiceProvider).getSubscriptionPlans();
      final plans = response.map(PremiumPlan.fromApi).toList();
      if (!mounted || plans.isEmpty) return;

      setState(() {
        _plans = plans;
        if (!_plans.any((plan) => plan.id == _selectedPlanId)) {
          _selectedPlanId = _plans.first.id;
        }
      });
    } catch (_) {
      // Keep local catalog available when backend cannot be reached.
    }
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
      plans: _plans,
      selectedPlanId: _selectedPlanId,
      isStartingPayment: false,
      onClose: _close,
      onPlanSelected: (plan) => setState(() => _selectedPlanId = plan.id),
      onStartPayment: () {
        context.push(
          AppConstants.paymentMethodRoute,
          extra: _selectedPlan,
        );
      },
      onRestorePurchases: () => context.push(AppConstants.subscriptionRoute),
      onTermsPressed: () => context.push(AppConstants.termsOfServiceRoute),
    );
  }
}
