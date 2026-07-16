import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/premium/widgets/premium_upgrade_view.dart';

void main() {
  testWidgets('latest package remains selectable and renews', (tester) async {
    PremiumPlan? selected;
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PremiumUpgradeView(
          plans: premiumPlans,
          selectedPlanId: 'pro',
          latestPurchasedPlanId: 'pro',
          actionLabel: 'Gia hạn thêm 30 ngày',
          isStartingPayment: false,
          onClose: () {},
          onPlanSelected: (plan) => selected = plan,
          onStartPayment: () => started = true,
          onRestorePurchases: () {},
          onTermsPressed: () {},
        ),
      ),
    );

    expect(find.text('GÓI MUA GẦN NHẤT'), findsOneWidget);
    expect(find.text('Gia hạn thêm 30 ngày'), findsOneWidget);

    await tester.ensureVisible(find.text('Gói Pro').first);
    await tester.tap(find.text('Gói Pro').first);
    await tester.pump();
    expect(selected?.id, 'pro');

    await tester.ensureVisible(find.text('Gia hạn thêm 30 ngày'));
    await tester.tap(find.text('Gia hạn thêm 30 ngày'));
    expect(started, isTrue);
  });
}
