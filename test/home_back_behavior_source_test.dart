import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home opens snap through push so Android back returns home', () {
    final source = File('lib/features/home/screens/simple_home_screen.dart')
        .readAsStringSync();

    expect(source, contains('context.push(AppConstants.snapAndLearnRoute)'));
  });
}
