import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';
import 'package:milingo/features/flashcards/models/flashcard_models.dart';

const _kAccentLight = Color(0xFFFFF0EB);

/// Bottom sheet that lets the user save a word to an existing deck
/// or create a new deck on the spot.
class SaveFlashcardSheet extends ConsumerStatefulWidget {
  const SaveFlashcardSheet({super.key, required this.entry});
  final FlashcardEntry entry;

  @override
  ConsumerState<SaveFlashcardSheet> createState() =>
      _SaveFlashcardSheetState();
}

class _SaveFlashcardSheetState extends ConsumerState<SaveFlashcardSheet> {
  bool _creatingNew = false;
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '📚';
  String? _savedToDeckName;
  bool _isBusy = false;

  static const _kEmojiOptions = [
    '📚', '⭐', '🎯', '🔥', '💡', '🌟', '📝', '🎓', '🗂️', '🧠',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the async provider — fall back to empty state while loading
    final asyncState = ref.watch(flashcardProvider);
    final state = asyncState.valueOrNull ?? FlashcardState(decks: const []);
    final notifier = ref.read(flashcardProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kAccentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bookmark_add_rounded,
                    color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lưu vào Flashcard',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '"${widget.entry.english}"  →  ${widget.entry.translation}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (_savedToDeckName != null)
            _buildSuccessState()
          else if (_creatingNew)
            _buildCreateNewDeck(notifier)
          else
            _buildDeckList(state, notifier),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đã lưu vào bộ thẻ "$_savedToDeckName" ✓',
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckList(FlashcardState state, FlashcardNotifier notifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: state.decks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 2),
            itemBuilder: (_, i) {
              final deck = state.decks[i];
              final alreadySaved = deck.cards.any(
                (c) =>
                    c.english.toLowerCase() ==
                        widget.entry.english.toLowerCase() &&
                    c.langCode == widget.entry.langCode,
              );
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kAccentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(deck.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                title: Text(deck.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                subtitle: Text('${deck.total} từ',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
                trailing: alreadySaved
                    ? const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 22)
                    : (_isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.add_circle_outline_rounded,
                            color: AppTheme.primaryColor, size: 22)),
                onTap: alreadySaved || _isBusy
                    ? null
                    : () => _saveToExistingDeck(notifier, deck),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _creatingNew = true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text('Tạo bộ thẻ mới',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveToExistingDeck(
      FlashcardNotifier notifier, DeckData deck) async {
    setState(() => _isBusy = true);
    try {
      final added = await notifier.addCardToDeck(deck.id, widget.entry);
      if (!mounted) return;
      if (added) {
        setState(() {
          _savedToDeckName = deck.name;
          _isBusy = false;
        });
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.of(context).pop();
        });
      } else {
        // Card already exists in this deck
        setState(() => _isBusy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Từ này đã có trong bộ thẻ rồi!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      final msg = e.toString().contains('MilingoApiException')
          ? e.toString().split(': ').last
          : 'Không thể lưu. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildCreateNewDeck(FlashcardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _creatingNew = false),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Quay lại',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tên bộ thẻ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555))),
        const SizedBox(height: 8),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'VD: Từ vựng du lịch...',
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Chọn biểu tượng',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555))),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kEmojiOptions
              .map((e) => GestureDetector(
                    onTap: () => setState(() => _selectedEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _selectedEmoji == e
                            ? _kAccentLight
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedEmoji == e
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _creatingNew = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('Huỷ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666))),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _isBusy ? null : () => _createDeckAndSave(notifier),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppTheme.primaryColor,
                      const Color(0xFFf5a97a)
                    ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Tạo & Lưu',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _createDeckAndSave(FlashcardNotifier notifier) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      await notifier.addDeck(name, _selectedEmoji);
      // The newly created deck is the last one in the list
      final newDeck = ref.read(flashcardProvider).valueOrNull?.decks.last;
      if (newDeck != null) {
        await notifier.addCardToDeck(newDeck.id, widget.entry);
        if (mounted) {
          setState(() {
            _creatingNew = false;
            _savedToDeckName = name;
            _isBusy = false;
          });
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      } else {
        if (mounted) setState(() => _isBusy = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      final msg = e.toString().contains('MilingoApiException')
          ? e.toString().split(': ').last
          : 'Không thể tạo bộ thẻ. Vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}