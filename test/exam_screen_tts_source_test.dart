import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exam pronunciation uses each study card target language', () {
    final source = File(
      'lib/features/flashcards/screens/exam_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_card.targetLangCode'));
    expect(source, contains('userProfileProvider'));
    expect(source, contains('profileLangCode'));
  });
}
