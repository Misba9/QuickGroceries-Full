import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/core/order/order_bill_totals.dart';
import 'package:quickgrocery/models/order_model.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart'
    show DeliveryInstructions, OrderStatus;

export 'package:quickgrocery/view/cart/domain/cart_models.dart'
    show DeliveryInstructions, OrderStatus;

/// A live, screen-friendly view of an order — wraps the legacy [OrderModel]
/// and surfaces the modern fields written by the new checkout flow
/// (`status`, `paymentMethod`, `delivery_slot`, `delivery_instructions`,
/// `bill`, `address_snapshot`, `paymentRef`) while keeping all the legacy
/// per-step timestamps so screens can render a rich timeline.
@immutable
class LiveOrder {
  final OrderModel legacy;
  final OrderStatus status;
  final DateTime createdAt;
  final String paymentMethodId;
  final String paymentStatus;
  final String? paymentRef;
  final String deliveryInstructions;
  final DeliveryInstructions structuredInstructions;
  final DateTime? slotStart;
  final DateTime? slotEnd;
  final String? slotLabel;
  final bool slotExpress;
  final Map<String, dynamic> billSnapshot;
  final Map<String, dynamic>? addressSnapshot;

  const LiveOrder({
    required this.legacy,
    required this.status,
    required this.createdAt,
    required this.paymentMethodId,
    required this.paymentStatus,
    required this.paymentRef,
    required this.deliveryInstructions,
    required this.structuredInstructions,
    required this.slotStart,
    required this.slotEnd,
    required this.slotLabel,
    required this.slotExpress,
    required this.billSnapshot,
    required this.addressSnapshot,
  });

  String get id => legacy.id;
  String get deliveryBoyId => legacy.deliveryBoyId;
  String get phone => legacy.phone;
  String get customerName => legacy.customerName;
  LatLng get dropLatLng => LatLng(legacy.lat, legacy.lng);
  int get itemCount =>
      legacy.products.fold<int>(0, (acc, p) => acc + p.itemCount);
  bool get isPaid => legacy.isPaid;
  bool get isCancelled => legacy.isCancelled;
  bool get isDelivered => legacy.isDelivered;
  bool get hasRider => legacy.deliveryBoyId.isNotEmpty;

  bool get isLiveTracking =>
      hasRider && !isDelivered && !isCancelled && status.isLiveTracking;

  bool get canCustomerCancel {
    if (isCancelled || isDelivered) return false;
    if (status == OrderStatus.pickedUp ||
        status == OrderStatus.outForDelivery) {
      return false;
    }
    if (_tryParse(legacy.orderPickedTime) != null) return false;
    return true;
  }

  String get paymentMethodLabel {
    switch (paymentMethodId.toLowerCase()) {
      case 'cod':
        return 'Cash on Delivery';
      case 'online':
      case 'razorpay':
        return 'Online Payment';
      case 'upi':
        return 'UPI';
      default:
        if (paymentMethodId.isEmpty) return 'Cash on Delivery';
        return paymentMethodId;
    }
  }

  String get shortOrderId =>
      id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();

  double billField(String key) => (billSnapshot[key] as num?)?.toDouble() ?? 0;

  /// Grand total from saved `bill` (single source of truth).
  double get total {
    final fromBill = OrderBillTotals.fromMap(billSnapshot);
    if (fromBill != null && fromBill.grandTotal > 0) {
      return fromBill.grandTotal;
    }
    return OrderBillTotals.fromLineTotals(
      itemsSubtotal: legacy.products.fold<double>(
        0,
        (sum, p) => sum + p.lineTotal,
      ),
      deliveryCharge: legacy.deliveryCharge,
    ).grandTotal;
  }

  String get deliverySlotLabel {
    if (slotLabel == null || slotLabel!.isEmpty) return '—';
    if (slotExpress) {
      final cleaned = slotLabel!
          .replaceAll(RegExp(r'^Express\s*[·•\-]\s*', caseSensitive: false), '');
      return 'Express • $cleaned';
    }
    return slotLabel!;
  }

  factory LiveOrder.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final legacy = OrderModel.fromFirestore(data, id);
    final status = OrderStatus.fromId(
      (data['status'] as String?) ?? _statusFromLegacy(data),
    );

    DateTime createdAt = _parseDateTime(data['createdAt']) ??
        _parseDateTime(data['created_date']) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final slot = data['deliverySlot'] ?? data['delivery_slot'];
    DateTime? slotStart;
    DateTime? slotEnd;
    String? slotLabel;
    bool slotExpress = false;
    if (slot is Map) {
      slotStart = _parseDateTime(slot['startTime'] ?? slot['start']);
      slotEnd = _parseDateTime(slot['endTime'] ?? slot['end']);
      slotLabel = (slot['slotName'] ?? slot['label'])?.toString();
      slotExpress = slot['isExpress'] as bool? ??
          (slot['slotType']?.toString().toLowerCase() == 'express');
    }

    final bill = data['bill'];
    final addressSnap = data['address_snapshot'];
    final structured = DeliveryInstructions.fromMap(
      data['deliveryInstructions'] ?? data['delivery_instructions'],
    );

    return LiveOrder(
      legacy: legacy,
      status: status,
      createdAt: createdAt,
      paymentMethodId: (data['paymentMethod'] as String?) ?? 'cod',
      paymentStatus: (data['paymentStatus'] as String?) ??
          (legacy.isPaid ? 'paid' : 'pending'),
      paymentRef: data['paymentRef']?.toString(),
      deliveryInstructions: structured.legacyText,
      structuredInstructions: structured,
      slotStart: slotStart,
      slotEnd: slotEnd,
      slotLabel: slotLabel,
      slotExpress: slotExpress,
      billSnapshot: bill is Map
          ? Map<String, dynamic>.from(bill)
          : <String, dynamic>{},
      addressSnapshot: addressSnap is Map
          ? Map<String, dynamic>.from(addressSnap)
          : null,
    );
  }

  static String _statusFromLegacy(Map<String, dynamic> data) {
    if (data['isCancelled'] == true) return OrderStatus.cancelled.id;
    if (data['isDelivered'] == true) return OrderStatus.delivered.id;
    final modern = (data['status'] as String?)?.trim();
    if (modern != null && modern.isNotEmpty) {
      return OrderStatus.fromId(modern).id;
    }
    final s = (data['order_status'] as String?)?.toLowerCase() ?? '';
    if (s.contains('cancel')) return OrderStatus.cancelled.id;
    if (s.contains('deliver')) return OrderStatus.delivered.id;
    if (s.contains('way')) return OrderStatus.outForDelivery.id;
    if (s.contains('picked')) return OrderStatus.pickedUp.id;
    if (s.contains('reached') && s.contains('store')) {
      return OrderStatus.reachedStore.id;
    }
    if (s.contains('going') || s.contains('shop')) return OrderStatus.headingToStore.id;
    if (s.contains('rider') && s.contains('accept')) return OrderStatus.riderAccepted.id;
    if (s.contains('rider') && s.contains('assign')) return OrderStatus.riderAssigned.id;
    if (s.contains('ready')) return OrderStatus.readyForPickup.id;
    if (s.contains('prepar') || s.contains('pack')) return OrderStatus.packing.id;
    if (s.contains('reject')) return OrderStatus.vendorRejected.id;
    if (s.contains('vendor') && s.contains('accept')) return OrderStatus.vendorAccepted.id;
    if (s.contains('confirm') || s.contains('accept')) return OrderStatus.vendorAccepted.id;
    return OrderStatus.pending.id;
  }
}

/// Single tile in the order timeline.
@immutable
class OrderTimelineEntry {
  final String title;
  final String subtitle;
  final DateTime? at;
  final bool done;
  final bool active;

  const OrderTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.done,
    required this.active,
  });
}

/// Build the canonical 8-step timeline for a [LiveOrder].
List<OrderTimelineEntry> buildTimeline(LiveOrder o) {
  if (o.isCancelled) {
    return [
      const OrderTimelineEntry(
        title: 'Order placed',
        subtitle: 'We have received your order',
        at: null,
        done: true,
        active: false,
      ),
      const OrderTimelineEntry(
        title: 'Cancelled',
        subtitle: 'This order was cancelled',
        at: null,
        done: true,
        active: true,
      ),
    ];
  }

  final activeStep = _activeTrackingStep(o);
  final placedAt = o.createdAt == DateTime.fromMillisecondsSinceEpoch(0)
      ? null
      : o.createdAt;

  const steps = <({String title, String subtitle, DateTime? at})>[
    (
      title: 'Order placed',
      subtitle: 'We have received your order',
      at: null,
    ),
    (
      title: 'Order confirmed',
      subtitle: 'Vendor has confirmed your order',
      at: null,
    ),
    (
      title: 'Vendor preparing order',
      subtitle: 'Your items are being prepared',
      at: null,
    ),
    (
      title: 'Order ready for pickup',
      subtitle: 'Waiting for the delivery partner',
      at: null,
    ),
    (
      title: 'Delivery partner assigned',
      subtitle: 'A rider is on the way to the store',
      at: null,
    ),
    (
      title: 'Picked up',
      subtitle: 'Your order has left the store',
      at: null,
    ),
    (
      title: 'Out for delivery',
      subtitle: 'Rider is heading to you',
      at: null,
    ),
    (
      title: 'Delivered',
      subtitle: 'Order completed — enjoy!',
      at: null,
    ),
  ];

  final times = <DateTime?>[
    placedAt,
    _tryParse(o.legacy.confimedTime),
    _tryParse(o.legacy.driverGoShopTime),
    _tryParse(o.legacy.driverGoShopTime),
    o.hasRider ? _tryParse(o.legacy.driverGoShopTime) : null,
    _tryParse(o.legacy.orderPickedTime),
    _tryParse(o.legacy.onTheWayTime) ?? _tryParse(o.legacy.orderPickedTime),
    _tryParse(o.legacy.orderDeliveredTime),
  ];

  return List.generate(steps.length, (i) {
    final step = steps[i];
    final done = o.isDelivered || i < activeStep || i == 0;
    final active = o.isDelivered ? i == 7 : i == activeStep;
    return OrderTimelineEntry(
      title: step.title,
      subtitle: step.subtitle,
      at: times[i],
      done: done,
      active: active,
    );
  });
}

int _activeTrackingStep(LiveOrder o) {
  if (o.isDelivered || o.status == OrderStatus.delivered) return 7;
  if (o.status == OrderStatus.outForDelivery) return 6;
  if (o.status == OrderStatus.pickedUp || _tryParse(o.legacy.orderPickedTime) != null) {
    return 5;
  }
  if (o.status == OrderStatus.reachedStore ||
      o.status == OrderStatus.headingToStore) {
    return 4;
  }
  if (o.status == OrderStatus.riderAccepted) return 4;
  if (o.hasRider || o.status == OrderStatus.riderAssigned) return 4;
  if (o.status == OrderStatus.readyForPickup) return 3;
  if (o.status == OrderStatus.packing) return 3;
  if (o.status == OrderStatus.accepted || o.status == OrderStatus.vendorAccepted) return 2;
  if (_tryParse(o.legacy.confimedTime) != null) return 1;
  return 0;
}

/// Realtime rider position. Shape:
/// `delivery_boys/{id}` is expected to optionally contain
/// `lat`, `lng`, `heading`, `lastUpdated`, `phone`, `name`, `image`.
@immutable
class RiderLocation {
  final String id;
  final String name;
  final String phone;
  final String image;
  final String vehicleType;
  final String vehicleNumber;
  final LatLng? position;
  final double? heading;
  final DateTime? lastUpdated;

  const RiderLocation({
    required this.id,
    required this.name,
    required this.phone,
    required this.image,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.position,
    required this.heading,
    required this.lastUpdated,
  });

  factory RiderLocation.fromMap(Map<String, dynamic> data, String id) {
    final lat = (data['lat'] as num?)?.toDouble() ??
        (data['latitude'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble() ??
        (data['longitude'] as num?)?.toDouble();
    return RiderLocation(
      id: id,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      image: (data['image'] ?? data['profileImage'] ?? '').toString(),
      vehicleType: (data['vehicleType'] ?? data['vehicle_type'] ?? '')
          .toString(),
      vehicleNumber: (data['vehicleNumber'] ?? data['vehicle_number'] ?? '')
          .toString(),
      position: (lat != null && lng != null) ? LatLng(lat, lng) : null,
      heading: (data['heading'] as num?)?.toDouble(),
      lastUpdated: _parseDateTime(data['lastUpdated']),
    );
  }
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

DateTime? _tryParse(String s) {
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}
