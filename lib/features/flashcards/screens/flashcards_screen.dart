import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/deck_arg.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFFFF8F4);
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF9E9E9E);
const _kSoft = Color(0xFFFFEDE7);

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(flashcardProvider);
    final state = asyncState.valueOrNull ?? FlashcardState(decks: const []);
    final totalCards = state.decks.fold<int>(0, (sum, d) => sum + d.cards.length);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            child: Column(
              children: [
                _PracticeSummary(
                  totalCards: totalCards,
                  totalDecks: state.decks.length,
                  canCreateDeck: asyncState.hasValue,
                  onFavoritesTap: () => context.push(AppConstants.allCategoriesRoute),
                  onNewSetTap: () =>
                      _showCreateDeckSheet(context, ref, asyncState.hasValue),
                ),
                const SizedBox(height: 20),
                asyncState.when(
                  loading: () => const _DeckLoadingState(),
                  error: (error, _) => _DeckErrorState(
                    message: error.toString(),
                    onRetry: () => ref.read(flashcardProvider.notifier).refresh(),
                  ),
                  data: (data) => _DeckList(decks: data.decks),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      ),
    );
  }

  void _showCreateDeckSheet(BuildContext context, WidgetRef ref, bool canCreate) {
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decks are still loading.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateDeckSheet(),
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary({
    required this.totalCards,
    required this.totalDecks,
    required this.canCreateDeck,
    required this.onFavoritesTap,
    required this.onNewSetTap,
  });

  final int totalCards;
  final int totalDecks;
  final bool canCreateDeck;
  final VoidCallback onFavoritesTap;
  final VoidCallback onNewSetTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _WordsLearnedRing(totalCards: totalCards),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _HeaderActionCard(
                icon: Icons.star_rounded,
                label: 'My favorites',
                subtitle: '$totalCards cards',
                onTap: onFavoritesTap,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HeaderActionCard(
                icon: Icons.add_rounded,
                label: 'New set',
                subtitle: canCreateDeck ? '$totalDecks sets' : 'Loading',
                onTap: onNewSetTap,
                isPrimaryIcon: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _HeaderActionCard extends StatelessWidget {
  const _HeaderActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isPrimaryIcon = false,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimaryIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          height: 96,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isPrimaryIcon ? _kAccent.withValues(alpha: 0.68) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isPrimaryIcon ? Colors.white : _kAccent.withValues(alpha: 0.62),
                    size: isPrimaryIcon ? 23 : 26,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WordsLearnedRing extends StatelessWidget {
  const _WordsLearnedRing({required this.totalCards});

  final int totalCards;

  @override
  Widget build(BuildContext context) {
    const goal = 600;
    final progress = (totalCards / goal).clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: 164,
        height: 164,
        decoration: BoxDecoration(
          color: _kBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(144, 144),
              painter: _RingPainter(progress: progress),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalCards',
                  style: const TextStyle(
                    color: _kDark,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'WORDS LEARNED',
                  style: TextStyle(
                    color: _kMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${(progress * 100).round()}% goal',
                    style: const TextStyle(
                      color: _kAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 11.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          AppTheme.primaryColor,
          Color(0xFFFF8A65),
          AppTheme.primaryColor,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DeckList extends StatelessWidget {
  const _DeckList({required this.decks});

  final List<DeckData> decks;

  @override
  Widget build(BuildContext context) {
    if (decks.isEmpty) return const _EmptyDeckState();

    return Column(
      children: [
        for (final indexed in decks.indexed) ...[
          _DeckProgressTile(
            deck: indexed.$2,
            learned: indexed.$2.cards.length,
            target: _targetForDeck(indexed.$1, indexed.$2.cards.length),
            onTap: () {
              final target = _targetForDeck(indexed.$1, indexed.$2.cards.length);

              context.push(
                AppConstants.deckRoute,
                extra: DeckArg(
                  id: indexed.$2.id,
                  name: indexed.$2.name,
                  nameVi: indexed.$2.name,
                  total: target,
                  learned: indexed.$2.cards.length,
                  emoji: indexed.$2.emoji,
                ),
              );
            },
          ),
          if (indexed.$1 != decks.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  int _targetForDeck(int index, int learned) {
    const defaults = [150, 48, 132, 20, 80, 64];
    final fallback = defaults[index % defaults.length];
    return math.max(learned, fallback);
  }
}

class _DeckProgressTile extends StatelessWidget {
  const _DeckProgressTile({
    required this.deck,
    required this.learned,
    required this.target,
    required this.onTap,
  });

  final DeckData deck;
  final int learned;
  final int target;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = target == 0 ? 0.0 : (learned / target).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 68,
          padding: const EdgeInsets.fromLTRB(16, 11, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 126,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFEDEDED),
                          color: _kAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$learned/$target',
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.more_vert_rounded, color: Color(0xFFD6D6D6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckLoadingState extends StatelessWidget {
  const _DeckLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kAccent),
    );
  }
}

class _DeckErrorState extends StatelessWidget {
  const _DeckErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: _kAccent, size: 38),
            const SizedBox(height: 10),
            const Text(
              'Could not load your sets',
              style: TextStyle(
                color: _kDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _kAccent),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDeckState extends StatelessWidget {
  const _EmptyDeckState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _kSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.style_rounded, color: _kAccent, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              'No sets yet',
              style: TextStyle(
                color: _kDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a set or save words from Snap & Learn.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateDeckSheet extends ConsumerStatefulWidget {
  const _CreateDeckSheet();

  @override
  ConsumerState<_CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<_CreateDeckSheet> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedEmoji = '📚';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    if (name.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(flashcardProvider.notifier).addDeck(
            name,
            _selectedEmoji,
            description: description.isEmpty ? null : description,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create set: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    const emojiOptions = ['📚', '⭐', '🧠', '✏️', '🔥'];

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'New set',
              style: TextStyle(
                color: _kDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                for (final emoji in emojiOptions)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _selectedEmoji == emoji,
                    selectedColor: _kSoft,
                    checkmarkColor: _kAccent,
                    side: BorderSide(
                      color: _selectedEmoji == emoji ? _kAccent : const Color(0xFFE8E8E8),
                    ),
                    onSelected: (_) => setState(() => _selectedEmoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Set name',
                hintText: 'Travel words',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create set',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
