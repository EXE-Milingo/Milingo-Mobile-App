import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home screen keeps existing bottom nav and Figma behavior hooks', () {
    final source = File('lib/features/home/screens/simple_home_screen.dart')
        .readAsStringSync();

    expect(source, contains('AppBottomNavBar'));
    expect(
      source,
      contains('bottomNavigationBar: const AppBottomNavBar(currentIndex: 0)'),
    );
    expect(source, contains('AppConstants.snapAndLearnRoute'));
    expect(source, contains('AppConstants.examRoute'));
    expect(source, contains('scannedWords'));
    expect(source, contains("value: 'Xu'"));
    expect(source, isNot(contains("value: 'xu")));
    expect(source, contains('assets/images/nothing.png'));
  });
}
