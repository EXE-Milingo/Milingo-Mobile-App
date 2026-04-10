import 'package:flutter/material.dart';

enum SocialType { apple, google, facebook }

class SocialButton extends StatelessWidget {
  const SocialButton({super.key, required this.type, this.onTap});
  final SocialType type;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: _buildIcon()),
      ),
    );
  }

  Widget _buildIcon() {
    switch (type) {
      case SocialType.apple:
        return const Icon(Icons.apple, size: 28, color: Color(0xFF1A1A1A));
      case SocialType.google:
        return const GoogleIcon();
      case SocialType.facebook:
        return const Icon(Icons.facebook, size: 28, color: Color(0xFF1877F2));
    }
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: GooglePainter()),
    );
  }
}

class GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    _drawArc(canvas, cx, cy, r, -0.1, 1.55, const Color(0xFF4285F4));
    _drawArc(canvas, cx, cy, r, 1.45, 1.55, const Color(0xFFEA4335));
    _drawArc(canvas, cx, cy, r, 2.99, 1.6, const Color(0xFFFBBC05));
    _drawArc(canvas, cx, cy, r, 4.58, 0.93, const Color(0xFF34A853));

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.62, whitePaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..strokeWidth = r * 0.38
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx + r * 0.02, cy),
      Offset(cx + r * 0.95, cy),
      barPaint,
    );
  }

  void _drawArc(Canvas canvas, double cx, double cy, double r,
      double startAngle, double sweepAngle, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(cx, cy)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
