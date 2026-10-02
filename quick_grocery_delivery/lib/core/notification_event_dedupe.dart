import 'dart:async';
import 'dart:collection';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists processed notification [eventId]s across isolates and app restarts.
///
/// Suppresses duplicate tray entries when the same logical event is delivered
/// more than once (topic+token dual send, CF retry, multiple listeners, etc.).
class NotificationEventDedupe {
  NotificationEventDedupe._();

  static const _prefKey = 'processed_notification_ids';
  static const _maxIds = 500;
  static const _appTag = 'DeliveryNotify';
  static const _messageIdWindow = Duration(seconds: 30);

  static LinkedHashSet<String>? _cache;
  static Future<void>? _loadFuture;

  /// Serializes claim checks so concurrent handlers cannot both mark "new".
  static Future<void> _mutex = Future.value();

  /// Short window for raw FCM messageIds (covers dual delivery of copies).
  static final LinkedHashMap<String, DateTime> _recentMessageIds =
      LinkedHashMap<String, DateTime>();

  /// Prefer server [eventId]; else stable `orderId:type` (no timestamp —
  /// timestamps differ per duplicate FCM copy and would defeat dedupe).
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
  }) {
    final done = Completer<bool>();
    _mutex = _mutex.then((_) async {
      try {
        final isNew = await _markIfNewUnlocked(
          msg,
          source: source,
          listenerId: listenerId,
          deviceToken: deviceToken,
        );
        done.complete(isNew);
      } catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }

  static Future<bool> _markIfNewUnlocked(
    RemoteMessage msg, {
    required String source,
    required String listenerId,
    String? deviceToken,
  }) async {
    await _ensureLoaded();
    final eventId = resolveEventId(msg);
    final messageId = msg.messageId?.trim() ?? '';

    _pruneRecentMessageIds();
    final midDuplicate = messageId.isNotEmpty &&
        _recentMessageIds.containsKey(messageId);
    final alreadyProcessed = _cache!.contains(eventId) || midDuplicate;

    _log(
      eventId: eventId,
      alreadyProcessed: alreadyProcessed,
      source: source,
      listenerId: listenerId,
      deviceToken: deviceToken,
      messageId: msg.messageId,
      orderId: msg.data['orderId']?.toString(),
      type: msg.data['type']?.toString(),
    );

    if (alreadyProcessed) return false;

    _cache!.add(eventId);
    while (_cache!.length > _maxIds) {
      _cache!.remove(_cache!.first);
    }
    if (messageId.isNotEmpty) {
      _recentMessageIds[messageId] = DateTime.now();
    }
    await _persist();
    return true;
  }

  static void _pruneRecentMessageIds() {
    final cutoff = DateTime.now().subtract(_messageIdWindow);
    _recentMessageIds.removeWhere((_, at) => at.isBefore(cutoff));
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

  static void _log({
    required String eventId,
    required bool alreadyProcessed,
    required String source,
    required String listenerId,
    String? deviceToken,
    String? messageId,
    String? orderId,
    String? type,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[$_appTag] Notification received '
      'eventId=$eventId '
      'alreadyProcessed=$alreadyProcessed '
      'source=$source '
      'listenerId=$listenerId '
      'messageId=${messageId ?? "—"} '
      'orderId=${orderId ?? "—"} '
      'type=${type ?? "—"} '
      'token=${deviceToken ?? "—"} '
      'time=${DateTime.now().toIso8601String()}',
    );
  }
}
