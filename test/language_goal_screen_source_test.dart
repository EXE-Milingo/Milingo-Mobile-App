import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language goal screen is separate and attached from profile row', () {
    final profileSource =
        File('lib/features/profile/screens/profile_screen.dart')
            .readAsStringSync();
    final languageSource =
        File('lib/features/profile/screens/language_goal_screen.dart')
            .readAsStringSync();

    expect(profileSource, contains('language_goal_screen.dart'));
    expect(profileSource, contains('LanguageGoalScreen'));
    expect(profileSource, contains('_openLanguageGoal'));

    expect(languageSource, contains('class LanguageGoalScreen'));
    expect(languageSource, contains('Ngôn ngữ muốn học'));
    expect(languageSource, contains('Ngôn ngữ mục tiêu'));
    expect(languageSource, contains('Mục tiêu tuần này'));
    expect(languageSource, contains('Lưu thay đổi'));
    expect(languageSource, contains('assets/images/uk.png'));
    expect(languageSource, contains('assets/images/france.png'));
    expect(languageSource, contains('assets/images/jp.png'));
    expect(languageSource, contains('assets/svg/language-speaker.svg'));
    expect(languageSource, contains('assets/svg/language-scan.svg'));
    expect(languageSource, contains('assets/svg/language-check.svg'));
  });

  test('language goal screen uses onboarding languages and saves target', () {
    final languageSource =
        File('lib/features/profile/screens/language_goal_screen.dart')
            .readAsStringSync();

    expect(languageSource, contains('supportedLanguagesProvider'));
    expect(languageSource, contains('languageFlagAssetForCode'));
    expect(languageSource, contains('Future<void> _changeLanguage'));
    expect(languageSource, contains('onChanged: _changeLanguage'));
    expect(languageSource, contains('updateLanguages(targetLanguage: code)'));
    expect(languageSource,
        contains('updateLanguages(targetLanguage: _selectedCode)'));
  });
}
