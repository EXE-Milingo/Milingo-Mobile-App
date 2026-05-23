import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/widgets/app_bottom_nav_bar.dart';

const _kBg = Color(0xFFFFF7EF);
const _kSurface = Colors.white;
const _kInk = Color(0xFF30211D);
const _kMuted = Color(0xFF9C8D86);
const _kLine = Color(0xFFEDE2DC);
const _kAccent = AppTheme.primaryColor;

const _kTtsLocales = {
  'en': 'en-US',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'zh': 'zh-CN',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'de': 'de-DE',
  'th': 'th-TH',
};

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  final _rng = math.Random();
  final _tts = FlutterTts();

  String? _selectedDeckId;
  int? _requestedCount;
  bool _loadingCards = false;

  DeckData? _quizDeck;
  List<FlashcardEntry> _quizCards = const [];
  List<String> _options = const [];
  int _current = 0;
  int _score = 0;
  String? _selectedOption;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _tts.setSpeechRate(0.45);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(flashcardProvider.future);
        await ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
      } catch (_) {
        // Dashboard still shows provider error state.
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  bool get _isQuizActive => _quizCards.isNotEmpty;
  FlashcardEntry get _question => _quizCards[_current];
  bool get _isLastQuestion => _current == _quizCards.length - 1;

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(flashcardProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: _isQuizActive
          ? _buildQuizScaffold()
          : Scaffold(
              backgroundColor: _kBg,
              body: SafeArea(
                child: decks.when(
                  loading: () => const _ProgressLoading(),
                  error: (error, _) => _ProgressError(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(flashcardProvider.notifier).refresh(),
                  ),
                  data: _buildDashboard,
                ),
              ),
              bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
            ),
    );
  }

  Widget _buildDashboard(FlashcardState state) {
    final decks = state.decks.where((deck) => deck.total > 0).toList();
    final totalWords =
        state.decks.fold<int>(0, (sum, deck) => sum + deck.total);
    final selectedDeck = _selectedDeck(decks);
    final availableCount = selectedDeck == null
        ? 0
        : selectedDeck.cards.isNotEmpty
            ? selectedDeck.cards.length
            : selectedDeck.total;
    final selectedCount = _resolvedCount(availableCount);

    return RefreshIndicator(
      color: _kAccent,
      onRefresh: () async {
        await ref.read(flashcardProvider.notifier).refresh();
        await ref.read(flashcardProvider.notifier).loadCardsForAllDecks();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        children: [
          const _ProgressHeader(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Từ vựng',
                  value: '$totalWords',
                  icon: Icons.menu_book_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Bộ từ',
                  value: '${state.decks.length}',
                  icon: Icons.folder_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Sẵn sàng',
                  value: '$selectedCount',
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Chọn bộ từ',
            trailing: decks.isEmpty ? '' : '${decks.length} bộ',
          ),
          const SizedBox(height: 12),
          if (decks.isEmpty)
            const _EmptyProgressState()
          else
            ...decks.map(
              (deck) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeckChoiceCard(
                  deck: deck,
                  selected: deck.id == selectedDeck?.id,
                  onTap: () {
                    setState(() {
                      _selectedDeckId = deck.id;
                      _requestedCount = null;
                    });
                    if (deck.cards.isEmpty) {
                      ref
                          .read(flashcardProvider.notifier)
                          .loadCardsForDeck(deck.id);
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 14),
          if (selectedDeck != null) ...[
            _SectionTitle(
              title: 'Số lượng kiểm tra',
              trailing:
                  _requestedCount == null ? 'Toàn bộ' : '$selectedCount từ',
            ),
            const SizedBox(height: 12),
            _CountPicker(
              total: availableCount,
              selectedCount: _requestedCount,
              onChanged: (value) => setState(() => _requestedCount = value),
            ),
            const SizedBox(height: 18),
            _StartExamButton(
              loading: _loadingCards,
              enabled: availableCount > 0,
              label: _requestedCount == null
                  ? 'Bắt đầu toàn bộ $availableCount từ'
                  : 'Bắt đầu $selectedCount từ',
              onTap: () => _startQuiz(selectedDeck),
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Ôn tập nhanh',
              trailing: selectedDeck.cards.isEmpty
                  ? 'Đang tải'
                  : '${selectedDeck.cards.length} từ',
            ),
            const SizedBox(height: 12),
            _ReviewPreview(cards: selectedDeck.cards.take(5).toList()),
          ],
        ],
      ),
    );
  }

  DeckData? _selectedDeck(List<DeckData> decks) {
    if (decks.isEmpty) return null;
    final matching = decks.where((deck) => deck.id == _selectedDeckId).toList();
    return matching.isEmpty ? decks.first : matching.first;
  }

  int _resolvedCount(int total) {
    if (total <= 0) return 0;
    if (_requestedCount == null) return total;
    return math.min(_requestedCount!, total);
  }

  Future<void> _startQuiz(DeckData deck) async {
    if (_loadingCards) return;
    setState(() => _loadingCards = true);

    try {
      var latestDeck = deck;
      if (latestDeck.cards.isEmpty && latestDeck.total > 0) {
        await ref.read(flashcardProvider.notifier).loadCardsForDeck(deck.id);
        final state = ref.read(flashcardProvider).valueOrNull;
        final matches =
            state?.decks.where((item) => item.id == deck.id).toList() ??
                const [];
        if (matches.isNotEmpty) latestDeck = matches.first;
      }

      final usableCards = latestDeck.cards
          .where((card) =>
              card.english.trim().isNotEmpty &&
              card.translation.trim().isNotEmpty)
          .toList();
      if (usableCards.isEmpty) {
        _showMessage('Bộ này chưa có từ để kiểm tra.');
        return;
      }

      usableCards.shuffle(_rng);
      final count = _resolvedCount(usableCards.length);
      final picked = usableCards.take(count).toList();

      setState(() {
        _quizDeck = latestDeck;
        _quizCards = picked;
        _current = 0;
        _score = 0;
        _selectedOption = null;
        _answered = false;
        _options = _buildOptions(picked.first, latestDeck.cards);
      });
    } finally {
      if (mounted) setState(() => _loadingCards = false);
    }
  }

  List<String> _buildOptions(FlashcardEntry answer, List<FlashcardEntry> pool) {
    final correct = answer.translation.trim();
    final wrongs = pool
        .map((card) => card.translation.trim())
        .where((value) => value.isNotEmpty && value != correct)
        .toSet()
        .toList()
      ..shuffle(_rng);

    final options = <String>[correct, ...wrongs.take(3)];
    const fallback = ['Không phải đáp án này', 'Đáp án khác', 'Chưa chính xác'];
    for (final item in fallback) {
      if (options.length >= 4) break;
      if (!options.contains(item)) options.add(item);
    }
    options.shuffle(_rng);
    return options;
  }

  void _selectOption(String option) {
    if (_answered) return;
    final correct = option == _question.translation.trim();
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (correct) _score += 10;
    });
  }

  void _nextQuestion() {
    if (!_answered) return;
    if (_isLastQuestion) {
      _showResultDialog();
      return;
    }

    setState(() {
      _current += 1;
      _selectedOption = null;
      _answered = false;
      _options =
          _buildOptions(_quizCards[_current], _quizDeck?.cards ?? _quizCards);
    });
  }

  Future<void> _speakCurrent() async {
    await _tts.setLanguage(_kTtsLocales[_question.langCode] ?? 'en-US');
    await _tts.speak(_question.translation);
  }

  void _exitQuiz() {
    _tts.stop();
    setState(() {
      _quizDeck = null;
      _quizCards = const [];
      _options = const [];
      _current = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
    });
  }

  void _restartQuiz() {
    final cards = List<FlashcardEntry>.from(_quizCards)..shuffle(_rng);
    setState(() {
      _quizCards = cards;
      _current = 0;
      _score = 0;
      _selectedOption = null;
      _answered = false;
      _options = _buildOptions(cards.first, _quizDeck?.cards ?? cards);
    });
  }

  void _showResultDialog() {
    final total = _quizCards.length * 10;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizResultDialog(
        score: _score,
        total: total,
        correct: _score ~/ 10,
        questions: _quizCards.length,
        onRetry: () {
          Navigator.of(context).pop();
          _restartQuiz();
        },
        onExit: () {
          Navigator.of(context).pop();
          _exitQuiz();
        },
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildQuizScaffold() {
    final progress = (_current + 1) / _quizCards.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F4),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _exitQuiz,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF92837D)),
                          SizedBox(width: 5),
                          Text(
                            'Thoát',
                            style: TextStyle(
                              color: Color(0xFF92837D),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'BÀI KIỂM TRA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A7B75),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$_score pts',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Câu hỏi ${_current + 1}',
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' / ${_quizCards.length}',
                        style: const TextStyle(
                          color: Color(0xFFB7AAA5),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8DEDA),
                      color: _kAccent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  _QuestionMediaCard(card: _question, onListen: _speakCurrent),
                  const SizedBox(height: 24),
                  Text(
                    'Chọn bản dịch đúng cho từ "${_question.english}"',
                    style: const TextStyle(
                      color: Color(0xFF7D6E68),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _AnswerOption(
                        label: option,
                        selected: option == _selectedOption,
                        correct: option == _question.translation.trim(),
                        answered: _answered,
                        onTap: () => _selectOption(option),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _NextButton(
                enabled: _answered,
                label: _isLastQuestion ? 'Xem kết quả' : 'Câu tiếp theo',
                onTap: _nextQuestion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: _kInk,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _kInk.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ôn tập theo deck. Kiểm tra bằng số từ bạn chọn.',
            style: TextStyle(
              color: Color(0xFFFFD8C9),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _kAccent, size: 21),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kInk,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.trailing,
  });

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _kInk,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing.isNotEmpty)
          Text(
            trailing,
            style: const TextStyle(
              color: _kMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _DeckChoiceCard extends StatelessWidget {
  const _DeckChoiceCard({
    required this.deck,
    required this.selected,
    required this.onTap,
  });

  final DeckData deck;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFE7DE) : _kSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _kAccent : _kLine,
              width: selected ? 1.7 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? _kAccent : const Color(0xFFFFF0EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    deck.emoji,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${deck.total} từ vựng',
                      style: const TextStyle(
                        color: _kMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? _kAccent : const Color(0xFFD8CCC6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPicker extends StatelessWidget {
  const _CountPicker({
    required this.total,
    required this.selectedCount,
    required this.onChanged,
  });

  final int total;
  final int? selectedCount;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fixed = [5, 10, 20].where((count) => count < total).toList();
    final items = <({String label, int? value})>[
      for (final count in fixed) (label: '$count', value: count),
      (label: 'Tất cả', value: null),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          _CountChip(
            label: item.label,
            selected: item.value == selectedCount,
            onTap: () => onChanged(item.value),
          ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _kAccent : _kSurface,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? _kAccent : _kLine),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : _kInk,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _StartExamButton extends StatelessWidget {
  const _StartExamButton({
    required this.loading,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && !loading ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA225), Color(0xFFF13A2E)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _kAccent.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 21),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ReviewPreview extends StatelessWidget {
  const _ReviewPreview({required this.cards});

  final List<FlashcardEntry> cards;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kLine),
        ),
        child: const Text(
          'Đang lấy từ trong deck...',
          style: TextStyle(color: _kMuted, fontWeight: FontWeight.w800),
        ),
      );
    }

    return Column(
      children: [
        for (final card in cards)
          Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kLine),
            ),
            child: Row(
              children: [
                _TinyCardImage(card: card),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.english,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.translation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TinyCardImage extends StatelessWidget {
  const _TinyCardImage({required this.card});

  final FlashcardEntry card;

  @override
  Widget build(BuildContext context) {
    final imageUrl = card.imageUrl;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE8),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl.isEmpty
          ? const Icon(Icons.image_rounded, color: _kAccent, size: 22)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_rounded, color: _kAccent),
            ),
    );
  }
}

class _QuestionMediaCard extends StatelessWidget {
  const _QuestionMediaCard({
    required this.card,
    required this.onListen,
  });

  final FlashcardEntry card;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final imageUrl = card.imageUrl;

    return AspectRatio(
      aspectRatio: 1.38,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E2A22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  );
                },
                errorBuilder: (_, __, ___) => _QuestionPlaceholder(card: card),
              )
            else
              _QuestionPlaceholder(card: card),
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: onListen,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up_rounded, color: _kAccent, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'NGHE',
                        style: TextStyle(
                          color: _kInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPlaceholder extends StatelessWidget {
  const _QuestionPlaceholder({required this.card});

  final FlashcardEntry card;

  @override
  Widget build(BuildContext context) {
    final initial = card.english.trim().isEmpty
        ? '?'
        : card.english.trim().substring(0, 1).toUpperCase();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10382D), Color(0xFF06150F)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 86,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.selected,
    required this.correct,
    required this.answered,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool correct;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && correct;
    final showWrong = answered && selected && !correct;
    final active = showCorrect || showWrong || selected;
    final bg = showCorrect
        ? _kAccent
        : showWrong
            ? const Color(0xFFFFECE8)
            : _kSurface;
    final border = showCorrect
        ? _kAccent
        : showWrong || selected
            ? _kAccent
            : _kLine;
    final textColor = showCorrect
        ? Colors.white
        : showWrong
            ? _kAccent
            : _kInk;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: answered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: border, width: active ? 2 : 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (showCorrect)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22)
              else if (showWrong)
                const Icon(Icons.cancel_rounded, color: _kAccent, size: 22)
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFE0D7D2), width: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: enabled ? 1 : 0.42,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA225), Color(0xFFF13A2E)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizResultDialog extends StatelessWidget {
  const _QuizResultDialog({
    required this.score,
    required this.total,
    required this.correct,
    required this.questions,
    required this.onRetry,
    required this.onExit,
  });

  final int score;
  final int total;
  final int correct;
  final int questions;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : score / total;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFF0E7E2),
                    color: _kAccent,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(percent * 100).round()}%',
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Hoàn thành bài kiểm tra',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kInk,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct / $questions câu đúng · $score pts',
              style: const TextStyle(
                color: _kMuted,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccent,
                      side: const BorderSide(color: _kAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Thoát',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Làm lại',
                        style: TextStyle(fontWeight: FontWeight.w900)),
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

class _ProgressLoading extends StatelessWidget {
  const _ProgressLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kAccent),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({
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
            const Icon(Icons.error_outline_rounded, color: _kAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: _kMuted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProgressState extends StatelessWidget {
  const _EmptyProgressState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kLine),
      ),
      child: const Column(
        children: [
          Icon(Icons.school_outlined, color: _kAccent, size: 42),
          SizedBox(height: 12),
          Text(
            'Chưa có từ vựng trong deck.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Lưu vài từ từ Snap hoặc Vocabulary rồi quay lại kiểm tra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
