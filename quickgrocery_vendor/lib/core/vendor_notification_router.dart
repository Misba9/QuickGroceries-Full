import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../models/vendor_model.dart';
import '../services/order_service.dart';
import '../view/orders/order_detail_screen.dart';

/// Central deep-link router for Vendor push / local notification taps.
///
/// All open paths (FCM open, cold start, local tray tap, inbox) must go through
/// [handleNotificationOpen] so navigation stays in one place.
class VendorNotificationRouter {
  VendorNotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static VendorModel? _vendor;
  static void Function(int tabIndex)? _onSelectTab;
  static Map<String, dynamic>? _pending;
  static String? _lastNavKey;
  static DateTime? _lastNavAt;

  static void register({
    required VendorModel vendor,
    void Function(int tabIndex)? onSelectTab,
  }) {
    _vendor = vendor;
    _onSelectTab = onSelectTab;
    if (kDebugMode) {
      debugPrint('[VendorPushNav] registered vendor=${vendor.id}');
    }
  }

  static void unregister() {
    _vendor = null;
    _onSelectTab = null;
  }

  static void enqueue(Map<String, dynamic> raw) {
    _pending = Map<String, dynamic>.from(raw);
    if (kDebugMode) {
      debugPrint(
        '[VendorPushNav] queued type=${raw['type']} orderId=${raw['orderId']}',
      );
    }
  }

  static Future<void> consumePending() async {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    await handleNotificationOpen(pending);
  }

  static String resolveOrderId(Map<String, dynamic> raw) {
    final direct = raw['orderId']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final dl = raw['deepLink']?.toString() ?? '';
    if (dl.isEmpty) return '';
    try {
      final uri = Uri.parse(dl);
      final q = uri.queryParameters['orderId'];
      if (q != null && q.isNotEmpty) return q;
      if (uri.pathSegments.isNotEmpty) return uri.pathSegments.last;
    } catch (_) {
      /* ignore */
    }
    return '';
  }

  static String resolveTargetScreen(Map<String, dynamic> raw) {
    final explicit = raw['targetScreen']?.toString().trim().toLowerCase() ?? '';
    if (explicit.isNotEmpty) return explicit;

    final type = (raw['type'] ?? raw['notificationType'] ?? raw['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    switch (type) {
      case 'new_order':
      case 'order_accepted':
      case 'order_packed':
      case 'order_ready':
      case 'driver_assigned':
      case 'rider_assigned':
      case 'payment_released':
      case 'payment_received':
      case 'order_delivered':
      case 'order_cancelled':
      case 'low_stock':
      case 'out_of_stock':
      case 'stock_low':
        return type == 'low_stock' ||
                type == 'out_of_stock' ||
                type == 'stock_low'
            ? 'products_tab'
            : 'order_detail';
      default:
        break;
    }

    if (resolveOrderId(raw).isNotEmpty) return 'order_detail';
    return 'orders_tab';
  }

  static bool _shouldSkip(String key) {
    final now = DateTime.now();
    if (_lastNavKey == key &&
        _lastNavAt != null &&
        now.difference(_lastNavAt!) < const Duration(seconds: 3)) {
      return true;
    }
    return false;
  }

  static void _mark(String key) {
    _lastNavKey = key;
    _lastNavAt = DateTime.now();
  }

  /// Entry for every notification **tap** / cold-start open.
  static Future<void> handleNotificationOpen(Map<String, dynamic> raw) async {
    final data = Map<String, dynamic>.from(raw);
    final orderId = resolveOrderId(data);
    final target = resolveTargetScreen(data);
    final ctx = navigatorKey.currentContext;
    final vendor = _vendor;

    if (kDebugMode) {
      debugPrint(
        '[VendorPushNav] open target=$target orderId=$orderId '
        'type=${data['type']} ready=${ctx != null && vendor != null}',
      );
    }

    if (ctx == null || vendor == null) {
      enqueue(data);
      return;
    }

    switch (target) {
      case 'products_tab':
        _onSelectTab?.call(2);
        return;
      case 'orders_tab':
        _onSelectTab?.call(1);
        if (orderId.isEmpty) {
          _showMissingOrder(ctx);
        }
        return;
      case 'order_detail':
      default:
        if (orderId.isEmpty) {
          _onSelectTab?.call(1);
          _showMissingOrder(ctx);
          return;
        }
        await _openOrderDetail(ctx, vendor, orderId);
    }
  }

  static Future<void> _openOrderDetail(
    BuildContext context,
    VendorModel vendor,
    String orderId,
  ) async {
    final routeKey = 'vendor_order_detail:$orderId';
    if (_shouldSkip(routeKey)) return;

    _onSelectTab?.call(1);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    OrderModel? order;
    try {
      order = await OrderService().getOrderById(orderId);
    } catch (e) {
      if (kDebugMode) debugPrint('[VendorPushNav] fetch failed: $e');
    }

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // loading

    if (order == null) {
      _showMissingOrder(context);
      return;
    }

    // Avoid stacking duplicate detail pages for the same order.
    final nav = Navigator.of(context);
    _mark(routeKey);
    await nav.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeKey),
        builder: (_) => OrderDetailScreen(order: order!, vendor: vendor),
      ),
    );
  }

  static void _showMissingOrder(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open this order. It may have been removed.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
