import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FloatingNavButton
// A floating "+" button that slides down a light gradient dropdown panel.
// The panel background starts from behind the plus-icon button itself.
// ─────────────────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFFF25F36);
const _kDark = Color(0xFF1A1A1A);
const _kPanelTop = Color(0xFFD9D9D9);
const _kPanelBottom = Color(0xFFFFF5E9);

const _kButtonSize = 44.0;
const _kPanelWidth = 70.0;
const _kPanelHeight = 270.0;

class FloatingNavButton extends StatefulWidget {
  const FloatingNavButton({super.key});

  @override
  State<FloatingNavButton> createState() => _FloatingNavButtonState();
}

class _FloatingNavButtonState extends State<FloatingNavButton>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  void _close() {
    setState(() => _isOpen = false);
    _ctrl.reverse();
  }

  void _navigate(String route) {
    _close();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kPanelWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Gradient panel (starts from behind the button) ──
          SizeTransition(
            sizeFactor: _slideAnim,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: _kPanelWidth,
                  height: _kPanelHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kPanelTop, _kPanelBottom],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  // Nav items inside, below the button area
                  padding: EdgeInsets.only(
                    top: _kButtonSize + 4,
                    bottom: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavIcon(
                        assetPath: 'assets/svg/camera.svg',
                        label: 'Camera',
                        onTap: () => _navigate(AppConstants.snapAndLearnRoute),
                      ),
                      _NavIcon(
                        assetPath: 'assets/svg/review.svg',
                        label: 'Ôn tập',
                        onTap: () => _navigate(AppConstants.flashcardsRoute),
                      ),
                      _NavIcon(
                        assetPath: 'assets/svg/personalize.svg',
                        label: 'Cá nhân',
                        onTap: () => _navigate(AppConstants.profileRoute),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Plus / Close button (on top of the panel) ──
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: _kButtonSize,
              height: _kButtonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AnimatedRotation(
                  turns: _isOpen ? 0.125 : 0.0, // 45° rotation → + becomes ×
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: SvgPicture.asset(
                    'assets/svg/plus-circle.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _isOpen ? _kAccent : _kDark,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav icon: rounded-square with SVG icon, no label
// ─────────────────────────────────────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.assetPath,
    required this.label,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                assetPath,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  _kAccent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

