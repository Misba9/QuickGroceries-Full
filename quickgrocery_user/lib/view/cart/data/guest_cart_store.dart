import 'dart:convert';
import 'dart:isolate';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:quickgrocery/view/cart/domain/cart_models.dart';

/// Local-only cart persistence for guest browsing sessions.
abstract final class GuestCartStore {
  static const _key = 'guest_cart_items_v1';
  static const _isolateThreshold = 8;

  static Future<void> saveItems(
    SharedPreferences prefs,
    List<CartItem> items,
  ) async {
    if (items.isEmpty) {
      await clear(prefs);
      return;
    }
    final maps = items.map((e) => e.toMap()).toList(growable: false);
    final encoded = maps.length < _isolateThreshold
        ? jsonEncode(maps)
        : await Isolate.run(() => jsonEncode(maps));
    await prefs.setString(_key, encoded);
  }

  static Future<List<CartItem>> loadItems(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = raw.length < 2048
          ? jsonDecode(raw) as List<dynamic>
          : await Isolate.run(() => jsonDecode(raw) as List<dynamic>);
      return list
          .map(
            (e) => CartItem.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_key);
  }
}
