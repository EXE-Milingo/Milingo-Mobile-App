import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountSettingsProfile {
  const AccountSettingsProfile({
    required this.displayName,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  final String displayName;
  final String email;
  final String firstName;
  final String lastName;
}

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    required this.profile,
    this.onBack,
    super.key,
  });

  final AccountSettingsProfile profile;
  final VoidCallback? onBack;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  bool _emailNotifications = true;
  bool _pushNotifications = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.profile.firstName);
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AccountSettingsColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountSettingsHeader(
                onBack: widget.onBack ?? () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
              _ProfileOverviewCard(profile: widget.profile),
              const SizedBox(height: 24),
              _PersonalInformationCard(
                firstNameController: _firstNameController,
                lastNameController: _lastNameController,
                emailController: _emailController,
              ),
              const SizedBox(height: 24),
              const _SecurityPrivacyCard(),
              const SizedBox(height: 24),
              _NotificationPreferencesCard(
                emailNotifications: _emailNotifications,
                pushNotifications: _pushNotifications,
                onEmailChanged: (value) {
                  setState(() => _emailNotifications = value);
                },
                onPushChanged: (value) {
                  setState(() => _pushNotifications = value);
                },
              ),
              const SizedBox(height: 32),
              const _DeleteAccountButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountSettingsHeader extends StatelessWidget {
  const _AccountSettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: const _AccountSvgIcon(
              'assets/svg/account-back.svg',
              width: 16,
              height: 16,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Cài đặt tài khoản',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AccountSettingsColors.text,
              fontSize: 32,
              height: 38.4 / 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.profile});

  final AccountSettingsProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      height: 130,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 24,
            top: 25,
            bottom: 25,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: _AccountSettingsColors.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned.fill(
            left: 35,
            right: 116,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountSettingsColors.text,
                      fontSize: 24,
                      height: 31.2 / 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    profile.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountSettingsColors.mutedText,
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 9,
            top: 45,
            child: SizedBox(
              width: 90,
              height: 40,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _AccountSettingsColors.editButtonBg,
                  foregroundColor: _AccountSettingsColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    height: 12 / 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text(
                  'Chỉnh sửa\nHồ sơ',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInformationCard extends StatelessWidget {
  const _PersonalInformationCard({
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            assetPath: 'assets/svg/account-person.svg',
            iconBackground: Color(0xFFE7F4FF),
            title: 'Thông tin cá nhân',
          ),
          const SizedBox(height: 24),
          _LabeledInput(label: 'Họ', controller: firstNameController),
          const SizedBox(height: 24),
          _LabeledInput(label: 'Tên', controller: lastNameController),
          const SizedBox(height: 24),
          _LabeledInput(
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: _AccountSettingsColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    height: 12 / 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPrivacyCard extends StatelessWidget {
  const _SecurityPrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const _SettingsCard(
      padding: EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            assetPath: 'assets/svg/account-shield.svg',
            iconBackground: Color(0xFFFFEEE9),
            title: 'Bảo mật & Quyền riêng tư',
          ),
          SizedBox(height: 24),
          _SecurityRow(
            title: 'Mật khẩu',
            subtitle: 'Lần cuối thay đổi 3 tháng trước',
            actionLabel: 'Cập nhật',
          ),
          SizedBox(height: 24),
          _SecurityRow(
            title: 'Xác thực hai yếu tố',
            subtitle: 'Thêm một lớp bảo mật nữa.',
            actionLabel: 'Cho phép',
          ),
        ],
      ),
    );
  }
}

class _NotificationPreferencesCard extends StatelessWidget {
  const _NotificationPreferencesCard({
    required this.emailNotifications,
    required this.pushNotifications,
    required this.onEmailChanged,
    required this.onPushChanged,
  });

  final bool emailNotifications;
  final bool pushNotifications;
  final ValueChanged<bool> onEmailChanged;
  final ValueChanged<bool> onPushChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(
            assetPath: 'assets/svg/account-bell.svg',
            iconBackground: Color(0xFFFFEEE9),
            title: 'Thông báo',
          ),
          const SizedBox(height: 24),
          _NotificationRow(
            title: 'Thông báo qua email',
            subtitle: 'Nhận thông tin cập nhật và\nemail khuyến mãi',
            value: emailNotifications,
            onChanged: onEmailChanged,
          ),
          const SizedBox(height: 16),
          _NotificationRow(
            title: 'Thông báo đẩy',
            subtitle:
                'Nhận thông báo theo thời gian thực\ntrên thiết bị của bạn',
            value: pushNotifications,
            onChanged: onPushChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
    required this.padding,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AccountSettingsColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.assetPath,
    required this.iconBackground,
    required this.title,
  });

  final String assetPath;
  final Color iconBackground;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _AccountSvgIcon(assetPath, width: 20, height: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AccountSettingsColors.text,
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _AccountSettingsColors.mutedText,
            fontSize: 12,
            height: 12 / 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: _AccountSettingsColors.text,
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _AccountSettingsColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 17),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: _AccountSettingsColors.inputBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: _AccountSettingsColors.inputBorder,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 17),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _AccountSettingsColors.cardBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AccountSettingsColors.text,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AccountSettingsColors.mutedText,
                    fontSize: 12,
                    height: 12 / 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: _AccountSettingsColors.text,
                side:
                    const BorderSide(color: _AccountSettingsColors.inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 17),
                textStyle: const TextStyle(
                  fontSize: 12,
                  height: 12 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _AccountSettingsColors.text,
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _AccountSettingsColors.mutedText,
                    fontSize: 12,
                    height: 14 / 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _ToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: value
                ? _AccountSettingsColors.primary
                : _AccountSettingsColors.toggleOff,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? Colors.white : const Color(0xFFD1D5DB),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          foregroundColor: _AccountSettingsColors.danger,
          side: const BorderSide(color: _AccountSettingsColors.danger),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        icon: const _AccountSvgIcon(
          'assets/svg/account-delete.svg',
          width: 16,
          height: 18,
        ),
        label: const Text('Xoá tài khoản'),
      ),
    );
  }
}

class _AccountSvgIcon extends StatelessWidget {
  const _AccountSvgIcon(
    this.assetPath, {
    required this.width,
    required this.height,
  });

  final String assetPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(assetPath, width: width, height: height);
  }
}

class _AccountSettingsColors {
  static const background = Color(0xFFFFF8F6);
  static const primary = Color(0xFFE4502E);
  static const text = Color(0xFF271812);
  static const mutedText = Color(0xFF5C4037);
  static const cardBorder = Color(0x4DE5BEB2);
  static const inputBorder = Color(0xFF917065);
  static const accentSoft = Color(0xFFFFDBD0);
  static const editButtonBg = Color(0x1AA93200);
  static const toggleOff = Color(0xFFE5BEB2);
  static const danger = Color(0xFFBA1A1A);
}
