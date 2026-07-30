import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/core/firebase/callable_payload.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Map<String, dynamic>? _pendingPushPayload;
String? _lastNavigationKey;
DateTime? _lastNavigationAt;

/// Queue a notification payload until [rootNavigatorKey] has a context (cold start).
void enqueuePushNavigation(Map<String, dynamic> raw) {
  _pendingPushPayload = Map<String, dynamic>.from(raw);
}

/// Replay a notification tap deferred during splash / bootstrap.
Future<void> consumePendingPushNavigation() async {
  final pending = _pendingPushPayload;
  if (pending == null) return;
  _pendingPushPayload = null;
  await handlePushNavigation(pending);
}

Map<String, String> _stringData(Map<String, dynamic> raw) {
  final out = <String, String>{};
  raw.forEach((k, v) {
    out[k.toString()] = v == null ? '' : v.toString();
  });
  return out;
}

/// JSON-safe map for local notification tray payloads.
Map<String, String> pushNavigationPayload(Map<String, dynamic> raw) {
  final data = _stringData(raw);
  final orderId = resolveOrderId(data);
  final notificationType =
      data['notificationType'] ?? data['type'] ?? data['status'] ?? '';
  final targetScreen = resolveTargetScreen({
    ...data,
    if (orderId.isNotEmpty) 'orderId': orderId,
    if (notificationType.isNotEmpty) 'notificationType': notificationType,
  });
  return {
    ...data,
    if (orderId.isNotEmpty) 'orderId': orderId,
    if (notificationType.isNotEmpty) 'notificationType': notificationType,
    'targetScreen': targetScreen,
  };
}

Future<void> recordPushOpenIfNeeded(Map<String, String> data) async {
  final logId = data['logId'] ?? '';
  if (logId.isEmpty) return;
  try {
    final payload = sanitizeCallableData(<String, dynamic>{'logId': logId});
    debugCallableData('recordNotificationOpen', payload);
    await FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('recordNotificationOpen').call(payload);
  } catch (_) {
    /* non-fatal */
  }
  try {
    await FirebaseAnalytics.instance.logEvent(
      name: 'notification_open',
      parameters: {
        'log_id': logId,
        'redirect': data['redirectType'] ?? '',
        'target_screen': data['targetScreen'] ?? '',
      },
    );
  } catch (_) {
    /* analytics optional */
  }
}

String? _parseQuery(String link, String key) {
  try {
    final uri = Uri.parse(link);
    return uri.queryParameters[key];
  } catch (_) {
    return null;
  }
}

String? _lastPathSegment(String link) {
  try {
    final uri = Uri.parse(link);
    if (uri.pathSegments.isEmpty) return null;
    return uri.pathSegments.last;
  } catch (_) {
    return null;
  }
}

String resolveOrderId(Map<String, String> data) {
  final direct = data['orderId']?.trim() ?? '';
  if (direct.isNotEmpty) return direct;
  final dl = data['deepLink'] ?? '';
  return _parseQuery(dl, 'orderId') ?? _lastPathSegment(dl) ?? '';
}

String _normalizeRedirect(String? redirect) {
  final r = (redirect ?? '').trim().toLowerCase();
  switch (r) {
    case 'order':
    case 'orders':
      return 'order_page';
    case 'cart':
      return 'cart_page';
    case 'offer':
    case 'offers':
      return 'offers_page';
    case 'category':
      return 'category_page';
    case 'product':
      return 'product_page';
    default:
      return r;
  }
}

/// Maps server `notificationType` / `type` / `targetScreen` to a navigation target.
String resolveTargetScreen(Map<String, String> data) {
  final explicit = data['targetScreen']?.trim().toLowerCase() ?? '';
  if (explicit.isNotEmpty) return explicit;

  final type = (data['notificationType'] ??
          data['type'] ??
          data['status'] ??
          '')
      .trim()
      .toLowerCase();

  switch (type) {
    case 'order_placed':
    case 'order_accepted':
    case 'order_packed':
    case 'order_confirmed':
    case 'payment_successful':
    case 'payment_success':
      return 'order_tracking';
    case 'delivery_assigned':
    case 'delivery_partner_assigned':
    case 'driver_assigned':
      return 'delivery_tracking';
    case 'order_out_for_delivery':
    case 'out_for_delivery':
      return 'live_tracking';
    case 'order_delivered':
    case 'delivered':
      return 'order_delivered';
    case 'order_cancelled':
    case 'cancelled':
    case 'cancelled_by_vendor':
    case 'cancelled_by_customer':
      return 'order_cancelled';
    case 'payment_failed':
      return 'payment_retry';
    case 'refund_initiated':
    case 'refund':
      return 'refund_details';
    case 'offer':
    case 'offers':
      return 'offers_page';
    case 'cart':
    case 'abandoned_cart':
      return 'cart_page';
    case 'home':
      return 'home';
    default:
      break;
  }

  final redirect = _normalizeRedirect(data['redirectType']);
  if (redirect == 'order_page' || redirect == 'order_details') {
    return resolveOrderId(data).isNotEmpty ? 'order_tracking' : 'orders_tab';
  }
  if (redirect == 'cart_page') return 'cart_page';
  if (redirect == 'offers_page') return 'offers_page';
  if (redirect == 'category_page') return 'category_page';
  if (redirect == 'product_page') return 'product_page';
  if (redirect == 'home') return 'home';

  final dl = data['deepLink'] ?? '';
  if (dl.contains('/orders/') || dl.contains('order')) {
    return resolveOrderId(data).isNotEmpty ? 'order_tracking' : 'orders_tab';
  }
  if (dl.contains('cart')) return 'cart_page';
  if (dl.contains('offers')) return 'offers_page';
  if (dl.contains('product')) return 'product_page';

  return resolveOrderId(data).isNotEmpty ? 'order_tracking' : 'home';
}

Future<void> _openProductById(BuildContext context, String? productId) async {
  if (productId == null || productId.isEmpty) return;
  try {
    final snap = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .get();
    if (!snap.exists || !context.mounted) return;
    final data = snap.data();
    if (data == null) return;
    final product = ProductModel.fromFirestore(data, snap.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(AppPageRoutes.product(product));
  } catch (_) {
    /* ignore */
  }
}

Future<bool> _orderExists(String orderId) async {
  if (orderId.isEmpty) return false;
  try {
    final snap =
        await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    return snap.exists;
  } catch (_) {
    return false;
  }
}

String _orderTrackingRouteName(String orderId) =>
    '${AppRoutes.orderTracking}/$orderId';

bool _shouldSkipDuplicateNavigation(String key) {
  final now = DateTime.now();
  if (_lastNavigationKey == key &&
      _lastNavigationAt != null &&
      now.difference(_lastNavigationAt!) < const Duration(seconds: 3)) {
    return true;
  }
  final top = appRouteObserver.topRouteName ?? '';
  if (top == key) return true;
  return false;
}

void _markNavigation(String key) {
  _lastNavigationKey = key;
  _lastNavigationAt = DateTime.now();
}

Future<void> _showOrderNotFound(BuildContext context) async {
  final home = legacy.Provider.of<HomeProvider>(context, listen: false);
  home.onSelectedChange(AppRoutes.ordersTabIndex);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Order not found'),
      content: const Text(
        'This order is no longer available. Showing your orders list.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> _openOrderTracking(BuildContext context, String orderId) async {
  if (orderId.isEmpty) return;
  final routeName = _orderTrackingRouteName(orderId);
  if (_shouldSkipDuplicateNavigation(routeName)) return;

  final exists = await _orderExists(orderId);
  if (!context.mounted) return;
  if (!exists) {
    await _showOrderNotFound(context);
    return;
  }

  final home = legacy.Provider.of<HomeProvider>(context, listen: false);
  home.onSelectedChange(AppRoutes.ordersTabIndex);

  final nav = Navigator.of(context);
  final top = appRouteObserver.topRouteName ?? '';
  if (top.startsWith(AppRoutes.orderTracking) && nav.canPop()) {
    await nav.maybePop();
  }

  _markNavigation(routeName);
  await nav.push(AppPageRoutes.orderTracking(orderId: orderId));
}

/// Handles FCM `data` payloads from taps, cold starts, and in-app inbox.
Future<void> handlePushNavigation(Map<String, dynamic> raw) async {
  final data = pushNavigationPayload(raw);
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) {
    enqueuePushNavigation(data);
    return;
  }

  await recordPushOpenIfNeeded(data);
  if (!ctx.mounted) return;

  final target = resolveTargetScreen(data);
  final orderId = resolveOrderId(data);
  final home = legacy.Provider.of<HomeProvider>(ctx, listen: false);

  if (kDebugMode) {
    debugPrint(
      '[PushNav] target=$target orderId=$orderId '
      'type=${data['notificationType'] ?? data['type'] ?? '—'}',
    );
  }

  switch (target) {
    case 'order_tracking':
    case 'delivery_tracking':
    case 'live_tracking':
    case 'order_delivered':
    case 'order_cancelled':
    case 'refund_details':
      await _openOrderTracking(ctx, orderId);
      return;
    case 'payment_retry':
      // Prefer the order screen when we have an orderId (payment failure on an order).
      if (orderId.isNotEmpty) {
        await _openOrderTracking(ctx, orderId);
        return;
      }
      home.onSelectedChange(AppRoutes.ordersTabIndex);
      if (!ctx.mounted) return;
      if (_shouldSkipDuplicateNavigation(AppRoutes.checkout)) return;
      _markNavigation(AppRoutes.checkout);
      await Navigator.of(ctx).push(AppPageRoutes.checkout());
      return;
    case 'orders_tab':
      home.onSelectedChange(AppRoutes.ordersTabIndex);
      return;
    case 'offers_page':
      home.onSelectedChange(2);
      return;
    case 'category_page':
      home.onSelectedChange(1);
      return;
    case 'cart_page':
      home.onSelectedChange(0);
      if (_shouldSkipDuplicateNavigation(AppRoutes.cart)) return;
      _markNavigation(AppRoutes.cart);
      await Navigator.of(ctx).push<void>(AppPageRoutes.cart());
      return;
    case 'product_page':
      home.onSelectedChange(0);
      final dl = data['deepLink'] ?? '';
      final pid = _parseQuery(dl, 'productId') ?? _lastPathSegment(dl);
      await _openProductById(ctx, pid);
      return;
    case 'home':
      home.onSelectedChange(0);
      return;
    default:
      if (orderId.isNotEmpty) {
        await _openOrderTracking(ctx, orderId);
      } else {
        home.onSelectedChange(0);
      }
  }
}
