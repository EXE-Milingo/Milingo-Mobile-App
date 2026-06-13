import 'dart:io';

import 'package:flutter/material.dart';
import 'package:milingo/features/profile/widgets/account_settings_data.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';

class AccountSettingsBackground extends StatelessWidget {
  const AccountSettingsBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -64,
          right: -80,
          child: _Glow(size: 288, color: Color(0x2EFF8A1F)),
        ),
        Positioned(
          top: 320,
          left: -96,
          child: _Glow(size: 256, color: Color(0x1AFF4D1A)),
        ),
      ],
    );
  }
}

class AccountSettingsHeader extends StatelessWidget {
  const AccountSettingsHeader({
    required this.onBack,
    super.key,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: ProfileSvgIcon(
                    'assets/svg/new-profile/account-back.svg',
                    size: 22,
                    color: _AccountColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tài khoản',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AccountColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.5,
                  ),
                ),
                Text(
                  'Quản lý thông tin cá nhân',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _AccountColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountAvatarSection extends StatelessWidget {
  const AccountAvatarSection({
    required this.profile,
    required this.onChangeAvatar,
    super.key,
  });

  final AccountSettingsProfile profile;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _AccountColors.orange.withValues(alpha: 0.30),
                      boxShadow: [
                        BoxShadow(
                          color: _AccountColors.orange.withValues(alpha: 0.24),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(child: _AccountAvatar(profile: profile)),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onChangeAvatar,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF8A1F),
                              Color(0xFFFF4D1A),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: ProfileSvgIcon(
                            'assets/svg/new-profile/account-camera.svg',
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: onChangeAvatar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 12),
                foregroundColor: _AccountColors.orange,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              child: const Text('Đổi ảnh đại diện'),
            ),
          ),
        ],
      ),
    );
  }
}

class AccountSectionTitle extends StatelessWidget {
  const AccountSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 24),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _AccountColors.section,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.5,
            letterSpacing: 0.56,
          ),
        ),
      ),
    );
  }
}

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({
    required this.profile,
    super.key,
  });

  final AccountSettingsProfile profile;

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      children: [
        _InfoRow(
          icon: const ProfileSvgIcon(
            'assets/svg/new-profile/profile-account.svg',
            size: 16,
            color: _AccountColors.orange,
          ),
          label: 'Tên hiển thị',
          value: profile.displayName,
        ),
        _InfoRow(
          icon: const ProfileSvgIcon(
            'assets/svg/new-profile/mail.svg',
            size: 16,
            color: _AccountColors.orange,
          ),
          label: 'Email',
          value: profile.email,
        ),
        _InfoRow(
          icon: const ProfileSvgIcon(
            'assets/svg/new-profile/phone.svg',
            size: 16,
            color: _AccountColors.orange,
          ),
          label: 'Số điện thoại',
          value: profile.phoneNumber,
        ),
      ],
    );
  }
}

class AccountLinkedAccountsCard extends StatelessWidget {
  const AccountLinkedAccountsCard({
    required this.accounts,
    super.key,
  });

  final List<AccountLinkedProviderData> accounts;

  @override
  Widget build(BuildContext context) {
    return _AccountCard(
      children: [
        for (final account in accounts) _LinkedAccountRow(account: account),
      ],
    );
  }
}

class AccountSecurityCard extends StatelessWidget {
  const AccountSecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AccountCard(
      children: [
        _ActionRow(
          assetPath: 'assets/svg/new-profile/change-pass.svg',
          label: 'Đổi mật khẩu',
        ),
        _ActionRow(
          assetPath: 'assets/svg/new-profile/privacy.svg',
          label: 'Cài đặt quyền riêng tư',
        ),
      ],
    );
  }
}

class AccountDeleteButton extends StatelessWidget {
  const AccountDeleteButton({
    required this.onTap,
    super.key,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: 338,
        height: 49,
        child: Material(
          color: _AccountColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfileSvgIcon(
                  'assets/svg/new-profile/delete-acc.svg',
                  size: 17,
                  color: _AccountColors.danger,
                ),
                SizedBox(width: 8),
                Text(
                  'Xoá tài khoản',
                  style: TextStyle(
                    color: _AccountColors.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: _AccountColors.text.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
              spreadRadius: -14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0x0D000000),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBubble(child: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountColors.section,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedAccountRow extends StatelessWidget {
  const _LinkedAccountRow({required this.account});

  final AccountLinkedProviderData account;

  @override
  Widget build(BuildContext context) {
    final chipColor =
        account.isConnected ? _AccountColors.success : _AccountColors.orange;

    return SizedBox(
      height: 66.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _LetterBubble(letter: account.initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    account.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  Text(
                    account.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AccountColors.section,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withValues(
                    alpha: account.isConnected ? 0.14 : 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                account.isConnected ? 'Đã kết nối' : 'Kết nối',
                style: TextStyle(
                  color: chipColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.assetPath,
    required this.label,
  });

  final String assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBubble(
              child: ProfileSvgIcon(
                assetPath,
                size: 16,
                color: _AccountColors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AccountColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const ProfileSvgIcon(
              'assets/svg/new-profile/account-chevron-right.svg',
              size: 18,
              color: Color(0xFFB8A8A0),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _AccountColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _LetterBubble extends StatelessWidget {
  const _LetterBubble({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFEA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: _AccountColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          height: 1.5,
        ),
      ),
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.profile});

  final AccountSettingsProfile profile;

  @override
  Widget build(BuildContext context) {
    final localPath = profile.localAvatarPath;
    final photoUrl = profile.photoUrl;

    Widget image;
    if (localPath != null && localPath.isNotEmpty) {
      image = Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _AvatarFallback(name: profile.displayName),
      );
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      image = Image.network(
        photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _AvatarFallback(name: profile.displayName),
      );
    } else {
      image = _AvatarFallback(name: profile.displayName);
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipOval(child: image),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '' : name.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFFFFD7C2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: _AccountColors.orange,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 64,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _AccountColors {
  static const text = Color(0xFF1D1814);
  static const muted = Color(0x8C1D1814);
  static const section = Color(0x801D1814);
  static const orange = Color(0xFFFF6A00);
  static const success = Color(0xFF3CA45C);
  static const danger = Color(0xFFD4183D);
}
