import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

/// Interactive vocabulary bubble displayed around a detected object.
class VocabBubble extends StatelessWidget {
  const VocabBubble({
    required this.english,
    required this.translation,
    required this.onSpeak,
    required this.onSave,
    super.key,
  });

  final String english;
  final String translation;
  final VoidCallback onSpeak;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            english.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            translation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF605851),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Phát âm',
                onPressed: onSpeak,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(34),
                  maximumSize: const Size.square(34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.10,
                  ),
                ),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Lưu vào bộ thẻ',
                onPressed: onSave,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(34),
                  maximumSize: const Size.square(34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.10,
                  ),
                ),
                icon: const Icon(
                  Icons.bookmark_add_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
