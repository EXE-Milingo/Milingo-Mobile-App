import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';

/// Screen displayed when the free tier daily snap quota is exhausted.
/// Background fills the entire screen matching Figma node #0:2060.
class PremiumLimitScreen extends StatelessWidget {
  const PremiumLimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Figma Background+Shadow fill: #211811
      backgroundColor: const Color(0xFF211811),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────────────
          SafeArea(
            bottom: true,
            child: Column(
              children: [
                // Scrollable hero area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      children: [
                        // Top row: close button + badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.pop();
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  // rgba(255,255,255,0.1)
                                  color: Color(0x1AFFFFFF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            // Figma badge: rgba(255,255,255,0.1) fill +
                            //   1px rgba(255,255,255,0.1) stroke, blur 6px
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                border: Border.all(
                                  color: const Color(0x1AFFFFFF),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '👑',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'YÊU CẦU NÂNG CẤP',
                                    style: TextStyle(
                                      // Figma: #FFEDD5
                                      color: Color(0xFFFFEDD5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Balance spacer
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // ── Premium icon box ──
                        // Figma: gradient 135deg #FF9400→#FF441F,
                        //        boxShadow 0 0 40px rgba(237,143,3,0.4)
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF9400), Color(0xFFFF441F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/svg/premium-icon.svg',
                            width: 44,
                            height: 44,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // ── Title ──
                        // Figma: fontWeight 800, fontSize 36, lineHeight 45px
                        const Text(
                          'Mở khóa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        // Figma gradient text ts1:
                        //   linear-gradient(90deg, #EF9D31 28%, #E1412C 100%)
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFEF9D31), Color(0xFFE1412C)],
                            stops: [0.28, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: const Text(
                            'quyền truy cập PRO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle — Figma: rgba(255,255,255,0.6), 14px
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Quét vật thể không giới hạn, xây dựng vốn từ vựng nhanh hơn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0x99FFFFFF),
                              fontSize: 14,
                              height: 1.625,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
                // ── Quota card ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      // Figma: white fill, #F3F4F6 stroke 1px, borderRadius 24px
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: icon + title + badge
                        Row(
                          children: [
                            // Figma: red block icon (#EF4444)
                            const Icon(
                              Icons.block_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Đã hết lượt quét miễn phí',
                                style: TextStyle(
                                  // Figma: #111827, bold, 16px
                                  color: Color(0xFF111827),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // Badge "Còn 0 / 3" — Figma: #FEF2F2 bg, #EF4444 text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Còn 0 / 3',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress dots — 3 filled red pills
                        // Figma: #FEE2E2 fill, #FECACA stroke, borderRadius 9999px
                        Row(
                          children: List.generate(
                              3,
                              (i) => Expanded(
                                    child: Container(
                                      margin:
                                          EdgeInsets.only(right: i < 2 ? 6 : 0),
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        border: Border.all(
                                            color: const Color(0xFFFECACA)),
                                        borderRadius:
                                            BorderRadius.circular(9999),
                                      ),
                                    ),
                                  )),
                        ),
                        const SizedBox(height: 12),
                        // Body text
                        const Text(
                          'Bạn đã dùng hết 3 lượt quét hôm nay. Nâng cấp để tiếp tục.',
                          style: TextStyle(
                            // Figma: #6B7280, 12px, regular
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            height: 1.625,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── CTA section pinned to bottom ────────────────────────

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // Figma Button: gradient 180deg #EF9B31→#E23F2D
                      GestureDetector(
                        onTap: () => context.push(AppConstants.premiumRoute),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF9B31), Color(0xFFE23F2D)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/svg/premium-icon.svg',
                                width: 22,
                                height: 22,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Nâng cấp lên PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Fine print — Figma: #9CA3AF, 10px
                      const Text(
                        'By subscribing you agree to our Terms of Service & Privacy Policy.\nSubscription renews automatically.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                          height: 1.625,
                        ),
                      ),
                    ],
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
