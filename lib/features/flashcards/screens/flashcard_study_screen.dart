import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1A1A1A);
const _kMuted = Color(0xFF8F8F8F);
const _kBorder = Color(0xFFE8E2DE);
const _kSoft = Color(0xFFFFEDE7);

class FlashcardStudyArg {
  const FlashcardStudyArg({
    required this.deckName,
    required this.cards,
  });

  final String deckName;
  final List<FlashcardEntry> cards;
}

class FlashcardStudyScreen extends StatefulWidget {
  const FlashcardStudyScreen({
    required this.deckName,
    required this.cards,
    super.key,
  });

  final String deckName;
  final List<FlashcardEntry> cards;

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _index = 0;
  bool _showBack = false;

  FlashcardEntry get _current => widget.cards[_index];

  void _flip() {
    if (widget.cards.isEmpty) return;
    setState(() => _showBack = !_showBack);
  }

  void _previous() {
    if (_index == 0) return;
    setState(() {
      _index -= 1;
      _showBack = false;
    });
  }

  void _next() {
    if (_index >= widget.cards.length - 1) return;
    setState(() {
      _index += 1;
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              children: [
                _StudyHeader(
                  deckName: widget.deckName,
                  count: widget.cards.length,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: widget.cards.isEmpty
                      ? const _EmptyStudyState()
                      : Column(
                          children: [
                            Text(
                              '${_index + 1}/${widget.cards.length}',
                              style: const TextStyle(
                                color: _kMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Expanded(
                              child: Center(
                                child: FlashcardStudyCard(
                                  entry: _current,
                                  showBack: _showBack,
                                  onTap: _flip,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _StudyControls(
                              canGoBack: _index > 0,
                              canGoNext: _index < widget.cards.length - 1,
                              onPrevious: _previous,
                              onNext: _next,
                            ),
                          ],
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

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.deckName,
    required this.count,
  });

  final String deckName;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Quay lai',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _kDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deckName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count the',
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FlashcardStudyCard extends StatefulWidget {
  const FlashcardStudyCard({
    required this.entry,
    required this.showBack,
    required this.onTap,
    super.key,
  });

  final FlashcardEntry entry;
  final bool showBack;
  final VoidCallback onTap;

  @override
  State<FlashcardStudyCard> createState() => _FlashcardStudyCardState();
}

class _FlashcardStudyCardState extends State<FlashcardStudyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _angle;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: widget.showBack ? 1 : 0,
    );
    _angle = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ).drive(Tween<double>(begin: 0, end: math.pi));
  }

  @override
  void didUpdateWidget(covariant FlashcardStudyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showBack == widget.showBack) return;

    if (widget.showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lat the',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _angle,
            builder: (context, _) {
              final angle = _angle.value;
              final showingBack = angle > math.pi / 2;

              return Transform(
                key: const ValueKey('flashcard-flip-transform'),
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(showingBack ? math.pi : 0),
                  child: _FlashcardFace(
                    entry: widget.entry,
                    showBack: showingBack,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FlashcardFace extends StatelessWidget {
  const _FlashcardFace({
    required this.entry,
    required this.showBack,
  });

  final FlashcardEntry entry;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final supporting = showBack
        ? ''
        : [
            if (entry.pronunciation.trim().isNotEmpty)
              entry.pronunciation.trim(),
            if (entry.partOfSpeech.trim().isNotEmpty) entry.partOfSpeech.trim(),
          ].join('  ');

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 320,
        maxWidth: 520,
      ),
      padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: showBack || entry.imageUrl == null
                ? Icon(
                    showBack
                        ? Icons.translate_rounded
                        : _iconForPartOfSpeech(entry.partOfSpeech),
                    color: _kAccent,
                    size: 32,
                  )
                : Image.network(
                    entry.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      _iconForPartOfSpeech(entry.partOfSpeech),
                      color: _kAccent,
                      size: 32,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            showBack ? entry.translation : entry.english,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kDark,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          if (supporting.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              supporting,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Cham de lat the',
            style: TextStyle(
              color: _kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyControls extends StatelessWidget {
  const _StudyControls({
    required this.canGoBack,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ControlButton(
          tooltip: 'The truoc',
          icon: Icons.arrow_back_rounded,
          onPressed: canGoBack ? onPrevious : null,
        ),
        const SizedBox(width: 18),
        _ControlButton(
          tooltip: 'The tiep theo',
          icon: Icons.arrow_forward_rounded,
          onPressed: canGoNext ? onNext : null,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: onPressed == null ? _kSoft : _kAccent,
        disabledBackgroundColor: _kSoft,
        shape: const CircleBorder(),
        fixedSize: const Size(58, 58),
      ),
      icon: Icon(
        icon,
        color: onPressed == null ? _kMuted : Colors.white,
        size: 28,
      ),
    );
  }
}

class _EmptyStudyState extends StatelessWidget {
  const _EmptyStudyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Chua co the nao trong bo nay.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _kMuted,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
