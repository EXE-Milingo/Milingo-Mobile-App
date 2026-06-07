import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile screen source uses the Figma premium settings layout', () {
    final source = File('lib/features/profile/screens/profile_screen.dart')
        .readAsStringSync();

    expect(source, contains('_PremiumButton'));
    expect(source, contains('_SettingsPanel'));
    expect(source, contains('_LeaderboardCard'));
    expect(source, contains('assets/svg/streak.svg'));
    expect(source, contains('assets/svg/xp.png'));
    expect(source, contains('assets/svg/rank.svg'));
    expect(source, contains('assets/svg/profile_setting.svg'));
    expect(source, contains('assets/svg/flag.svg'));
    expect(source, contains('assets/svg/theme.svg'));
    expect(source, contains('assets/svg/purchase.svg'));
    expect(source, contains('assets/svg/logout.svg'));
    expect(source, contains('assets/svg/right-arrow.svg'));
    expect(source, contains('AppBottomNavBar(currentIndex: 4)'));

    expect(source, isNot(contains('_ProfileSectionHeader')));
    expect(source, isNot(contains('_LuxuryLeaderboardCard')));
  });
}
