import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
//  Chat Input Bar — Pill-shaped, frosted glass style
// ─────────────────────────────────────────────────────────

const _kBorderColor = Color(0xFFE8DDD4);
const _kSendActive = Color(0xFFFF6A00);
const _kSendInactive = Color(0xFFD0C4BC);
const _kHintText = Color(0xFFBBAFA8);
const _kInputText = Color(0xFF1D1814);

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    required this.onSend,
    required this.isLoading,
    this.isLimitReached = false,
    super.key,
  });

  final void Function(String text) onSend;
  final bool isLoading;
  final bool isLimitReached;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading || widget.isLimitReached) return;
    _controller.clear();
    setState(() => _hasText = false);
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isEnabled = !widget.isLoading && !widget.isLimitReached;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: _kBorderColor.withValues(alpha: 0.6)),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isLimitReached ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: widget.isLimitReached ? Colors.grey.shade300 : _kBorderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D1814).withValues(alpha: 0.10),
              blurRadius: 24,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 8, 4),
                child: TextField(
                  controller: _controller,
                  enabled: isEnabled,
                  maxLines: 5,
                  minLines: 1,
                  maxLength: 500,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    color: widget.isLimitReached ? Colors.grey.shade500 : _kInputText,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.isLimitReached
                        ? 'Đã hết lượt nhắn tin miễn phí.'
                        : 'Hỏi AI Tutor điều gì đó...',
                    hintStyle: TextStyle(
                      color: widget.isLimitReached ? Colors.grey.shade400 : _kHintText,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    counterText: '', // hide character counter
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),

            // Send button
            Padding(
              padding: const EdgeInsets.all(5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _hasText && isEnabled
                      ? _kSendActive
                      : _kSendInactive,
                  shape: BoxShape.circle,
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: (_hasText && isEnabled) ? _submit : null,
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
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
