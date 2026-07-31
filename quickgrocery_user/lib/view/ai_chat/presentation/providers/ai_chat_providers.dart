import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/startup/shared_preferences_provider.dart';
import 'package:quickgrocery/view/ai_chat/data/ai_chat_api.dart';
import 'package:quickgrocery/view/ai_chat/data/ai_chat_local_store.dart';
import 'package:quickgrocery/view/ai_chat/data/ai_chat_remote_store.dart';
import 'package:quickgrocery/view/ai_chat/models/ai_chat_models.dart';

final aiChatApiProvider = Provider<AiChatApi>((ref) => AiChatApi());

final aiChatLocalStoreProvider = Provider<AiChatLocalStore>((ref) {
  return AiChatLocalStore(ref.watch(sharedPreferencesProvider));
});

final aiChatRemoteStoreProvider = Provider<AiChatRemoteStore>((ref) {
  return AiChatRemoteStore();
});

class AiChatState {
  const AiChatState({
    required this.sessionId,
    required this.messages,
    this.isTyping = false,
    this.sending = false,
  });

  final String sessionId;
  final List<AiChatMessage> messages;
  final bool isTyping;
  final bool sending;

  AiChatState copyWith({
    String? sessionId,
    List<AiChatMessage>? messages,
    bool? isTyping,
    bool? sending,
  }) {
    return AiChatState(
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      sending: sending ?? this.sending,
    );
  }
}

class AiChatController extends Notifier<AiChatState> {
  final _rng = Random();

  String _newId() =>
      'm_${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(9999)}';

  AiChatApi get _api => ref.read(aiChatApiProvider);
  AiChatLocalStore get _store => ref.read(aiChatLocalStoreProvider);
  AiChatRemoteStore get _remote => ref.read(aiChatRemoteStoreProvider);

  @override
  AiChatState build() {
    final store = ref.watch(aiChatLocalStoreProvider);
    final sessionId = store.getOrCreateSessionId();
    final saved = store.loadMessages();
    if (saved.isEmpty) {
      return AiChatState(
        sessionId: sessionId,
        messages: [_welcome()],
      );
    }
    return AiChatState(sessionId: sessionId, messages: saved);
  }

  AiChatMessage _welcome() {
    return AiChatMessage(
      id: 'welcome',
      role: AiChatRole.assistant,
      text:
          "Hi! I'm your QuickGrocery assistant. Ask me about products, offers, delivery, coupons, or your recent orders.",
      createdAt: DateTime.now(),
      quickReplies: const [
        "Any discounts today?",
        "Do you have Amul Milk?",
        "Suggest breakfast items",
        "Where is my order?",
      ],
      intent: 'general',
      source: 'local',
    );
  }

  Future<void> clearChat() async {
    await _store.resetSession();
    state = AiChatState(
      sessionId: _store.getOrCreateSessionId(),
      messages: [_welcome()],
    );
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.sending) return;

    final userMsg = AiChatMessage(
      id: _newId(),
      role: AiChatRole.user,
      text: text,
      createdAt: DateTime.now(),
      status: AiChatStatus.sent,
    );

    final historyForApi = [
      ...state.messages.where((m) => m.id != 'welcome'),
      userMsg,
    ];

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      sending: true,
      isTyping: true,
    );
    await _persist();

    try {
      final res = await _api.send(
        message: text,
        sessionId: state.sessionId,
        history: historyForApi
            .where((m) => m.id != 'welcome')
            .where((m) => m.role != AiChatRole.system)
            .toList(),
      );

      final assistant = AiChatMessage(
        id: _newId(),
        role: AiChatRole.assistant,
        text: res.reply,
        createdAt: DateTime.now(),
        status: AiChatStatus.sent,
        productIds: res.productIds,
        quickReplies: res.quickReplies,
        intent: res.intent,
        source: res.source,
      );

      state = state.copyWith(
        messages: [...state.messages, assistant],
        sending: false,
        isTyping: false,
      );
      await _persist();
      // Mirror to Firestore so Admin → AI Chat Inbox shows this session.
      // Cloud Function also persists; this is a best-effort backup.
      await _remote.persistTurn(
        sessionId: state.sessionId,
        userMessage: text,
        reply: res.reply,
        productIds: res.productIds,
        quickReplies: res.quickReplies,
        intent: res.intent,
        source: res.source,
        latencyMs: res.latencyMs,
      );
    } on AiChatApiException catch (e) {
      final err = AiChatMessage(
        id: _newId(),
        role: AiChatRole.assistant,
        text: e.message,
        createdAt: DateTime.now(),
        status: AiChatStatus.error,
        errorLabel: e.code,
        quickReplies: const ['Try again', 'Browse offers', 'Find milk'],
      );
      state = state.copyWith(
        messages: [...state.messages, err],
        sending: false,
        isTyping: false,
      );
      await _persist();
    } catch (_) {
      final err = AiChatMessage(
        id: _newId(),
        role: AiChatRole.assistant,
        text: 'Something went wrong. Please try again.',
        createdAt: DateTime.now(),
        status: AiChatStatus.error,
        quickReplies: const ['Try again'],
      );
      state = state.copyWith(
        messages: [...state.messages, err],
        sending: false,
        isTyping: false,
      );
      await _persist();
    }
  }

  Future<void> _persist() async {
    await _store.saveMessages(
      state.messages.where((m) => m.status != AiChatStatus.sending).toList(),
    );
  }
}

final aiChatControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);
