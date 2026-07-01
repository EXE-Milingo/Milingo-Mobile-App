import 'package:flutter/material.dart';

enum SocialType { google }

class SocialButton extends StatelessWidget {
  const SocialButton({
    required this.type,
    super.key,
    this.isLoading = false,
    this.onTap,
  });

  final SocialType type;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : _buildIcon(),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (type) {
      case SocialType.google:
        return const GoogleIcon();
    }
  }
}

class GoogleIcon extends StatelessWidget {
  const GoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Image.asset(
        'assets/images/google-logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
