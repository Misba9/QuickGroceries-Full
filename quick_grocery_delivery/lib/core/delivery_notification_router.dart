import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/orders/screens/delivery_details_screen.dart';
import '../features/orders/services/order_service.dart';
import '../models/order_model.dart';

/// Central deep-link router for Delivery (rider) push / local notification taps.
class DeliveryNotificationRouter {
  DeliveryNotificationRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void Function(int tabIndex)? _onSelectTab;
  static void Function(Map<String, dynamic> data)? _onCancellationBanner;
  static Map<String, dynamic>? _pending;
  static String? _lastNavKey;
  static DateTime? _lastNavAt;
  static bool _ready = false;

  static void register({
    required void Function(int tabIndex) onSelectTab,
    void Function(Map<String, dynamic> data)? onCancellationBanner,
  }) {
    _onSelectTab = onSelectTab;
    _onCancellationBanner = onCancellationBanner;
    _ready = true;
    if (kDebugMode) debugPrint('[DeliveryPushNav] registered');
  }

  static void unregister() {
    _onSelectTab = null;
    _onCancellationBanner = null;
    _ready = false;
  }

  static void enqueue(Map<String, dynamic> raw) {
    _pending = Map<String, dynamic>.from(raw);
    if (kDebugMode) {
      debugPrint(
        '[DeliveryPushNav] queued type=${raw['type']} orderId=${raw['orderId']}',
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
      case 'delivery_assigned':
      case 'driver_assigned':
        return 'assignment';
      case 'order_cancelled':
      case 'cancelled':
        return 'cancellation';
      case 'delivery_completed':
      case 'order_delivered':
      case 'delivered':
        return 'order_detail';
      case 'delivery_tip':
        return 'wallet_tab';
      case 'order_out_for_delivery':
      case 'out_for_delivery':
      case 'picked_up':
      case 'reached_store':
        return 'order_detail';
      default:
        break;
    }

    if (resolveOrderId(raw).isNotEmpty) return 'order_detail';
    return 'orders_tab';
  }

  static bool _shouldSkip(String key) {
    final now = DateTime.now();
    return _lastNavKey == key &&
        _lastNavAt != null &&
        now.difference(_lastNavAt!) < const Duration(seconds: 3);
  }

  static void _mark(String key) {
    _lastNavKey = key;
    _lastNavAt = DateTime.now();
  }

  static Future<void> handleNotificationOpen(Map<String, dynamic> raw) async {
    final data = Map<String, dynamic>.from(raw);
    final orderId = resolveOrderId(data);
    final target = resolveTargetScreen(data);
    final ctx = navigatorKey.currentContext;

    if (kDebugMode) {
      debugPrint(
        '[DeliveryPushNav] open target=$target orderId=$orderId '
        'type=${data['type']} ready=$_ready ctx=${ctx != null}',
      );
    }

    if (!_ready || ctx == null) {
      enqueue(data);
      return;
    }

    switch (target) {
      case 'wallet_tab':
        _onSelectTab?.call(2);
        return;
      case 'orders_tab':
        _onSelectTab?.call(1);
        return;
      case 'cancellation':
        _onSelectTab?.call(1);
        _onCancellationBanner?.call(data);
        if (orderId.isNotEmpty) {
          await _openOrderDetail(ctx, orderId);
        }
        return;
      case 'assignment':
      case 'order_detail':
      default:
        _onSelectTab?.call(1);
        if (orderId.isEmpty) {
          _showMissing(ctx);
          return;
        }
        await _openOrderDetail(ctx, orderId, preferAcceptDialog: target == 'assignment');
    }
  }

  static Future<OrderModel?> _fetchOrder(
    BuildContext context,
    String orderId,
  ) async {
    final svc = context.read<OrderService>();
    final cached = svc.orderById(orderId);
    if (cached != null) return cached;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return OrderModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) debugPrint('[DeliveryPushNav] fetch failed: $e');
      return null;
    }
  }

  static Future<void> _openOrderDetail(
    BuildContext context,
    String orderId, {
    bool preferAcceptDialog = false,
  }) async {
    final routeKey = 'delivery_order:$orderId';
    if (_shouldSkip(routeKey)) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final order = await _fetchOrder(context, orderId);

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (order == null) {
      _showMissing(context);
      return;
    }

    final svc = context.read<OrderService>();
    if (preferAcceptDialog) {
      try {
        await svc.getOrders();
      } catch (_) {
        /* ignore */
      }
      if (!context.mounted) return;
      if (svc.newOrders.any((o) => o.id == orderId)) {
        svc.showAcceptRejectDialog(context, order);
        _mark(routeKey);
        return;
      }
    }

    _mark(routeKey);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeKey),
        builder: (_) => DeliveryDetailsScreen(order: order),
      ),
    );
  }

  static void _showMissing(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
          'Could not open this delivery. It may no longer be assigned to you.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
