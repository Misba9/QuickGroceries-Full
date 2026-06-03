import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent search queries locally (max 10).
abstract final class SearchHistoryStore {
  static const _key = 'search_history_queries';
  static const _max = 10;

  static Future<List<String>> read() async {
    final pref = await SharedPreferences.getInstance();
    final raw = pref.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return;
    final existing = await read();
    final next = [
      trimmed,
      ...existing.where((e) => e.toLowerCase() != trimmed.toLowerCase()),
    ].take(_max).toList();
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_key, jsonEncode(next));
  }

  static Future<void> clear() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_key);
  }
}
