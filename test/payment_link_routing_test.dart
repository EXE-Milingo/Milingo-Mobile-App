import 'package:flutter_test/flutter_test.dart';
import 'package:milingo/main.dart';

void main() {
  test('preserves PayOS orderCode on custom-scheme success link', () {
    final route = paymentRouteFor(
      Uri.parse('milingo://payment/payment/success?orderCode=123456789012'),
    );

    expect(route, '/payment/success?orderCode=123456789012');
  });

  test('preserves PayOS orderCode on web return link', () {
    final route = paymentRouteFor(
      Uri.parse(
        'https://milingo.vn/payment/cancel?orderCode=123456789012',
      ),
    );

    expect(route, '/payment/cancel?orderCode=123456789012');
  });

  test('rejects unrelated links', () {
    expect(paymentRouteFor(Uri.parse('https://example.com/payment/success')),
        isNull);
  });
}
