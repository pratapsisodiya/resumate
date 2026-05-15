enum MessageRole { user, assistant }

class Message {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;

  const Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  Message copyWith({String? content, bool? isStreaming}) => Message(
        id: id,
        role: role,
        content: content ?? this.content,
        timestamp: timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isStreaming': isStreaming,
      };

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String? ?? '',
        role: MessageRole.values.firstWhere(
          (r) => r.name == (j['role'] as String?),
          orElse: () => MessageRole.user,
        ),
        content: j['content'] as String? ?? '',
        timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
        isStreaming: j['isStreaming'] as bool? ?? false,
      );
}
