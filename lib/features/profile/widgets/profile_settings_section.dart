import 'package:flutter/material.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';
import 'package:milingo/features/profile/widgets/profile_view_data.dart';

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({
    required this.items,
    required this.onLogoutTap,
    super.key,
  });

  final List<ProfileSettingsItemData> items;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt',
          style: TextStyle(
            color: _SettingsColors.text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1814).withValues(alpha: 0.12),
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
                for (var index = 0; index < items.length; index++) ...[
                  _SettingsTile(item: items[index]),
                  if (index != items.length - 1)
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
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: const Color(0x14FF4D1A),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onLogoutTap,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProfileSvgIcon(
                      'assets/svg/new-profile/logout.svg',
                      size: 17,
                      color: _SettingsColors.orange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: Color(0xFFFF4D1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final ProfileSettingsItemData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _SettingsColors.orange.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ProfileSvgIcon(
                  item.assetPath,
                  size: 17,
                  color: _SettingsColors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SettingsColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB8A8A0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsColors {
  static const text = Color(0xFF1D1814);
  static const orange = Color(0xFFFF6A00);
}
