import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/features/premium/widgets/payment_method_view.dart';

void main() {
  testWidgets('checkout explains additive renewal', (tester) async {
    const notice =
        'Thời gian còn lại được giữ nguyên. Giao dịch cộng thêm 30 ngày.';

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentMethodView(
          plan: const PaymentMethodPlanSummary(
            planLabel: 'Milingo Premium - 30 ngày',
            totalLabel: '139.000đ',
          ),
          renewalNotice: notice,
          isConfirming: false,
          initialMethodId: 'bank_qr',
          onClose: () {},
          onChangePlan: () {},
          onConfirmPayment: (_) {},
        ),
      ),
    );

    expect(find.text(notice), findsOneWidget);
  });
}
