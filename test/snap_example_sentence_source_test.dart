import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('example sentence speaker reads only the target sentence row', () {
    final source = File(
      'lib/features/snap_and_learn/screens/snap_and_learn_screen.dart',
    ).readAsStringSync();

    expect(source, contains('final speakText = example.original;'));
  });
}
