import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/core/network/milingo_models.dart';

void main() {
  test('parses native PayOS order details returned by backend', () {
    final order = CreatePayOSOrderResponse.fromJson({
      'bin': '970422',
      'accountNumber': '113366668888',
      'accountName': 'MERCHANT NAME',
      'amount': 139000,
      'description': 'Milingo pro',
      'checkoutUrl': 'https://pay.payos.vn/web/payment-link-id',
      'orderCode': 123456789012,
      'paymentLinkId': 'payment-link-id',
      'qrCode': '00020101021238570010A000000727',
      'status': 'PENDING',
      'expiresAt': '2026-07-15T10:30:00Z',
    });

    expect(order.bin, '970422');
    expect(order.accountNumber, '113366668888');
    expect(order.accountName, 'MERCHANT NAME');
    expect(order.amount, 139000);
    expect(order.description, 'Milingo pro');
    expect(order.checkoutUrl, contains('payment-link-id'));
    expect(order.orderCode, 123456789012);
    expect(order.paymentLinkId, 'payment-link-id');
    expect(order.qrCode, startsWith('000201'));
    expect(order.status, 'PENDING');
    expect(order.expiresAt, DateTime.utc(2026, 7, 15, 10, 30));
    expect(order.isPaid, isFalse);
    expect(order.isTerminal, isFalse);
  });

  test('parses terminal PayOS verification status', () {
    final status = PayOSOrderStatusResponse.fromJson({
      'orderCode': 123456789012,
      'status': 'PAID',
      'isPaid': true,
      'expiresAt': '2026-07-15T10:30:00Z',
    });

    expect(status.orderCode, 123456789012);
    expect(status.status, 'PAID');
    expect(status.isPaid, isTrue);
    expect(status.isTerminal, isTrue);
    expect(status.expiresAt, DateTime.utc(2026, 7, 15, 10, 30));
  });

  test('cancelled and expired PayOS statuses are terminal', () {
    for (final value in ['CANCELLED', 'EXPIRED']) {
      final status = PayOSOrderStatusResponse.fromJson({
        'orderCode': 1,
        'status': value,
        'isPaid': false,
      });

      expect(status.isTerminal, isTrue, reason: value);
    }
  });
}
