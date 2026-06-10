import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Prevents processing/displaying the same FCM message more than once.
class PushMessageDedupe {
  PushMessageDedupe._();

  static final Map<String, DateTime> _seen = {};
  static const _ttl = Duration(minutes: 3);

  static void _prune() {
    final now = DateTime.now();
    _seen.removeWhere((_, at) => now.difference(at) > _ttl);
  }

  /// Returns false when this message was already handled recently.
  static bool markIfNew(RemoteMessage msg, {required String appTag}) {
    _prune();
    final now = DateTime.now();

    final messageId = msg.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      final key = 'mid:$messageId';
      if (_seen.containsKey(key)) {
        _log(appTag, 'skip duplicate messageId=$messageId');
        return false;
      }
      _seen[key] = now;
    }

    final data = msg.data;
    final orderId = data['orderId']?.toString().trim() ?? '';
    final type = data['type']?.toString().trim() ?? '';
    if (orderId.isNotEmpty && type.isNotEmpty) {
      final key = 'evt:$orderId:$type';
      if (_seen.containsKey(key)) {
        _log(appTag, 'skip duplicate event orderId=$orderId type=$type');
        return false;
      }
      _seen[key] = now;
    }

    _log(
      appTag,
      'accept messageId=${msg.messageId ?? "—"} '
      'orderId=${orderId.isEmpty ? "—" : orderId} '
      'type=${type.isEmpty ? "—" : type}',
    );
    return true;
  }

  static void _log(String appTag, String message) {
    if (kDebugMode) {
      debugPrint('[$appTag][PushDedupe] $message');
    }
  }
}
