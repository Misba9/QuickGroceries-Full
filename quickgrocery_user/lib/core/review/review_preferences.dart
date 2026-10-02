import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for order-experience review prompts.
///
/// Tracks:
/// - [reviewedOrders] — submitted a rating for this order (never ask again)
/// - [dismissedOrders] — tapped "No Thanks" (never ask again for that order)
/// - [laterReminders] — tapped "Later"; re-prompt after the reminder window
/// - [lastStoreReviewRequestDate] — throttle native store review requests
class ReviewPreferences {
  ReviewPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _kReviewed = 'order_review_reviewed_ids';
  static const _kDismissed = 'order_review_dismissed_ids';
  static const _kLaterMap = 'order_review_later_map';
  static const _kLastStoreMs = 'order_review_last_store_request_ms';

  factory ReviewPreferences.fromInstance(SharedPreferences prefs) =>
      ReviewPreferences(prefs);

  static Future<ReviewPreferences> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ReviewPreferences(prefs);
  }

  // ── read helpers ───────────────────────────────────────────────────

  Set<String> get reviewedOrders => _readIdSet(_kReviewed);

  Set<String> get dismissedOrders => _readIdSet(_kDismissed);

  Map<String, DateTime> get laterReminders => _readLaterMap();

  DateTime? get lastStoreReviewRequestDate {
    final ms = _prefs.getInt(_kLastStoreMs);
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool isReviewed(String orderId) => reviewedOrders.contains(orderId);

  bool isDismissed(String orderId) => dismissedOrders.contains(orderId);

  /// Whether this order is eligible for a prompt under local rules.
  bool canPromptOrder(String orderId, {required Duration laterReminder}) {
    if (orderId.isEmpty) return false;
    if (isReviewed(orderId) || isDismissed(orderId)) return false;

    final laterAt = laterReminders[orderId];
    if (laterAt != null) {
      final readyAt = laterAt.add(laterReminder);
      if (DateTime.now().isBefore(readyAt)) {
        if (kDebugMode) {
          debugPrint(
            '[OrderReview] later snooze active for $orderId until $readyAt',
          );
        }
        return false;
      }
    }
    return true;
  }

  bool canRequestStoreReview({required Duration cooldown}) {
    final last = lastStoreReviewRequestDate;
    if (last == null) return true;
    final elapsed = DateTime.now().difference(last);
    final ok = elapsed >= cooldown;
    if (!ok && kDebugMode) {
      debugPrint(
        '[OrderReview] store review cooldown — next in '
        '${cooldown - elapsed}',
      );
    }
    return ok;
  }

  // ── write helpers ──────────────────────────────────────────────────

  Future<void> markReviewed(String orderId) async {
    final next = {...reviewedOrders, orderId};
    await _writeIdSet(_kReviewed, next);
    await _clearLater(orderId);
  }

  Future<void> markDismissed(String orderId) async {
    final next = {...dismissedOrders, orderId};
    await _writeIdSet(_kDismissed, next);
    await _clearLater(orderId);
  }

  Future<void> markLater(String orderId) async {
    final map = laterReminders;
    map[orderId] = DateTime.now();
    await _writeLaterMap(map);
  }

  Future<void> markStoreReviewRequested() async {
    await _prefs.setInt(
      _kLastStoreMs,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Test / debug helper.
  Future<void> clearAll() async {
    await _prefs.remove(_kReviewed);
    await _prefs.remove(_kDismissed);
    await _prefs.remove(_kLaterMap);
    await _prefs.remove(_kLastStoreMs);
  }

  // ── private serialization ──────────────────────────────────────────

  Set<String> _readIdSet(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).where((s) => s.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _writeIdSet(String key, Set<String> ids) async {
    await _prefs.setString(key, jsonEncode(ids.toList()));
  }

  Map<String, DateTime> _readLaterMap() {
    final raw = _prefs.getString(_kLaterMap);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, DateTime>{};
      map.forEach((k, v) {
        final ms = v is int ? v : int.tryParse(v.toString());
        if (ms != null && ms > 0) {
          out[k] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeLaterMap(Map<String, DateTime> map) async {
    final encoded = <String, int>{
      for (final e in map.entries) e.key: e.value.millisecondsSinceEpoch,
    };
    await _prefs.setString(_kLaterMap, jsonEncode(encoded));
  }

  Future<void> _clearLater(String orderId) async {
    final map = laterReminders;
    if (!map.containsKey(orderId)) return;
    map.remove(orderId);
    await _writeLaterMap(map);
  }
}
