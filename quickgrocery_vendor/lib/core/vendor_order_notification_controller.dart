import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/order_lifecycle.dart';
import '../models/order_model.dart';
import '../utils/vendor_order_utils.dart';
import 'order_alert_sound.dart';
import 'vendor_alert_vibration.dart';

/// In-app alerts driven by Firestore order stream diffs.
class VendorOrderNotificationController extends ChangeNotifier {
  int badgeCount = 0;
  VendorOrderAlert? latestAlert;
  final Set<String> _knownOrderIds = {};
  final Set<String> _notifiedOrderIds = {};
  final Set<String> _notifiedStatusKeys = {};
  final Map<String, String> _lastStatusById = {};
  bool _primed = false;

  String? _lastNotifiedOrderId;

  String? get lastNotifiedOrderId => _lastNotifiedOrderId;

  bool hasBeenNotified(String orderId) => _notifiedOrderIds.contains(orderId);

  void markOrderNotified(String orderId) {
    _notifiedOrderIds.add(orderId);
    _lastNotifiedOrderId = orderId;
  }

  static String _statusKey(OrderModel o) => OrderLifecycle.resolveStatus({
        'status': o.modernStatus,
        'order_status': o.orderStatus,
        'isCancelled': o.isCancelled,
        'isDelivered': o.isDelivered,
      });

  void onOrdersUpdated(List<OrderModel> orders, {required String vendorId}) {
    final vendorOrders = orders.where((o) {
      return o.products.any((p) => p.vendorId == vendorId);
    }).toList();

    if (!_primed) {
      for (final o in vendorOrders) {
        _knownOrderIds.add(o.id);
        _lastStatusById[o.id] = _statusKey(o);
        // Existing orders at startup are treated as already seen.
        _notifiedOrderIds.add(o.id);
      }
      _primed = true;
      _recomputeBadge(vendorOrders);
      notifyListeners();
      return;
    }

    for (final o in vendorOrders) {
      final cur = _statusKey(o);
      if (!_knownOrderIds.contains(o.id)) {
        _knownOrderIds.add(o.id);
        if (_isNewPendingOrder(o) && !_notifiedOrderIds.contains(o.id)) {
          if (kDebugMode) {
            debugPrint('[VendorNotify] order created id=${o.id} status=${o.orderStatus}');
          }
          _emit(
            type: VendorAlertType.newOrder,
            order: o,
            message: 'New order from ${o.customerName}',
          );
        }
      } else {
        final prev = _lastStatusById[o.id];
        if (prev != null && prev != cur) {
          _emitStatusChange(o, prev, cur);
        }
      }
      _lastStatusById[o.id] = cur;
    }

    _recomputeBadge(vendorOrders);
    notifyListeners();
  }

  static bool _isNewPendingOrder(OrderModel o) {
    if (o.isCancelled || o.isDelivered) return false;
    final bucket = VendorOrderUtils.statusBucket(o);
    return bucket == 'waiting';
  }

  void _recomputeBadge(List<OrderModel> orders) {
    badgeCount = orders.where((o) {
      if (o.isCancelled || o.isDelivered) return false;
      return VendorOrderUtils.statusBucket(o) == 'waiting';
    }).length;
  }

  void _emitStatusChange(OrderModel o, String prev, String cur) {
    final statusKey = '${o.id}:$cur';
    if (_notifiedStatusKeys.contains(statusKey)) return;
    _notifiedStatusKeys.add(statusKey);

    if (o.isCancelled ||
        cur == OrderLifecycle.vendorRejected ||
        cur == OrderLifecycle.cancelled) {
      OrderAlertSound.playNewOrder();
      VendorAlertVibration.pulseNewOrder();
      _emit(
        type: VendorAlertType.cancelled,
        order: o,
        message: '❌ Order #${o.id.substring(0, 8)} cancelled by customer',
      );
      return;
    }
    if (cur == OrderLifecycle.vendorAccepted) {
      _emit(
        type: VendorAlertType.accepted,
        order: o,
        message: 'Order accepted — start preparing',
      );
      return;
    }
    final curLegacy = o.orderStatus.toLowerCase();
    if (curLegacy.contains('deliver')) {
      _emit(type: VendorAlertType.delivered, order: o, message: 'Order delivered');
      return;
    }
    if (o.deliveryBoyId.isNotEmpty &&
        (curLegacy.contains('rider') || curLegacy.contains('assigned'))) {
      _emit(
        type: VendorAlertType.riderAssigned,
        order: o,
        message: 'Rider assigned to order',
      );
      return;
    }
    if (curLegacy.contains('going') || curLegacy.contains('shop')) {
      _emit(
        type: VendorAlertType.riderAtStore,
        order: o,
        message: 'Rider reached store',
      );
      return;
    }
    if (curLegacy.contains('picked')) {
      _emit(
        type: VendorAlertType.pickedUp,
        order: o,
        message: 'Rider picked up order',
      );
      return;
    }
    if (o.isPaid && !prev.toLowerCase().contains('paid')) {
      _emit(
        type: VendorAlertType.payment,
        order: o,
        message: 'Payment received',
      );
    }
  }

  final List<VendorOrderAlert> _pendingNewOrders = [];

  List<VendorOrderAlert> takePendingNewOrders() {
    if (_pendingNewOrders.isEmpty) return const [];
    final out = List<VendorOrderAlert>.from(_pendingNewOrders);
    _pendingNewOrders.clear();
    return out;
  }

  int get pendingNewOrderCount => _pendingNewOrders.length;

  /// Called when FCM arrives before/alongside Firestore stream update.
  void injectNewOrderFromRemote(OrderModel order, {required String vendorId}) {
    if (!order.products.any((p) => p.vendorId == vendorId)) return;
    if (!_primed) return;
    if (_knownOrderIds.contains(order.id)) return;
    if (!_isNewPendingOrder(order)) return;
    if (_notifiedOrderIds.contains(order.id)) return;

    _knownOrderIds.add(order.id);
    _lastStatusById[order.id] = order.orderStatus;
    if (kDebugMode) {
      debugPrint('[VendorNotify] FCM injected order id=${order.id}');
    }
    _emit(
      type: VendorAlertType.newOrder,
      order: order,
      message: 'New order from ${order.customerName}',
    );
    _recomputeBadge([order]);
    notifyListeners();
  }

  void _emit({
    required VendorAlertType type,
    required OrderModel order,
    required String message,
  }) {
    if (type == VendorAlertType.newOrder) {
      HapticFeedback.heavyImpact();
      OrderAlertSound.playNewOrder();
      VendorAlertVibration.pulseNewOrder();
      if (kDebugMode) {
        debugPrint('[VendorNotify] sound played order=${order.id}');
      }
    } else if (type == VendorAlertType.cancelled) {
      HapticFeedback.heavyImpact();
      OrderAlertSound.playNewOrder();
      VendorAlertVibration.pulseNewOrder();
    } else {
      HapticFeedback.mediumImpact();
    }
    final alert = VendorOrderAlert(
      type: type,
      orderId: order.id,
      customerName: order.customerName,
      message: message,
      at: DateTime.now(),
      order: type == VendorAlertType.newOrder ? order : null,
    );
    latestAlert = alert;
    if (type == VendorAlertType.newOrder) {
      _pendingNewOrders.add(alert);
    }
  }

  void clearLatest() {
    latestAlert = null;
    notifyListeners();
  }

  void clearBadge() {
    badgeCount = 0;
    notifyListeners();
  }
}

enum VendorAlertType {
  newOrder,
  accepted,
  cancelled,
  riderAssigned,
  riderAtStore,
  pickedUp,
  delivered,
  payment,
}

class VendorOrderAlert {
  const VendorOrderAlert({
    required this.type,
    required this.orderId,
    required this.customerName,
    required this.message,
    required this.at,
    this.order,
  });

  final VendorAlertType type;
  final String orderId;
  final String customerName;
  final String message;
  final DateTime at;
  final OrderModel? order;
}
