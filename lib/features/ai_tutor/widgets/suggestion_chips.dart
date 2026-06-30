import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  Suggestion Chips — Pre-built prompt shortcuts
// ─────────────────────────────────────────────────────────

const _kChipBg = Colors.white;
const _kChipBorder = Color(0xFFE8DDD4);
const _kChipText = Color(0xFF4A3728);

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({
    required this.onChipTap,
    required this.targetLanguage,
    super.key,
  });

  final void Function(String text) onChipTap;
  final String targetLanguage;

  List<_Chip> _chips() {
    final langName = _languageDisplayName(targetLanguage);
    return [
      _Chip(
          emoji: '📖',
          label: 'Ngữ pháp cơ bản',
          prompt: 'Giải thích cho tôi ngữ pháp cơ bản trong $langName.'),
      _Chip(
          emoji: '🔤',
          label: 'Từ vựng thường dùng',
          prompt:
              'Liệt kê 10 từ vựng thông dụng nhất trong $langName kèm nghĩa.'),
      _Chip(
          emoji: '🗣️',
          label: 'Phát âm',
          prompt: 'Hướng dẫn tôi cách phát âm chuẩn trong $langName.'),
      _Chip(
          emoji: '✍️',
          label: 'Câu ví dụ',
          prompt: 'Tạo 3 câu ví dụ đơn giản trong $langName với giải thích.'),
      _Chip(
          emoji: '🎯',
          label: 'Mẹo học',
          prompt: 'Cho tôi các mẹo học $langName hiệu quả nhất.'),
      _Chip(
          emoji: '❓',
          label: 'So sánh từ',
          prompt: 'Giải thích sự khác biệt giữa hai từ trong $langName.'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chips = _chips();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return _ChipItem(
            chip: chip,
            onTap: () => onChipTap(chip.prompt),
          );
        },
      ),
    );
  }

  static String _languageDisplayName(String code) {
    final base = code.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    return switch (base) {
      'en' => 'tiếng Anh',
      'ja' || 'jp' => 'tiếng Nhật',
      'ko' => 'tiếng Hàn',
      'zh' => 'tiếng Trung',
      'fr' => 'tiếng Pháp',
      'de' => 'tiếng Đức',
      'es' => 'tiếng Tây Ban Nha',
      'it' => 'tiếng Ý',
      _ => 'ngôn ngữ đang học',
    };
  }
}

class _Chip {
  const _Chip({
    required this.emoji,
    required this.label,
    required this.prompt,
  });

  final String emoji;
  final String label;
  final String prompt;
}

class _ChipItem extends StatelessWidget {
  const _ChipItem({required this.chip, required this.onTap});

  final _Chip chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kChipBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _kChipBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(chip.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(
                chip.label,
                style: const TextStyle(
                  color: _kChipText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
