import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resumate/data/genkit_client.dart';
import 'package:resumate/data/local_storage.dart';
import 'package:resumate/models/message.dart';
import 'package:resumate/models/resume.dart';
import 'package:resumate/providers/resume_provider.dart';
import 'package:uuid/uuid.dart';

class ChatState {
  final List<Message> messages;
  final bool isStreaming;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isStreaming = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isStreaming,
    String? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        error: error,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final GenKitClient _genKit;
  final LocalStorage _storage;

  ChatNotifier(this._genKit, this._storage) : super(const ChatState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.loadChat();
      if (raw != null) {
        final list = (raw['messages'] as List? ?? [])
            .map((m) => Message.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList();
        state = state.copyWith(messages: list);
      }
    } catch (_) {}
  }

  Future<void> send(String text, {Resume? resume}) async {
    final userMsg = Message(
      id: const Uuid().v4(),
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isStreaming: true,
      error: null,
    );

    try {
      final history = state.messages
          .where((m) => m.id != userMsg.id)
          .map((m) => {'role': m.role.name, 'content': m.content})
          .toList();

      final reply = await _genKit.sendChatMessage(
        text,
        history,
        resumeContext: resume?.toJson(),
      );

      final assistantMsg = Message(
        id: const Uuid().v4(),
        role: MessageRole.assistant,
        content: reply,
        timestamp: DateTime.now(),
      );
      final updated = [...state.messages, assistantMsg];
      state = state.copyWith(messages: updated, isStreaming: false);
      await _persist(updated);
    } catch (e) {
      state = state.copyWith(isStreaming: false, error: e.toString());
    }
  }

  Future<void> clear() async {
    state = const ChatState();
    await _storage.saveChat({'messages': []});
  }

  Future<void> _persist(List<Message> messages) async {
    await _storage.saveChat({
      'messages': messages.map((m) => m.toJson()).toList(),
    });
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(
    ref.watch(genKitClientProvider),
    ref.watch(localStorageProvider),
  ),
);
