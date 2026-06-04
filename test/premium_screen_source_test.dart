import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium route delegates to separated Figma upgrade view', () {
    final screenSource =
        File('lib/features/premium/screens/premium_screen.dart')
            .readAsStringSync();
    final viewSource =
        File('lib/features/premium/widgets/premium_upgrade_view.dart')
            .readAsStringSync();

    expect(screenSource, contains('PremiumUpgradeView'));
    expect(viewSource, contains('59.000đ'));
    expect(viewSource, contains('139.000đ'));
    expect(viewSource, contains('510.000đ'));
    expect(viewSource, contains('PHỔ BIẾN NHẤT'));
    expect(viewSource, contains('Bắt đầu ngay'));
    expect(viewSource, isNot(contains('Chọn gói')));
  });
}
