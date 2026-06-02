import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/models/order_model.dart';

/// Rebuilds when the order document or linked vendor document changes.
class OrderLiveBuilder extends StatelessWidget {
  const OrderLiveBuilder({
    super.key,
    required this.orderId,
    required this.seed,
    required this.builder,
  });

  final String orderId;
  final OrderModel seed;
  final Widget Function(BuildContext context, OrderModel order) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .snapshots(),
      builder: (context, orderSnap) {
        var order = seed;
        if (orderSnap.hasData &&
            orderSnap.data!.exists &&
            orderSnap.data!.data() != null) {
          order = OrderModel.fromFirestore(orderSnap.data!.data()!, orderId);
        }

        final vendorId = order.primaryVendorId;
        if (vendorId.isEmpty) {
          return builder(context, order);
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('vendors')
              .doc(vendorId)
              .snapshots(),
          builder: (context, vendorSnap) {
            if (vendorSnap.hasData &&
                vendorSnap.data!.exists &&
                vendorSnap.data!.data() != null) {
              order = _mergeVendor(order, vendorSnap.data!.data()!);
            }
            return builder(context, order);
          },
        );
      },
    );
  }

  static OrderModel _mergeVendor(
    OrderModel order,
    Map<String, dynamic> v,
  ) {
    final shop =
        (v['shopName'] ?? v['shop_name'] ?? order.storeName).toString();
    final owner =
        (v['ownerName'] ?? v['name'] ?? order.vendorName).toString();
    return order.copyWith(
      vendorName: order.vendorName.isNotEmpty ? order.vendorName : owner,
      storeName: order.storeName.isNotEmpty ? order.storeName : shop,
      vendorPhone: order.vendorPhone.isNotEmpty
          ? order.vendorPhone
          : (v['phone'] ?? v['mobile'] ?? '').toString(),
      pickupAddress: order.pickupAddress.isNotEmpty
          ? order.pickupAddress
          : (v['address'] ?? v['shopAddress'] ?? v['shop_address'] ?? '')
              .toString(),
      pickupLat: order.pickupLat ??
          _dbl(v['latitude'] ?? v['lat']),
      pickupLng: order.pickupLng ??
          _dbl(v['longitude'] ?? v['lng']),
    );
  }

  static double? _dbl(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }
}
