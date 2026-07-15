import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium start uses native bank QR without external checkout', () {
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
    expect(paymentScreenSource, isNot(contains('launchUrl')));
    expect(paymentScreenSource, isNot(contains('url_launcher')));
    expect(paymentViewSource, contains('Phương thức thanh toán'));
    expect(paymentViewSource, contains('Xác nhận thanh toán'));
    expect(paymentViewSource, contains('QR Ngân hàng'));
    expect(paymentViewSource, isNot(contains('Apple Pay')));
    expect(paymentViewSource, isNot(contains('Visa/Mastercard')));
    expect(paymentViewSource, isNot(contains('Ví MoMo')));
    expect(paymentViewSource, isNot(contains('Thêm phương thức mới')));
  });
}
