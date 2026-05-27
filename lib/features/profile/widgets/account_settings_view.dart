import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

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

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({
    required this.profile,
    this.onBack,
    super.key,
  });

  final AccountSettingsProfile profile;
  final VoidCallback? onBack;

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  bool _emailNotifications = true;
  bool _pushNotifications = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.profile.firstName);
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
        child: Column(
          children: [
            _AccountSettingsHeader(
              onBack: widget.onBack ?? () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 28),
                child: Column(
                  children: [
                    _ProfileSummaryCard(profile: widget.profile),
                    const SizedBox(height: 20),
                    _SectionCard(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF1796F3),
                      iconBackground: const Color(0xFFEAF6FF),
                      title: 'Thông tin cá nhân',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LabeledInput(
                            label: 'Họ',
                            controller: _firstNameController,
                          ),
                          const SizedBox(height: 18),
                          _LabeledInput(
                            label: 'Tên',
                            controller: _lastNameController,
                          ),
                          const SizedBox(height: 18),
                          _LabeledInput(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 36),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 106,
                              height: 36,
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      _AccountSettingsColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: const Text('Save Changes'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _SectionCard(
                      icon: Icons.shield_outlined,
                      iconColor: _AccountSettingsColors.primary,
                      iconBackground: Color(0xFFFFEEE9),
                      title: 'Bảo mật & Quyền riêng tư',
                      child: Column(
                        children: [
                          _SecurityRow(
                            title: 'Mật khẩu',
                            subtitle: 'Lần cuối thay đổi 3 tháng trước',
                            actionLabel: 'Cập nhật',
                          ),
                          Divider(height: 28, color: Color(0xFFF1E5E0)),
                          _SecurityRow(
                            title: 'Xác thực hai yếu tố',
                            subtitle: 'Thêm một lớp bảo mật nữa.',
                            actionLabel: 'Cho phép',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SectionCard(
                      icon: Icons.notifications_none_rounded,
                      iconColor: _AccountSettingsColors.primary,
                      iconBackground: const Color(0xFFFFEEE9),
                      title: 'Thông báo',
                      child: Column(
                        children: [
                          _NotificationRow(
                            title: 'Thông báo qua email',
                            subtitle:
                                'Nhận thông tin cập nhật và email khuyến mãi',
                            value: _emailNotifications,
                            onChanged: (value) {
                              setState(() => _emailNotifications = value);
                            },
                          ),
                          const SizedBox(height: 28),
                          _NotificationRow(
                            title: 'Thông báo đẩy',
                            subtitle:
                                'Nhận thông báo theo thời gian thực trên thiết bị của bạn',
                            value: _pushNotifications,
                            onChanged: (value) {
                              setState(() => _pushNotifications = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Xóa tài khoản'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE13224),
                          side: const BorderSide(
                            color: Color(0xFFE13224),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: _AccountSettingsColors.text,
            iconSize: 22,
          ),
          const SizedBox(width: 2),
          const Text(
            'Cài đặt tài khoản',
            style: TextStyle(
              color: _AccountSettingsColors.text,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.profile});

  final AccountSettingsProfile profile;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 60,
            color: const Color(0xFFFFC2B1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AccountSettingsColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _AccountSettingsColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 66,
            height: 34,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE3DC),
                foregroundColor: _AccountSettingsColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              child: const Text(
                'Chỉnh sửa\nHồ sơ',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _AccountSettingsColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF2E5E0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
            color: _AccountSettingsColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: _AccountSettingsColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _AccountSettingsColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: Color(0xFF9A6F62),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: _AccountSettingsColors.primary,
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _AccountSettingsColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _AccountSettingsColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 72,
          height: 28,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _AccountSettingsColors.text,
              side: const BorderSide(color: Color(0xFF9A6F62), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      ],
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _AccountSettingsColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _AccountSettingsColors.mutedText,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: _AccountSettingsColors.primary,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE7B8AA),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _AccountSettingsColors {
  static const background = Color(0xFFFFF9F6);
  static const primary = AppTheme.primaryColor;
  static const text = Color(0xFF2A1D19);
  static const mutedText = Color(0xFF8D6F67);
}
