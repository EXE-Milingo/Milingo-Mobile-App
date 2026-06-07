import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account settings screen is separate from profile screen', () {
    final profileSource =
        File('lib/features/profile/screens/profile_screen.dart')
            .readAsStringSync();
    final accountSource =
        File('lib/features/profile/screens/account_settings_screen.dart')
            .readAsStringSync();

    expect(profileSource, contains('account_settings_screen.dart'));
    expect(profileSource, contains('AccountSettingsScreen'));
    expect(profileSource, isNot(contains('AccountSettingsView')));

    expect(accountSource, contains('class AccountSettingsScreen'));
    expect(accountSource, contains('Cài đặt tài khoản'));
    expect(accountSource, contains('Thông tin cá nhân'));
    expect(accountSource, contains('Bảo mật & Quyền riêng tư'));
    expect(accountSource, contains('Thông báo'));
    expect(accountSource, contains('Xoá tài khoản'));
    expect(accountSource, contains('assets/svg/account-back.svg'));
    expect(accountSource, contains('assets/svg/account-person.svg'));
    expect(accountSource, contains('assets/svg/account-shield.svg'));
    expect(accountSource, contains('assets/svg/account-bell.svg'));
    expect(accountSource, contains('assets/svg/account-delete.svg'));
  });
}
