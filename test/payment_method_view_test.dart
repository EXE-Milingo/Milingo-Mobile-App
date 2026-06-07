import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/profile/widgets/payment_method_view.dart';

void main() {
  testWidgets('confirms selected bank QR payment method', (tester) async {
    PaymentMethodOption? confirmedMethod;
    PaymentPlanSummary? confirmedPlan;

    const plan = PaymentPlanSummary(
      planId: 'pro_monthly',
      planLabel: 'Milingo Premium - 1 Thang',
      totalLabel: '139,000 d',
      buttonTotalLabel: '139,000 d',
    );

    const methods = [
      PaymentMethodOption(
        id: 'card',
        title: 'Card',
        icon: Icons.credit_card_rounded,
      ),
      PaymentMethodOption(
        id: 'bank_qr',
        title: 'QR Bank',
        icon: Icons.qr_code_2_rounded,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaymentMethodView(
            plan: plan,
            methods: methods,
            initialMethodId: 'card',
            onClose: () {},
            onConfirmPayment: (method, plan) async {
              confirmedMethod = method;
              confirmedPlan = plan;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('QR Bank'));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(confirmedMethod?.id, 'bank_qr');
    expect(confirmedPlan?.planId, 'pro_monthly');
  });
}
