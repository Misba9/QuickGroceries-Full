import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_event_dedupe.dart';

/// Prevents processing/displaying the same FCM message more than once.
class PushMessageDedupe {
  PushMessageDedupe._();

  /// Returns false when this message was already handled recently.
  static Future<bool> markIfNew(
    RemoteMessage msg, {
    required String appTag,
    required String source,
    String listenerId = 'default',
    String? deviceToken,
  }) {
    return NotificationEventDedupe.markIfNew(
      msg,
      source: source,
      listenerId: listenerId,
      deviceToken: deviceToken,
    );
  }
}
