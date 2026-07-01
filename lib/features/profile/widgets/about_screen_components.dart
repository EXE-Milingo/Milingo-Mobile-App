import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';

class AboutBackground extends StatelessWidget {
  const AboutBackground({super.key});

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

class AboutHeader extends StatelessWidget {
  const AboutHeader({
    required this.onBack,
    super.key,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
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
                    color: _AboutColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'About Milingo',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _AboutColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutHero extends StatelessWidget {
  const AboutHero({super.key});

  @override
  Widget build(BuildContext context) {
    final version = AppConstants.appVersion.replaceFirst(RegExp(r'\.0$'), '');

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Image.asset(
            'assets/svg/milingo-logo.png',
            width: 128,
            height: 128,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 3),
          const Text(
            'Milingo',
            style: TextStyle(
              color: _AboutColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          Text(
            'Phiên bản $version',
            style: const TextStyle(
              color: _AboutColors.section,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutMissionCard extends StatelessWidget {
  const AboutMissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: _AboutSurface(
        padding: EdgeInsets.all(21),
        child: Column(
          children: [
            Text(
              'Sứ mệnh của chúng tôi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AboutColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Học ngôn ngữ bằng chính chiếc camera\ncủa bạn 📷',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AboutColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutSectionTitle extends StatelessWidget {
  const AboutSectionTitle(this.title, {super.key});

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
            color: _AboutColors.section,
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

class AboutTeamCard extends StatelessWidget {
  const AboutTeamCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: _AboutListCard(
        children: [
          _AboutInfoRow(
            assetPath: 'assets/svg/new-profile/profile-star-icon.svg',
            label: 'Milingo Team',
            trailingText: '2DEV',
          ),
        ],
      ),
    );
  }
}

class AboutLinksCard extends StatelessWidget {
  const AboutLinksCard({
    required this.onWebsiteTap,
    required this.onTermsTap,
    required this.onPrivacyTap,
    super.key,
  });

  final VoidCallback onWebsiteTap;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _AboutListCard(
        children: [
          _AboutActionRow(
            assetPath: 'assets/svg/new-profile/website.svg',
            label: 'Website',
            onTap: onWebsiteTap,
          ),
          _AboutActionRow(
            assetPath: 'assets/svg/new-profile/term_and_service.svg',
            label: 'Điều khoản dịch vụ',
            onTap: onTermsTap,
          ),
          _AboutActionRow(
            assetPath: 'assets/svg/new-profile/privacy.svg',
            label: 'Chính sách bảo mật',
            onTap: onPrivacyTap,
          ),
        ],
      ),
    );
  }
}

class AboutSocialButtons extends StatelessWidget {
  const AboutSocialButtons({
    required this.onTwitterTap,
    required this.onInstagramTap,
    required this.onGithubTap,
    super.key,
  });

  final VoidCallback onTwitterTap;
  final VoidCallback onInstagramTap;
  final VoidCallback onGithubTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: _SocialButton(
              assetPath: 'assets/svg/new-profile/twitter.svg',
              onTap: onTwitterTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SocialButton(
              assetPath: 'assets/svg/new-profile/instagram.svg',
              onTap: onInstagramTap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SocialButton(
              assetPath: 'assets/svg/new-profile/github.svg',
              onTap: onGithubTap,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutCopyright extends StatelessWidget {
  const AboutCopyright({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          '© ${DateTime.now().year} Milingo. All rights reserved.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0x661D1814),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _AboutListCard extends StatelessWidget {
  const _AboutListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _AboutSurface(
      padding: EdgeInsets.zero,
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
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({
    required this.assetPath,
    required this.label,
    this.trailingText,
  });

  final String assetPath;
  final String label;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconBubble(assetPath: assetPath),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AboutColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(
                  color: _AboutColors.section,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AboutActionRow extends StatelessWidget {
  const _AboutActionRow({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 65,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _IconBubble(assetPath: assetPath),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AboutColors.text,
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
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.assetPath,
    required this.onTap,
  });

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
              boxShadow: [
                BoxShadow(
                  color: _AboutColors.text.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ProfileSvgIcon(
              assetPath,
              size: 20,
              color: _AboutColors.orange,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _AboutColors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ProfileSvgIcon(
        assetPath,
        size: 16,
        color: _AboutColors.orange,
      ),
    );
  }
}

class _AboutSurface extends StatelessWidget {
  const _AboutSurface({
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: _AboutColors.text.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -14,
          ),
        ],
      ),
      child: child,
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

class _AboutColors {
  static const text = Color(0xFF1D1814);
  static const section = Color(0x801D1814);
  static const orange = Color(0xFFFF6A00);
}
