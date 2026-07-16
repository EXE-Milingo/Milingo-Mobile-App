import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PayOS management uses one-time purchase wording', () {
    final source = File(
      'lib/features/premium/screens/subscription_management_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Gói mua gần nhất'));
    expect(source, contains('PayOS là giao dịch một lần'));
    expect(source, contains("overview.source == 'payos'"));
  });
}
