import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:milingo/core/network/milingo_api_service.dart';
import 'package:milingo/core/theme/app_theme.dart';

const _kBg = Color(0xFFFFF8F4);
const _kSurface = Colors.white;
const _kAccent = AppTheme.primaryColor;
const _kDark = Color(0xFF1F1B18);
const _kMuted = Color(0xFF8E817A);
const _kBorder = Color(0xFFF0E4DE);
const _kSoft = Color(0xFFFFEDE7);
const _kSuccess = Color(0xFF2EAD62);
const _kDanger = Color(0xFFE14E43);

const _kTtsLocales = {
  'en': 'en-US',
  'vi': 'vi-VN',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'zh': 'zh-CN',
  'fr': 'fr-FR',
  'es': 'es-ES',
  'de': 'de-DE',
};

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
    await _tts.setLanguage(_kTtsLocales[widget.langCode] ?? 'en-US');
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
      builder: (_) => _ResultDialog(
        correct: _correct,
        total: _cards.length,
        coins: _coins,
        onRetry: () {
          Navigator.of(context).pop();
          _loadSession();
        },
        onExit: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Không gửi được câu trả lời: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: _loading
              ? const _LoadingView()
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadSession)
                  : _cards.isEmpty
                      ? _EmptyDueView(
                          deckName: _sessionTitle, onRetry: _loadSession)
                      : Column(
                          children: [
                            _buildTopBar(),
                            _buildProgressBar(),
                            Expanded(
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 14, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildPromptCard(),
                                    const SizedBox(height: 18),
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
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Thoát',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: _kMuted),
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
                    color: _kDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _kDark,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '+$_coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Câu ${_current + 1}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kDark,
                ),
              ),
              Text(
                ' / ${_cards.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                ),
              ),
              const Spacer(),
              _ModeChip(label: _srsLabel(_card.srsState)),
            ],
          ),
          const SizedBox(height: 9),
          _SrsStudyLine(card: _card),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: _kBorder,
                color: _kAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard() {
    final hasImage = _card.imageUrl != null && _card.imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 214),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                _card.imageUrl!,
                width: double.infinity,
                height: 138,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackPromptIcon(
                  isMcq: _card.isMcq,
                ),
              ),
            )
          else
            _FallbackPromptIcon(isMcq: _card.isMcq),
          const SizedBox(height: 16),
          Text(
            _card.isMcq ? _card.translation : _card.term,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          if (_card.pronunciation.isNotEmpty && !_card.isMcq) ...[
            const SizedBox(height: 6),
            Text(
              _card.pronunciation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMcqBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn từ đúng',
          style: TextStyle(
            color: _kDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dựa vào hình ảnh hoặc nghĩa gợi ý ở trên.',
          style: TextStyle(
            color: _kMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        for (final option in _card.options ?? const <StudyOption>[])
          _McqOptionTile(
            option: option,
            selected: _selectedOptionId == option.id,
            answered: _answered,
            disabled: _submitting,
            onTap: () => _submitMcq(option),
          ),
      ],
    );
  }

  Widget _buildFlashcardBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bạn nhớ từ này đến mức nào?',
          style: TextStyle(
            color: _kDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mặt sau',
                style: TextStyle(
                  color: _kMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _revealed ? _card.translation : 'Nhấn để xem nghĩa',
                style: TextStyle(
                  color: _revealed ? _kDark : _kMuted,
                  fontSize: _revealed ? 24 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_revealed && _card.exampleSentence.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _card.exampleSentence,
                  style: const TextStyle(
                    color: _kMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _speak,
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text('Nghe'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _revealed
                          ? null
                          : () => setState(() => _revealed = true),
                      style: FilledButton.styleFrom(backgroundColor: _kDark),
                      child: const Text('Lật thẻ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_revealed) _buildGradeButtons(),
      ],
    );
  }

  Widget _buildGradeButtons() {
    const grades = [
      (0, 'Lại', _kDanger),
      (2, 'Khó', Color(0xFFE1A43B)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: _answered ? _next : null,
          style: FilledButton.styleFrom(
            backgroundColor: _kDark,
            disabledBackgroundColor: _kDark.withValues(alpha: 0.25),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _isLast ? 'Xem kết quả' : 'Câu tiếp theo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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
    required this.selected,
    required this.answered,
    required this.disabled,
    required this.onTap,
  });

  final StudyOption option;
  final bool selected;
  final bool answered;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && option.isCorrect;
    final showWrong = answered && selected && !option.isCorrect;
    final color = showCorrect
        ? _kSuccess
        : showWrong
            ? _kDanger
            : _kDark;
    final bg = showCorrect
        ? _kSuccess.withValues(alpha: 0.12)
        : showWrong
            ? _kDanger.withValues(alpha: 0.1)
            : _kSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: disabled || answered ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: showCorrect || showWrong ? color : _kBorder,
                width: showCorrect || showWrong ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.term,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showCorrect)
                  const Icon(Icons.check_circle_rounded, color: _kSuccess)
                else if (showWrong)
                  const Icon(Icons.cancel_rounded, color: _kDanger)
                else
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _kMuted,
                  ),
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

class _SrsStudyLine extends StatelessWidget {
  const _SrsStudyLine({required this.card});

  final StudyCard card;

  @override
  Widget build(BuildContext context) {
    final nextInterval = card.srsIntervalDays <= 0
        ? 'đến hạn'
        : 'chu kỳ ${card.srsIntervalDays} ngày';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStudyBadge(
          icon: _srsIcon(card.srsState),
          label: _srsLabel(card.srsState),
        ),
        _MiniStudyBadge(
          icon: Icons.repeat_rounded,
          label: '${card.srsRepetitions} lần ôn',
        ),
        _MiniStudyBadge(
          icon: Icons.schedule_rounded,
          label: nextInterval,
        ),
        if (card.deckName.isNotEmpty)
          _MiniStudyBadge(
            icon: Icons.folder_rounded,
            label: card.deckName,
          ),
      ],
    );
  }
}

class _MiniStudyBadge extends StatelessWidget {
  const _MiniStudyBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _kAccent, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _srsLabel(String state) {
  return switch (state) {
    'learning' => 'Đang học',
    'review' => 'Ôn tập',
    'mastered' => 'Đã vững',
    _ => 'Mới',
  };
}

IconData _srsIcon(String state) {
  return switch (state) {
    'learning' => Icons.sync_rounded,
    'review' => Icons.event_available_rounded,
    'mastered' => Icons.verified_rounded,
    _ => Icons.bolt_rounded,
  };
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kAccent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FallbackPromptIcon extends StatelessWidget {
  const _FallbackPromptIcon({required this.isMcq});

  final bool isMcq;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(
        isMcq ? Icons.quiz_rounded : Icons.style_rounded,
        color: Colors.white,
        size: 48,
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
                    child: const Text('Thoát'),
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
