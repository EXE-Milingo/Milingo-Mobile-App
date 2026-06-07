import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bottom bar with gallery, capture, and effect buttons.
class BottomCaptureBar extends StatelessWidget {
  const BottomCaptureBar({
    required this.onGallery,
    required this.onCapture,
    super.key,
  });

  final VoidCallback onGallery;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(48, 12, 48, 68),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Gallery
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onGallery,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.photo_library_rounded,
                    color: Colors.grey[700], size: 22),
              ),
            ),
          ),

          // Capture (orange ring)
          GestureDetector(
            onTap: onCapture,
            child: SvgPicture.asset(
              'assets/svg/takepicure.svg',
              width: 82,
              height: 82,
            ),
          ),
        ],
      ),
    );
  }
}
