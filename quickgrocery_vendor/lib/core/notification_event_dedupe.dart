import 'dart:collection';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists processed notification [eventId]s across isolates and app restarts.
///
/// Prevents the same logical order event from creating two tray entries when
/// FCM is delivered more than once (topic retry, dual listener, etc.).
class NotificationEventDedupe {
  NotificationEventDedupe._();

  static const _prefKey = 'processed_notification_ids';
  static const _maxIds = 500;
  static const _appTag = 'VendorNotify';

  static LinkedHashSet<String>? _cache;
  static Future<void>? _loadFuture;

  /// Prefer server [eventId]; else stable `orderId:type` (no timestamp — timestamps
  /// differ per duplicate FCM copy and would defeat dedupe).
  static String resolveEventId(RemoteMessage msg) {
    final data = msg.data;
    final fromServer = data['eventId']?.toString().trim();
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;

    final orderId = data['orderId']?.toString().trim() ?? '';
    final type = data['type']?.toString().trim() ?? '';
    if (orderId.isNotEmpty && type.isNotEmpty) {
      return '$orderId:$type';
    }

    final messageId = msg.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) return 'mid:$messageId';
    return 'hash:${msg.hashCode}';
  }

  /// Returns false when this event was already processed.
  static Future<bool> markIfNew(
    RemoteMessage msg, {
    required String source,
    String listenerId = 'default',
    String? deviceToken,
  }) async {
    await _ensureLoaded();
    final eventId = resolveEventId(msg);
    final alreadyProcessed = _cache!.contains(eventId);

    if (kDebugMode) {
      debugPrint(
        '[$_appTag][EventDedupe] '
        'eventId=$eventId '
        'alreadyProcessed=$alreadyProcessed '
        'source=$source '
        'listenerId=$listenerId '
        'messageId=${msg.messageId ?? "—"} '
        'orderId=${msg.data['orderId'] ?? "—"} '
        'type=${msg.data['type'] ?? "—"} '
        'vendorReceiver=${msg.data['eventId'] ?? "—"}',
      );
    }

    if (alreadyProcessed) return false;

    _cache!.add(eventId);
    while (_cache!.length > _maxIds) {
      _cache!.remove(_cache!.first);
    }
    await _persist();
    return true;
  }

  static Future<void> _ensureLoaded() {
    _loadFuture ??= _load();
    return _loadFuture!;
  }

  static Future<void> _load() async {
    if (_cache != null) return;
    _cache = LinkedHashSet<String>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefKey);
      if (raw != null) {
        for (final id in raw) {
          if (id.isNotEmpty) _cache!.add(id);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_appTag][EventDedupe] load failed: $e');
      }
    }
  }

  static Future<void> _persist() async {
    if (_cache == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, _cache!.toList(growable: false));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$_appTag][EventDedupe] persist failed: $e');
      }
    }
  }
}
