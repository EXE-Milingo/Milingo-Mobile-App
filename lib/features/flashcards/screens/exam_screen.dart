import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/core/constants/app_constants.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/profile/providers/profile_provider.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/shared/utils/tts_locale.dart';

const _kBg = Color(0xFFFBF7F2);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1D1814);
const _kMuted = Color(0xFF8E817A);
const _kBorder = Color(0xFFF0E4DE);
const _kSuccess = Color(0xFF2EAD62);
const _kDanger = Color(0xFFE14E43);

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({
    required this.deckId,
    required this.deckName,
    required this.langCode,
    required this.langName,
    super.key,
  });

  final String deckId;
  final String deckName;
  final String langCode;
  final String langName;

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  late final FlutterTts _tts;

  StudySessionResponse? _session;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  int _current = 0;
  int _correct = 0;
  int _coins = 0;
  bool _answered = false;
  bool _revealed = false;
  String? _selectedOptionId;
  int? _selectedQuality;
  bool _closingResultDialogForRetry = false;
  bool _closingResultDialogForReviewRoot = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setSpeechRate(0.45);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSession());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  List<StudyCard> get _cards => _session?.cards ?? const [];
  StudyCard get _card => _cards[_current];
  bool get _isLast => _current >= _cards.length - 1;
  bool get _isDailySession =>
      widget.deckId.trim().isEmpty || widget.deckId.trim() == 'all';

  String get _sessionTitle {
    if (_isDailySession) return 'Ôn tập hôm nay';
    return widget.deckName.isEmpty ? 'Ôn tập' : widget.deckName;
  }

  String get _modeLabel {
    if (_card.isMcq) return 'Trắc nghiệm';
    return _card.isFirstReview ? 'Thẻ học lần đầu' : 'Thẻ học';
  }

  bool get _isOptionsEnglish {
    if (_card.options == null || _card.options!.isEmpty) return true;
    return _card.options!
        .any((opt) => opt.term.toLowerCase() == _card.term.toLowerCase());
  }

  String get _promptText {
    if (!_card.isMcq) return _card.term;
    return _isOptionsEnglish ? _card.translation : _card.term;
  }

  String get _promptPronunciation {
    if (!_card.isMcq) return _card.pronunciation;
    return _isOptionsEnglish ? '' : _card.pronunciation;
  }

  String get _promptInstruction {
    if (!_card.isMcq) return '';
    return _isOptionsEnglish ? 'Chọn từ đúng' : 'Từ này có nghĩa là gì?';
  }

  Future<void> _loadSession() async {
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
      _current = 0;
      _correct = 0;
      _coins = 0;
      _answered = false;
      _revealed = false;
      _selectedOptionId = null;
      _selectedQuality = null;
    });

    try {
      final api = ref.read(milingoApiServiceProvider);
      final session = _isDailySession
          ? await api.getDailyStudySession(limit: 30)
          : await api.getStudySession(widget.deckId, limit: 20);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _speak() async {
    final cardLangCode = _card.targetLangCode.trim().toLowerCase();
    final profileLangCode = ref
            .read(userProfileProvider)
            .valueOrNull
            ?.targetLanguage
            ?.trim()
            .toLowerCase() ??
        '';
    final routeLangCode = widget.langCode.trim().toLowerCase();
    final langCode = cardLangCode.isNotEmpty
        ? cardLangCode
        : profileLangCode.isNotEmpty
            ? profileLangCode
            : routeLangCode;
    await _tts.setLanguage(ttsLocaleForLanguageCode(langCode));
    await _tts.stop();
    await _tts.speak(_card.term);
  }

  Future<void> _submitMcq(StudyOption option) async {
    if (_answered || _submitting) return;
    setState(() {
      _selectedOptionId = option.id;
      _submitting = true;
    });

    try {
      final result =
          await ref.read(milingoApiServiceProvider).submitStudyAnswer(
                deckId: _card.deckId,
                cardId: _card.cardId,
                mode: 'mcq',
                isCorrect: option.isCorrect,
              );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _answered = true;
        if (option.isCorrect) _correct++;
        _coins += result.coinsAwarded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectedOptionId = null;
      });
      _showError(error);
    }
  }

  Future<void> _submitFlashcard(int quality) async {
    if (_answered || _submitting) return;
    setState(() {
      _selectedQuality = quality;
      _submitting = true;
    });

    try {
      final result =
          await ref.read(milingoApiServiceProvider).submitStudyAnswer(
                deckId: _card.deckId,
                cardId: _card.cardId,
                mode: 'flashcard',
                quality: quality,
              );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _answered = true;
        if (quality >= 3) _correct++;
        _coins += result.coinsAwarded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectedQuality = null;
      });
      _showError(error);
    }
  }

  void _next() {
    if (_isLast) {
      _showResults();
      return;
    }

    setState(() {
      _current++;
      _answered = false;
      _revealed = false;
      _selectedOptionId = null;
      _selectedQuality = null;
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) return;
          _handleResultDialogPop();
        },
        child: _ResultDialog(
          correct: _correct,
          total: _cards.length,
          coins: _coins,
          onRetry: _retryResultSession,
          onExit: _goToReviewRoot,
        ),
      ),
    );
  }

  void _retryResultSession() {
    _closingResultDialogForRetry = true;
    Navigator.of(context).pop();
    _loadSession();
  }

  void _goToReviewRoot() {
    _closingResultDialogForReviewRoot = true;
    Navigator.of(context).pop();
    context.go(AppConstants.leaderboardRoute);
  }

  void _handleResultDialogPop() {
    if (_closingResultDialogForRetry) {
      _closingResultDialogForRetry = false;
      return;
    }
    if (_closingResultDialogForReviewRoot) {
      _closingResultDialogForReviewRoot = false;
      return;
    }
    context.go(AppConstants.leaderboardRoute);
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không gửi được câu trả lời: $error')),
    );
  }

  List<Widget> _buildBackgroundDecorators() {
    return [
      Positioned(
        right: -100,
        top: -64,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
          child: Container(
            width: 288,
            height: 288,
            decoration: BoxDecoration(
              color: const Color(0xFFF68A5C).withOpacity(0.20),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      Positioned(
        left: -96,
        top: 320,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
          child: Container(
            width: 256,
            height: 256,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8016).withOpacity(0.16),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: _loading || _error != null || _cards.isEmpty
            ? SafeArea(
                child: _loading
                    ? const _LoadingView()
                    : _error != null
                        ? _ErrorView(message: _error!, onRetry: _loadSession)
                        : _EmptyDueView(
                            deckName: _sessionTitle, onRetry: _loadSession),
              )
            : Stack(
                children: [
                  ..._buildBackgroundDecorators(),
                  SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        _buildProgressBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPromptCard(),
                                const SizedBox(height: 20),
                                _card.isMcq
                                    ? _buildMcqBody()
                                    : _buildFlashcardBody(),
                              ],
                            ),
                          ),
                        ),
                        _buildNextButton(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF1D1814),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _sessionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1D1814),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _modeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF9832), Color(0xFFE2442D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF641C).withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              '${_current + 1} / ${_cards.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_current + 1) / _cards.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Container(
          height: 8,
          width: double.infinity,
          color: Colors.black.withOpacity(0.06),
          child: Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                builder: (_, value, __) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF9832), Color(0xFFE2442D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard() {
    final hasImage = _card.imageUrl != null && _card.imageUrl!.isNotEmpty;
    final pr = _promptPronunciation;

    final decks = ref.watch(flashcardStateProvider).decks;
    final deck = decks.firstWhere(
      (d) => d.id == _card.deckId || d.name == _card.deckName,
      orElse: () => DeckData(id: '', name: '', emoji: '📚'),
    );
    final emojiStr = deck.emoji.isNotEmpty ? deck.emoji : '📚';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D1814).withOpacity(0.10),
            blurRadius: 44,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                _card.imageUrl!,
                width: double.infinity,
                height: 138,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildGradientEmojiBox(emojiStr),
              ),
            ),
          ] else ...[
            _buildGradientEmojiBox(emojiStr),
          ],
          const SizedBox(height: 20),
          Text(
            _promptText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1D1814),
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (pr.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              pr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF1D1814).withOpacity(0.55),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (_card.deckName.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF6B15C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                _card.deckName,
                style: const TextStyle(
                  color: Color(0xFFFF6A00),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradientEmojiBox(String emoji) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF9832), Color(0xFFDF462C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        emoji,
        style: const TextStyle(
          fontSize: 40,
        ),
      ),
    );
  }

  Widget _buildMcqBody() {
    final options = _card.options ?? const <StudyOption>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Center(
          child: Text(
            _promptInstruction,
            style: const TextStyle(
              color: Color(0xFF1D1814),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++)
          _McqOptionTile(
            option: options[i],
            prefixLetter: String.fromCharCode(65 + i),
            selected: _selectedOptionId == options[i].id,
            answered: _answered,
            disabled: _submitting,
            onTap: () => _submitMcq(options[i]),
          ),
      ],
    );
  }

  Widget _buildFlashcardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Bạn nhớ từ này đến mức nào?',
            style: TextStyle(
              color: Color(0xFF1D1814),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.black.withOpacity(0.06), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D1814).withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mặt sau',
                style: TextStyle(
                  color: Color(0xFF8E817A),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _revealed ? _card.translation : 'Nhấn để xem nghĩa',
                style: TextStyle(
                  color: _revealed
                      ? const Color(0xFF1D1814)
                      : const Color(0xFF8E817A),
                  fontSize: _revealed ? 24 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_revealed && _card.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _card.exampleSentence,
                  style: const TextStyle(
                    color: Color(0xFF8E817A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _speak,
                      icon: const Icon(Icons.volume_up_rounded,
                          size: 18, color: Color(0xFFFF6A00)),
                      label: const Text(
                        'Nghe',
                        style: TextStyle(
                          color: Color(0xFFFF6A00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFFFF6A00), width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _revealed
                          ? null
                          : () => setState(() => _revealed = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D1814),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF1D1814).withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lật thẻ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_revealed) _buildGradeButtons(),
      ],
    );
  }

  Widget _buildGradeButtons() {
    final grades = [
      (0, 'Lại', _kDanger),
      (2, 'Khó', const Color(0xFFE1A43B)),
      (4, 'Tốt', _kSuccess),
      (5, 'Dễ', _kAccent),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.45,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        for (final grade in grades)
          _GradeButton(
            quality: grade.$1,
            label: grade.$2,
            color: grade.$3,
            selected: _selectedQuality == grade.$1,
            answered: _answered,
            disabled: _submitting,
            onPressed: () => _submitFlashcard(grade.$1),
          ),
      ],
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      color: Colors.transparent,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _answered ? _next : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return const Color(0xFF1D1814).withOpacity(0.12);
              }
              return null;
            }),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: _answered
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8A1F), Color(0xFFFF4D1A)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              alignment: Alignment.center,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLast ? 'Xem kết quả' : 'Tiếp tục',
                          style: TextStyle(
                            color: _answered
                                ? Colors.white
                                : const Color(0xFF8E817A).withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _answered
                              ? Colors.white
                              : const Color(0xFF8E817A).withOpacity(0.6),
                          size: 13,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _McqOptionTile extends StatelessWidget {
  const _McqOptionTile({
    required this.option,
    required this.prefixLetter,
    required this.selected,
    required this.answered,
    required this.disabled,
    required this.onTap,
  });

  final StudyOption option;
  final String prefixLetter;
  final bool selected;
  final bool answered;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && option.isCorrect;
    final showWrong = answered && selected && !option.isCorrect;

    // Determine colors based on state
    Color tileBg;
    Color borderColor;
    Color textColor;
    Color letterBg;
    Color letterTextColor;

    if (showCorrect) {
      tileBg = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF2EAD62);
      textColor = const Color(0xFF2EAD62);
      letterBg = const Color(0xFF2EAD62);
      letterTextColor = Colors.white;
    } else if (showWrong) {
      tileBg = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFE14E43);
      textColor = const Color(0xFFE14E43);
      letterBg = const Color(0xFFE14E43);
      letterTextColor = Colors.white;
    } else if (selected && !answered) {
      tileBg = Colors.white;
      borderColor = const Color(0xFFFF6A00);
      textColor = const Color(0xFFFF6A00);
      letterBg = const Color(0xFFFF6A00);
      letterTextColor = Colors.white;
    } else {
      tileBg = Colors.white;
      borderColor = Colors.black.withOpacity(0.06);
      textColor = const Color(0xFF1D1814);
      letterBg = const Color(0xFFFF8016).withOpacity(0.12);
      letterTextColor = const Color(0xFFFF6A00);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: tileBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled || answered ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1D1814).withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Letter Prefix
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: letterBg,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    prefixLetter,
                    style: TextStyle(
                      color: letterTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option.term,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (showCorrect)
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2EAD62))
                else if (showWrong)
                  const Icon(Icons.cancel_rounded, color: Color(0xFFE14E43)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.quality,
    required this.label,
    required this.color,
    required this.selected,
    required this.answered,
    required this.disabled,
    required this.onPressed,
  });

  final int quality;
  final String label;
  final Color color;
  final bool selected;
  final bool answered;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = selected || (!answered && !disabled);
    return FilledButton(
      onPressed: answered || disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: selected ? color : color.withValues(alpha: 0.13),
        disabledBackgroundColor:
            selected ? color : color.withValues(alpha: active ? 0.13 : 0.08),
        foregroundColor: selected ? Colors.white : color,
        disabledForegroundColor: selected ? Colors.white : color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    );
  }
}


class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: _kAccent),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.error_outline_rounded,
      title: 'Không tải được phiên ôn tập',
      message: message,
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}

class _EmptyDueView extends StatelessWidget {
  const _EmptyDueView({required this.deckName, required this.onRetry});

  final String deckName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.check_circle_outline_rounded,
      title: 'Hôm nay đã xong',
      message: 'Không còn từ nào đến hạn trong "$deckName".',
      actionLabel: 'Tải lại',
      onAction: onRetry,
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: _kAccent, size: 46),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: _kAccent),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.correct,
    required this.total,
    required this.coins,
    required this.onRetry,
    required this.onExit,
  });

  final int correct;
  final int total;
  final int coins;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : correct / total;
    final title = ratio >= 0.85
        ? 'Quá tốt'
        : ratio >= 0.55
            ? 'Ổn định rồi'
            : 'Cứ tiếp tục nhé';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: Padding(
        padding: const EdgeInsets.all(26),
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
                    value: ratio,
                    strokeWidth: 10,
                    backgroundColor: _kBorder,
                    color: _kAccent,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      '${(ratio * 100).round()}%',
                      style: const TextStyle(
                        color: _kDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correct / $total câu tốt · +$coins xu',
              style: const TextStyle(
                color: _kMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onExit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kAccent,
                      side: const BorderSide(color: _kAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Về ôn tập'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Làm tiếp'),
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
