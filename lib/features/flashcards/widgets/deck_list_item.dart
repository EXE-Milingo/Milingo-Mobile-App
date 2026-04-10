import 'package:flutter/material.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';

class DeckListItem extends StatelessWidget {
  const DeckListItem({
    super.key,
    required this.id,
    required this.name,
    required this.nameVi,
    required this.emoji,
    required this.total,
    required this.learned,
    required this.onTap,
  });

  final String id;
  final String name;
  final String nameVi;
  final String emoji;
  final int total;
  final int learned;
  final VoidCallback onTap;

  /// Convenience constructor from a [DeckArg]
  factory DeckListItem.fromArg(DeckArg deck, {required VoidCallback onTap}) {
    return DeckListItem(
      id: deck.id,
      name: deck.name,
      nameVi: deck.nameVi,
      emoji: deck.emoji,
      total: deck.total,
      learned: deck.learned,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : learned / total;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        nameVi,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFBDBDBD)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF0F0F0),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$learned/$total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.more_vert_rounded,
                    size: 18, color: Color(0xFFBDBDBD)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
