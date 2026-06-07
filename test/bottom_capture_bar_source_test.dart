import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capture controls keep extra space above screen bottom', () {
    final source = File(
      'lib/features/snap_and_learn/widgets/bottom_capture_bar.dart',
    ).readAsStringSync();

    expect(source, contains('EdgeInsets.fromLTRB(48, 12, 48, 68)'));
  });
}
