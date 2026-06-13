import 'package:flutter/material.dart';
import 'package:milingo/features/profile/widgets/account_settings_components.dart';
import 'package:milingo/features/profile/widgets/account_settings_data.dart';

export 'package:milingo/features/profile/widgets/account_settings_data.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({
    required this.profile,
    this.onBack,
    super.key,
  });

  final AccountSettingsProfile profile;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F2),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const AccountSettingsBackground(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
              child: Column(
                children: [
                  AccountSettingsHeader(
                    onBack: onBack ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                  AccountAvatarSection(
                    profile: profile,
                    onChangeAvatar: () {},
                  ),
                  const AccountSectionTitle('Thông tin'),
                  AccountInfoCard(profile: profile),
                  const AccountSectionTitle('Tài khoản liên kết'),
                  AccountLinkedAccountsCard(accounts: profile.linkedAccounts),
                  const AccountSectionTitle('Bảo mật'),
                  const AccountSecurityCard(),
                  AccountDeleteButton(onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
