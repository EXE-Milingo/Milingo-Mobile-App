import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen source uses the Figma premium settings layout', () {
    final source = File('lib/features/profile/screens/profile_screen.dart')
        .readAsStringSync();

    expect(source, contains('ProfileHeaderSection'));
    expect(source, contains('ProfilePremiumCard'));
    expect(source, contains('ProfileStatsSection'));
    expect(source, contains('ProfileSettingsSection'));
    expect(source, contains('assets/svg/new-profile/profile-account.svg'));
    expect(source, contains('assets/svg/new-profile/premium.svg'));
    expect(source, contains('AppBottomNavBar(currentIndex: 4)'));
  });
}
