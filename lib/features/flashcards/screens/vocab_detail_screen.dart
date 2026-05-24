import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF8F8F8F);
const _kBorder = Color(0xFFE8E2DE);
const _kSoft = Color(0xFFFFEDE7);
const _kWarm = Color(0xFFFFF1EA);
const _kStar = Color(0xFFFFC84B);

class VocabDetailScreen extends ConsumerWidget {
  const VocabDetailScreen({required this.arg, super.key});

  final VocabDetailArg arg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashcardState = ref.watch(flashcardProvider).valueOrNull;
    final deck = _findDeck(flashcardState, arg.deckId);
    final entry = _findEntry(deck, arg.entry);
    final deckName = deck?.name ?? arg.deckName;
    final deckFavorite = deck?.isFavorite ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                  child: _TopBar(
                    deckName: deckName,
                    entry: entry,
                    onBack: () => Navigator.of(context).pop(),
                    onFavoriteWord: arg.deckId.isEmpty
                        ? null
                        : () => _toggleCardFavorite(context, ref, entry),
                    onDeleteFromDeck: arg.deckId.isEmpty
                        ? null
                        : () => _confirmDeleteFromDeck(context, ref, entry),
                    onDeleteEverywhere: () =>
                        _confirmDeleteEverywhere(context, ref, entry),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                sliver: SliverList.list(
                  children: [
                    _HeroImage(entry: entry),
                    const SizedBox(height: 18),
                    _WordPanel(
                      entry: entry,
                      deckFavorite: deckFavorite,
                      onWordFavorite: arg.deckId.isEmpty
                          ? null
                          : () => _toggleCardFavorite(context, ref, entry),
                      onDeckFavorite: deck == null
                          ? null
                          : () => _toggleDeckFavorite(context, ref, deck),
                    ),
                    const SizedBox(height: 14),
                    _DetailLine(
                      label: 'Nghĩa',
                      value: entry.translation,
                      icon: Icons.translate_rounded,
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Loại từ',
                      value: entry.partOfSpeech.trim().isEmpty
                          ? 'Chưa phân loại'
                          : entry.partOfSpeech,
                      icon: Icons.label_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Ngôn ngữ',
                      value: entry.langCode.toUpperCase(),
                      icon: Icons.language_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleCardFavorite(
    BuildContext context,
    WidgetRef ref,
    FlashcardEntry entry,
  ) async {
    try {
      await ref
          .read(flashcardProvider.notifier)
          .setCardFavorite(arg.deckId, entry.id, !entry.isFavorite);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được yêu thích: $error')),
      );
    }
  }

  Future<void> _toggleDeckFavorite(
    BuildContext context,
    WidgetRef ref,
    DeckData deck,
  ) async {
    try {
      await ref
          .read(flashcardProvider.notifier)
          .setDeckFavorite(deck.id, !deck.isFavorite);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được yêu thích: $error')),
      );
    }
  }

  Future<void> _confirmDeleteFromDeck(
    BuildContext context,
    WidgetRef ref,
    FlashcardEntry entry,
  ) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Xóa từ khỏi deck?',
      message: 'Xóa "${entry.english}" khỏi deck này.',
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(flashcardProvider.notifier)
          .deleteCard(arg.deckId, entry.id);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã xóa từ khỏi deck.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được từ: $error')),
      );
    }
  }

  Future<void> _confirmDeleteEverywhere(
    BuildContext context,
    WidgetRef ref,
    FlashcardEntry entry,
  ) async {
    final confirmed = await _confirmDelete(
      context,
      title: 'Xóa khỏi tất cả từ vựng?',
      message: 'Xóa mọi bản lưu của "${entry.english}" trong thư viện.',
    );
    if (confirmed != true) return;

    try {
      final count = await ref
          .read(flashcardProvider.notifier)
          .deleteCardsEverywhere(entry.english, entry.langCode);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Đã xóa $count từ khỏi thư viện.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không xóa được từ: $error')),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.deckName,
    required this.entry,
    required this.onBack,
    required this.onFavoriteWord,
    required this.onDeleteFromDeck,
    required this.onDeleteEverywhere,
  });

  final String deckName;
  final FlashcardEntry entry;
  final VoidCallback onBack;
  final VoidCallback? onFavoriteWord;
  final VoidCallback? onDeleteFromDeck;
  final VoidCallback onDeleteEverywhere;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: _kDark,
          ),
          onPressed: onBack,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            deckName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          tooltip: entry.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích từ',
          onPressed: onFavoriteWord,
          icon: Icon(
            entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            color: entry.isFavorite ? _kStar : _kMuted,
            size: 28,
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Tùy chọn',
          color: _kSurface,
          icon: const Icon(Icons.more_horiz_rounded, color: _kDark),
          onSelected: (value) {
            if (value == 'deck') {
              onDeleteFromDeck?.call();
              return;
            }
            onDeleteEverywhere();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'deck',
              enabled: onDeleteFromDeck != null,
              child: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: _kAccent),
                  SizedBox(width: 10),
                  Text('Xóa khỏi deck'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'all',
              child: Row(
                children: [
                  Icon(Icons.playlist_remove_rounded, color: _kAccent),
                  SizedBox(width: 10),
                  Text('Xóa khỏi tất cả'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.entry});

  final FlashcardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 306,
      decoration: BoxDecoration(
        color: _kWarm,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: _VocabImage(entry: entry),
      ),
    );
  }
}

class _VocabImage extends StatelessWidget {
  const _VocabImage({required this.entry});

  final FlashcardEntry entry;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeBase64(entry.objectImageBase64);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      );
    }

    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      return Image.network(
        entry.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackImage(entry: entry),
      );
    }

    return _FallbackImage(entry: entry);
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.entry});

  final FlashcardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 118,
        height: 118,
        decoration: const BoxDecoration(
          color: _kSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconForPartOfSpeech(entry.partOfSpeech),
          color: _kAccent,
          size: 54,
        ),
      ),
    );
  }
}

class _WordPanel extends StatelessWidget {
  const _WordPanel({
    required this.entry,
    required this.deckFavorite,
    required this.onWordFavorite,
    required this.onDeckFavorite,
  });

  final FlashcardEntry entry;
  final bool deckFavorite;
  final VoidCallback? onWordFavorite;
  final VoidCallback? onDeckFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.english,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: _kDark,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.04,
            ),
          ),
          if (entry.pronunciation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.pronunciation,
              softWrap: true,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: entry.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  label: entry.isFavorite ? 'Đã lưu từ' : 'Lưu từ',
                  active: entry.isFavorite,
                  onTap: onWordFavorite,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: deckFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: deckFavorite ? 'Đã lưu deck' : 'Lưu deck',
                  active: deckFavorite,
                  onTap: onDeckFavorite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? _kSoft : const Color(0xFFFFFBF8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? _kAccent : _kBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? _kStar : _kAccent, size: 21),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? _kDark : _kAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _kAccent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> _confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: _kAccent),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
}

DeckData? _findDeck(FlashcardState? state, String deckId) {
  if (state == null) return null;
  final matches = state.decks.where((deck) => deck.id == deckId).toList();
  return matches.isEmpty ? null : matches.first;
}

FlashcardEntry _findEntry(DeckData? deck, FlashcardEntry fallback) {
  if (deck == null) return fallback;
  final matches = deck.cards.where((card) => card.id == fallback.id).toList();
  return matches.isEmpty ? fallback : matches.first;
}

Uint8List? _decodeBase64(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return base64Decode(value);
  } on FormatException {
    return null;
  }
}

IconData _iconForPartOfSpeech(String partOfSpeech) {
  return switch (partOfSpeech.toLowerCase()) {
    'noun' => Icons.category_rounded,
    'verb' => Icons.directions_run_rounded,
    'adjective' => Icons.auto_awesome_rounded,
    'adverb' => Icons.speed_rounded,
    'pronoun' => Icons.person_rounded,
    'preposition' => Icons.place_rounded,
    'conjunction' => Icons.link_rounded,
    _ => Icons.menu_book_rounded,
  };
}
