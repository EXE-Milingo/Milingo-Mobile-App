import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Slow continuous spin for the logo
  late AnimationController _spinController;

  // Drives the 3-dot loading sequence
  late AnimationController _dotsController;

  // Per-dot bounce animations (staggered)
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();

    // ── Logo spin: one full rotation every 3 s ─────────────
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // ── Dots: each dot bounces up then returns, staggered ──
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Each dot occupies 40 % of the cycle, offset by 20 %
    _dot1 = _bounceTween(0.00, 0.40);
    _dot2 = _bounceTween(0.20, 0.60);
    _dot3 = _bounceTween(0.40, 0.80);

    // Navigate after 3.5 s so the user sees at least one full spin
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) context.go(AppConstants.authRoute);
    });
  }

  Animation<double> _bounceTween(double start, double end) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -10.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -10.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: Interval(start, end, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF5F0),
              Color(0xFFFCEDE8),
              Color(0xFFFFF8F4),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // ── Spinning logo ──────────────────────────────
            AnimatedBuilder(
              animation: _spinController,
              builder: (_, child) => Transform.rotate(
                angle: _spinController.value * 2 * 3.14159265,
                child: child,
              ),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.18),
                      blurRadius: 30,
                      spreadRadius: -4,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/svg/milingo-logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 56),

            // ── Three bouncing dots ───────────────────────
            AnimatedBuilder(
              animation: _dotsController,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Dot(offset: _dot1.value),
                  const SizedBox(width: 10),
                  _Dot(offset: _dot2.value),
                  const SizedBox(width: 10),
                  _Dot(offset: _dot3.value),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.offset});
  final double offset; // negative = moved upward

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, offset),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
