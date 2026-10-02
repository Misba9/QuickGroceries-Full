import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/view/ai_chat/models/ai_chat_models.dart';

/// Persists the current AI session locally so reopen restores history.
class AiChatLocalStore {
  AiChatLocalStore(this._prefs);

  static const _messagesKey = 'ai_chat_messages_v1';
  static const _sessionKey = 'ai_chat_session_v1';
  static const _maxStored = 80;

  final SharedPreferences _prefs;

  String getOrCreateSessionId() {
    final existing = _prefs.getString(_sessionKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    _prefs.setString(_sessionKey, id);
    return id;
  }

  Future<void> resetSession() async {
    final id = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString(_sessionKey, id);
    await _prefs.remove(_messagesKey);
  }

  List<AiChatMessage> loadMessages() {
    final raw = _prefs.getString(_messagesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => AiChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .where((m) => m.text.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveMessages(List<AiChatMessage> messages) async {
    final slice = messages.length > _maxStored
        ? messages.sublist(messages.length - _maxStored)
        : messages;
    final encoded = jsonEncode(slice.map((m) => m.toJson()).toList());
    await _prefs.setString(_messagesKey, encoded);
  }
}
