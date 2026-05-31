import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get browserNotificationsSupported => web.window.isSecureContext;

bool get browserNotificationsGranted =>
    browserNotificationsSupported &&
    web.Notification.permission == 'granted';

Future<void> requestBrowserNotificationPermission() async {
  if (!browserNotificationsSupported) return;
  if (web.Notification.permission == 'granted') return;
  if (web.Notification.permission == 'denied') return;
  try {
    await web.Notification.requestPermission().toDart;
  } catch (_) {}
}

Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) async {
  if (!browserNotificationsGranted) return;
  try {
    web.Notification(
      title,
      web.NotificationOptions(body: body, tag: tag ?? title, silent: false),
    );
  } catch (_) {}
}
