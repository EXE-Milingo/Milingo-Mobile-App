import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:milingo/features/profile/widgets/profile_svg_icon.dart';
import 'package:milingo/features/profile/widgets/profile_view_data.dart';

class ProfilePremiumCard extends StatelessWidget {
  const ProfilePremiumCard({
    required this.data,
    required this.onUpgradeTap,
    super.key,
  });

  final ProfileViewData data;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = data.isPremium;

    return Container(
      height: 247,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: _PremiumColors.orange.withValues(alpha: 0.50),
            blurRadius: 44,
            offset: const Offset(0, 22),
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              left: 202,
              top: -48,
              child: _GlowCircle(
                size: 176,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            const Positioned(
              left: 234,
              top: 150.5,
              child: Opacity(
                opacity: 0.28,
                child: ProfileSvgIcon(
                  'assets/svg/new-profile/profile-trophy.svg',
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
            const Positioned(
              left: 302,
              top: 20,
              child: ProfileSvgIcon(
                'assets/svg/new-profile/profile-star-icon.svg',
                size: 16,
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _MembershipPill(),
                  const SizedBox(height: 8),
                  Text(
                    isPremium
                        ? (data.premiumPlanName ?? 'Gói Premium')
                        : 'Mở khoá toàn bộ Milingo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isPremium) ...[
                    Text(
                      data.premiumExpiresAt != null
                          ? 'Hạn dùng: ${DateFormat('dd/MM/yyyy').format(data.premiumExpiresAt!)}'
                          : 'Trạng thái: Đang hoạt động',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _PremiumBullet('Đã mở khóa AI Tutor không giới hạn'),
                    const _PremiumBullet('Đã mở khóa quét từ không giới hạn'),
                  ] else ...[
                    const _PremiumBullet('AI Tutor không giới hạn'),
                    const _PremiumBullet('Quét từ không giới hạn'),
                    const _PremiumBullet('Ôn tập nâng cao'),
                  ],
                  const Spacer(),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 51,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.14),
                          child: InkWell(
                            onTap: onUpgradeTap,
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    isPremium
                                        ? 'Quản lý gói đăng ký'
                                        : 'Nâng cấp Premium',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFFF4D1A),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFFF4D1A),
                                  size: 17,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _MembershipPill extends StatelessWidget {
  const _MembershipPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileSvgIcon(
            'assets/svg/new-profile/profile-premium-member.svg',
            size: 12,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            'Premium Member',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBullet extends StatelessWidget {
  const _PremiumBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const ProfileSvgIcon(
            'assets/svg/new-profile/profile-star-icon.svg',
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xF2FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _PremiumColors {
  static const orange = Color(0xFFFF6A00);
}
