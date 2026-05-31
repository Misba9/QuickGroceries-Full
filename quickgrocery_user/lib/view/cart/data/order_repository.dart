import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/models/order_model.dart';

import '../domain/cart_models.dart';
import '../domain/order_line_snapshot.dart';

/// Writes orders to `orders/` after a successful payment / COD checkout.
///
/// The new order schema is a superset of the legacy one — we keep all the
/// old fields (`isDelivered`, `isCancelled`, `order_status`, etc.) so the
/// existing admin / delivery apps keep working, AND we add the cleaner
/// modern fields the new client surfaces:
///
/// ```
/// orders/{id} = {
///   ...legacy fields...,
///   status: 'pending' | 'accepted' | 'packing' | 'out_for_delivery'
///         | 'delivered' | 'cancelled',
///   paymentMethod: 'cod' | 'upi' | 'card' | 'wallet',
///   paymentStatus: 'pending' | 'paid' | 'failed',
///   paymentRef: <gateway txn id>,
///   delivery_slot: { id, label, start, end, isExpress },
///   delivery_instructions: <string>,
///   bill: { subtotal, deliveryFee, surgeFee, tax, handlingCharge,
///           platformFee, couponDiscount, total },
///   coupon: { id, code, discount },
///   address_snapshot: { name, mobile, address, area, type },
/// }
/// ```
class OrderRepository {
  OrderRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<String> placeOrder({
    required List<CartItem> items,
    required AppliedCoupon? coupon,
    required BillBreakdown bill,
    required AddressModel address,
    required String currentAddressString,
    required LatLng currentLatLng,
    required DeliverySlot? slot,
    required DeliveryInstructions instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User must be signed in to place an order.');
    }

    final productItems =
        items.map(OrderLineSnapshot.toProductItem).toList();

    final isPaid = paymentMethod.isOnline && paymentRef != null;

    final legacyOrder = OrderModel(
      lat: currentLatLng.latitude,
      lng: currentLatLng.longitude,
      currentLocation: currentAddressString,
      uuid: user.uid,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      products: productItems,
      createdDate: DateTime.now().toString(),
      address: '${address.address} ${address.area}',
      customerName: address.name,
      phone: address.mobile,
      isPaid: isPaid,
      orderStatus: OrderStatus.pending.displayName,
      deliveryBoyId: '',
      isDelivered: false,
      isCancelled: false,
      confimedTime: '',
      driverGoShopTime: '',
      onTheWayTime: '',
      orderDeliveredTime: '',
      orderPickedTime: '',
      deliveryType: 'standard',
      deliveryCharge: bill.deliveryFee.toInt(),
      isRated: false,
      rating: 0,
    );

    final legacyMap = legacyOrder.toMap();
    final modernExtras = <String, dynamic>{
      'status': OrderStatus.pending.id,
      'paymentMethod': paymentMethod.id,
      'paymentStatus': isPaid ? 'paid' : 'pending',
      if (paymentRef != null) 'paymentRef': paymentRef,
      'delivery_instructions': instructions.legacyText,
      'deliveryInstructions': instructions.toMap(),
      if (slot != null) ...{
        'delivery_slot': slot.toMap(),
        'deliverySlot': slot.toMap(),
      },
      'bill': bill.toMap(),
      if (coupon != null) 'coupon': coupon.toMap(),
      'address_snapshot': {
        'id': address.id,
        'name': address.name,
        'mobile': address.mobile,
        'address': address.address,
        'area': address.area,
        'type': address.type,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = _firestore.collection('orders').doc();
    final vendorIds = productItems
        .map((p) => p.vendorId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final orderData = {
      ...legacyMap,
      ...modernExtras,
      'id': ref.id,
      'vendorIds': vendorIds,
      if (vendorIds.length == 1) 'vendorId': vendorIds.first,
      if (vendorIds.length == 1) 'vendor_id': vendorIds.first,
    };

    debugPrint(
      'ORDER FIRESTORE WRITE path=orders/${ref.id} '
      'vendorIds=$vendorIds user=${user.uid}',
    );

    try {
      await ref.set(orderData);
      await _mirrorVendorOrders(
        orderId: ref.id,
        vendorIds: vendorIds,
        orderData: orderData,
      );
    } on FirebaseException catch (e, stack) {
      debugPrint(
        'ORDER FIRESTORE ERROR path=orders/${ref.id} '
        'code=${e.code} message=${e.message}',
      );
      debugPrintStack(stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      debugPrint('ORDER FIRESTORE ERROR path=orders/${ref.id} error=$e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
    return ref.id;
  }

  Future<void> _mirrorVendorOrders({
    required String orderId,
    required List<String> vendorIds,
    required Map<String, dynamic> orderData,
  }) async {
    if (vendorIds.isEmpty) return;
    final mirror = {
      'orderId': orderId,
      'status': orderData['status'],
      'customer_name': orderData['customer_name'],
      'phone': orderData['phone'],
      'address': orderData['address'],
      'deliverySlot': orderData['deliverySlot'] ?? orderData['delivery_slot'],
      'deliveryInstructions':
          orderData['deliveryInstructions'] ?? orderData['delivery_instructions'],
      'bill': orderData['bill'],
      'createdAt': orderData['createdAt'],
    };
    final batch = _firestore.batch();
    for (final vendorId in vendorIds) {
      batch.set(
        _firestore
            .collection('vendor_orders')
            .doc(vendorId)
            .collection('orders')
            .doc(orderId),
        {...mirror, 'vendorId': vendorId},
      );
    }
    await batch.commit();
  }

  /// Subscribe to a single order so the success / tracking screens can show
  /// realtime status as the admin moves it through the lifecycle.
  Stream<OrderUpdate?> watch(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((s) {
      if (!s.exists) return null;
      final data = s.data();
      if (data == null) return null;
      return OrderUpdate(
        id: s.id,
        status: OrderStatus.fromId(
          (data['status'] as String?) ?? _statusFromLegacy(data),
        ),
        total: (data['bill']?['total'] as num?)?.toDouble() ?? 0,
      );
    });
  }

  static String _statusFromLegacy(Map<String, dynamic> data) {
    if (data['isCancelled'] == true) return OrderStatus.cancelled.id;
    if (data['isDelivered'] == true) return OrderStatus.delivered.id;
    return OrderStatus.pending.id;
  }
}

class OrderUpdate {
  final String id;
  final OrderStatus status;
  final double total;
  OrderUpdate({required this.id, required this.status, required this.total});
}
