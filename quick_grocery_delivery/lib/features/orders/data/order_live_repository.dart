import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

/// Live order + vendor enrichment for delivery detail screens.
class OrderLiveRepository {
  OrderLiveRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<OrderModel> watchOrder(String orderId, {OrderModel? seed}) {
    if (orderId.isEmpty) {
      return Stream.value(seed ?? _emptyOrder(orderId));
    }
    return _db.collection('orders').doc(orderId).snapshots().asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) {
        return seed ?? _emptyOrder(orderId);
      }
      var order = OrderModel.fromFirestore(snap.data()!, orderId);
      order = await _enrichVendor(order);
      return order;
    });
  }

  Future<OrderModel> _enrichVendor(OrderModel order) async {
    final vendorId = order.primaryVendorId;
    if (vendorId.isEmpty) return order;

    final needsVendor = order.vendorPhone.trim().isEmpty ||
        order.pickupAddress.trim().isEmpty ||
        order.storeName.trim().isEmpty;
    if (!needsVendor) return order;

    try {
      final snap = await _db.collection('vendors').doc(vendorId).get();
      if (!snap.exists || snap.data() == null) return order;
      final v = snap.data()!;
      return order.copyWith(
        vendorName: order.vendorName.isNotEmpty
            ? order.vendorName
            : (v['ownerName'] ?? v['name'] ?? v['shopName'] ?? '').toString(),
        storeName: order.storeName.isNotEmpty
            ? order.storeName
            : (v['shopName'] ?? v['shop_name'] ?? '').toString(),
        vendorPhone: order.vendorPhone.isNotEmpty
            ? order.vendorPhone
            : (v['phone'] ?? v['mobile'] ?? '').toString(),
        pickupAddress: order.pickupAddress.isNotEmpty
            ? order.pickupAddress
            : (v['address'] ?? v['shopAddress'] ?? v['shop_address'] ?? '')
                .toString(),
        pickupLat: order.pickupLat ??
            _optionalDouble(v['latitude'] ?? v['lat']),
        pickupLng: order.pickupLng ??
            _optionalDouble(v['longitude'] ?? v['lng']),
      );
    } catch (_) {
      return order;
    }
  }

  static double? _optionalDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static OrderModel _emptyOrder(String id) => OrderModel(
        id: id,
        products: const [],
        createdDate: '',
        customerName: '',
        phone: '',
        address: '',
        isPaid: false,
        orderStatus: '',
        deliveryBoyId: '',
        isDelivered: false,
        isCancelled: false,
        deliveryType: '',
        isRated: false,
        rating: 0,
        confimedTime: '',
        driverGoShopTime: '',
        orderPickedTime: '',
        onTheWayTime: '',
        orderDeliveredTime: '',
        deliveryCharge: 0,
        uuid: '',
      );
}
