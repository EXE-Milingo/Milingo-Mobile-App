import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milingo/core/theme/app_theme.dart';
import 'package:milingo/features/flashcards/providers/flashcard_provider.dart';

class CreateDeckSheet extends ConsumerStatefulWidget {
  const CreateDeckSheet({super.key});

  @override
  ConsumerState<CreateDeckSheet> createState() => _CreateDeckSheetState();
}

class _CreateDeckSheetState extends ConsumerState<CreateDeckSheet> {
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
        SnackBar(content: Text('Không tạo được bộ từ: $error')),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: const Color(0xFFE8E1DD),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tạo bộ từ',
              style: TextStyle(
                color: Color(0xFF1D1814),
                fontSize: 22,
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
                    selectedColor: const Color(0xFFFFECE6),
                    checkmarkColor: AppTheme.primaryColor,
                    side: BorderSide(
                      color: _selectedEmoji == emoji
                          ? AppTheme.primaryColor
                          : const Color(0xFFE8E1DD),
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
                labelText: 'Tên bộ từ',
                hintText: 'Từ vựng du lịch',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionCtrl,
              minLines: 1,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Không bắt buộc',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
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
                        'Tạo bộ từ',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
