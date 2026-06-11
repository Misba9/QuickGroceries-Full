import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/realtime/models/notification_item.dart';

/// Builds FCM-style payload for [handlePushNavigation] from an in-app item.
Map<String, String> notificationPushData(NotificationItem item) {
  final redirect = switch (item.kind) {
    NotificationKind.order => 'order_page',
    NotificationKind.offer => 'offers_page',
    NotificationKind.delivery => 'order_page',
    NotificationKind.system => 'home',
    NotificationKind.unknown => '',
  };

  var deepLink = item.deepLink;
  if (deepLink.isEmpty && item.targetId.isNotEmpty) {
    deepLink = switch (item.kind) {
      NotificationKind.order || NotificationKind.delivery =>
        '/orders/${item.targetId}',
      NotificationKind.offer => '/offers',
      _ => '',
    };
  }

  final notificationType = switch (item.kind) {
    NotificationKind.delivery => 'delivery_assigned',
    NotificationKind.order => 'order',
    NotificationKind.offer => 'offer',
    NotificationKind.system => 'system',
    NotificationKind.unknown => '',
  };

  return pushNavigationPayload({
    if (redirect.isNotEmpty) 'redirectType': redirect,
    if (deepLink.isNotEmpty) 'deepLink': deepLink,
    if (item.targetId.isNotEmpty) 'orderId': item.targetId,
    if (notificationType.isNotEmpty) 'notificationType': notificationType,
  });
}
