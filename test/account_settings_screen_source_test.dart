import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account settings screen is separate from profile screen', () {
    final profileSource =
        File('lib/features/profile/screens/profile_screen.dart')
            .readAsStringSync();
    final accountSource = File(
                'lib/features/profile/screens/account_settings_screen.dart')
            .readAsStringSync() +
        File('lib/features/profile/widgets/account_settings_components.dart')
            .readAsStringSync();

    expect(profileSource, contains('account_settings_screen.dart'));
    expect(profileSource, contains('AccountSettingsScreen'));
    expect(profileSource, isNot(contains('AccountSettingsView')));

    expect(accountSource, contains('class AccountSettingsScreen'));
    expect(accountSource, contains('Tài khoản'));
    expect(accountSource, contains('Thông tin'));
    expect(accountSource, contains('Bảo mật'));
    expect(accountSource, contains('Tài khoản liên kết'));
    expect(accountSource, contains('Xoá tài khoản'));
    expect(accountSource, contains('assets/svg/new-profile/account-back.svg'));
    expect(
        accountSource, contains('assets/svg/new-profile/profile-account.svg'));
    expect(accountSource, contains('assets/svg/new-profile/privacy.svg'));
    expect(accountSource, contains('assets/svg/new-profile/delete-acc.svg'));
  });
}
