import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium start routes to payment method before PayOS checkout', () {
    final premiumSource =
        File('lib/features/premium/screens/premium_screen.dart')
            .readAsStringSync();
    final paymentScreenSource =
        File('lib/features/premium/screens/payment_method_screen.dart')
            .readAsStringSync();
    final paymentViewSource =
        File('lib/features/premium/widgets/payment_method_view.dart')
            .readAsStringSync();

    expect(premiumSource, contains('AppConstants.paymentMethodRoute'));
    expect(premiumSource, isNot(contains('createPayOSOrder')));
    expect(paymentScreenSource, contains('createPayOSOrder'));
    expect(paymentScreenSource, contains('launchUrl'));
    expect(paymentViewSource, contains('Phương thức thanh toán'));
    expect(paymentViewSource, contains('Xác nhận thanh toán'));
    expect(paymentViewSource, contains('QR Ngân hàng'));
  });
}
