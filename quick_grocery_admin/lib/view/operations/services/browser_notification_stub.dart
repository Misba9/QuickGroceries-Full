/// Browser notifications are web-only.
Future<void> requestBrowserNotificationPermission() async {}

Future<void> showBrowserNotification({
  required String title,
  required String body,
  String? tag,
}) async {}

bool get browserNotificationsSupported => false;

bool get browserNotificationsGranted => false;
