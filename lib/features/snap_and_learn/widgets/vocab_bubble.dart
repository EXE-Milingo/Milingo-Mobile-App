import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';

const _kAccentLight = Color(0xFFFFF0EB);

/// Floating vocabulary bubble displayed over the captured image.
/// Tapping the card opens the save-to-flashcard sheet.
/// The speaker icon plays the pronunciation.
class VocabBubble extends StatelessWidget {
  const VocabBubble({
    super.key,
    required this.english,
    required this.translation,
    required this.pronunciation,
    required this.onSpeak,
    required this.onSave,
  });

  final String english;
  final String translation;
  final String pronunciation;
  final VoidCallback onSpeak;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  english,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.bookmark_add_rounded,
                    color: AppTheme.primaryColor, size: 11),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  translation,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onSpeak,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.volume_up_rounded,
                      color: AppTheme.primaryColor, size: 13),
                ),
              ],
            ),
            Text(
              pronunciation,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
