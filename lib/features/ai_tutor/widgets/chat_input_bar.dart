import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            color: widget.isLimitReached ? Colors.grey.shade300 : Colors.transparent,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1D1814).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
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
                        : 'Nhập tin nhắn...',
                    hintStyle: TextStyle(
                      color: widget.isLimitReached ? Colors.grey.shade400 : _kHintText,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    counterText: '', // hide character counter
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),

            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF8A1F), Color(0xFFFF6A00)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF6A00),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: (_hasText && isEnabled) ? _submit : null,
                      child: Opacity(
                        opacity: (_hasText && isEnabled) ? 1.0 : 0.5,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Transform.translate(
                            offset: const Offset(0.0, 6.05),
                            child: OverflowBox(
                              minWidth: 79.2,
                              maxWidth: 79.2,
                              minHeight: 73.7,
                              maxHeight: 73.7,
                              child: SvgPicture.asset(
                                'assets/svg/send-message.svg',
                                fit: BoxFit.fill,
                              ),
                            ),
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
