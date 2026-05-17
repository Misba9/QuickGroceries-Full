import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/models/address_model.dart';
import 'package:quickgrocery/models/order_model.dart';

import '../domain/cart_models.dart';

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
    required String instructions,
    required PaymentMethod paymentMethod,
    String? paymentRef,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User must be signed in to place an order.');
    }

    final productItems = items
        .map((item) => ProductItem(
              productId: item.productId,
              name: item.name,
              image: item.image,
              description: '',
              category: item.category,
              unit: item.unit,
              price: item.unitEffectivePrice,
              slashedPrice: item.unitEffectiveSlashedPrice,
              itemCount: item.itemCount,
              vendorId: item.vendorId,
            ))
        .toList();

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
      'delivery_instructions': instructions,
      if (slot != null) 'delivery_slot': slot.toMap(),
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
    await ref.set({
      ...legacyMap,
      ...modernExtras,
      'id': ref.id,
    });
    return ref.id;
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
