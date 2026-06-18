import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bottom navigation pushes tabs so Android back returns previous page',
      () {
    final source =
        File('lib/shared/widgets/app_bottom_nav_bar.dart').readAsStringSync();

    expect(source, contains('context.go(AppConstants.homeRoute)'));
    expect(source, contains('context.go(AppConstants.flashcardsRoute)'));
    expect(source, contains('context.push(AppConstants.snapAndLearnRoute)'));
    expect(source, contains('context.go(AppConstants.profileRoute)'));
  });
}
