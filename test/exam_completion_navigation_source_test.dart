import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exam completion can return to home', () {
    final source = File(
      'lib/features/flashcards/screens/exam_screen.dart',
    ).readAsStringSync();

    expect(source, contains('context.go(AppConstants.homeRoute)'));
    expect(source, contains('Về trang chủ'));
    expect(source, contains('PopScope'));
    expect(source, contains('_handleResultDialogPop'));
  });
}
