import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

/// Bottom bar with gallery, capture, and effect buttons.
class BottomCaptureBar extends StatelessWidget {
  const BottomCaptureBar({
    super.key,
    required this.onGallery,
    required this.onCapture,
  });

  final VoidCallback onGallery;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(48, 12, 48, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery
          GestureDetector(
            onTap: onGallery,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_library_rounded,
                  color: Colors.grey[600], size: 22),
            ),
          ),

          // Capture (orange ring)
          GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppTheme.primaryColor, width: 3.5),
              ),
              child: Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                ),
              ),
            ),
          ),

          // Effect
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_fix_high_rounded,
                  color: Colors.grey[600], size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
