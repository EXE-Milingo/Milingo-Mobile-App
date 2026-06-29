// ─────────────────────────────────────────────────────────
//  AI Tutor — Chat Message Model
// ─────────────────────────────────────────────────────────

enum ChatRole { user, assistant }

class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final ChatRole role;
  final String content;
  final DateTime timestamp;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  /// Converts to the history format expected by the backend.
  Map<String, dynamic> toJson() => {
        'role': role == ChatRole.user ? 'user' : 'assistant',
        'content': content,
      };
}
