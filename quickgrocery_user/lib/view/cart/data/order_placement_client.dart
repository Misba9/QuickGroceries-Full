import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/models/address_model.dart';

import '../domain/cart_models.dart';

/// Server-side order placement with stock validation and decrement.
class OrderPlacementClient {
  OrderPlacementClient({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;

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

    final res = await _fn.httpsCallable('placeOrderCallable').call({
      'items': items
          .where((e) => !e.isComboLine)
          .map((e) => {
                'productId': e.productId,
                'itemCount': e.itemCount,
                'selectedWeightInGrams': e.selectedWeightInGrams,
              })
          .toList(),
      'comboItems': items
          .where((e) => e.isComboLine)
          .map((e) => e.toMap())
          .toList(),
      'bill': bill.toMap(),
      if (coupon != null) 'coupon': coupon.toMap(),
      'address': {
        'id': address.id,
        'name': address.name,
        'mobile': address.mobile,
        'address': address.address,
        'area': address.area,
        'type': address.type,
      },
      'currentLocation': currentAddressString,
      'lat': currentLatLng.latitude,
      'lng': currentLatLng.longitude,
      if (slot != null) 'delivery_slot': slot.toMap(),
      'delivery_instructions': instructions,
      'paymentMethod': paymentMethod.id,
      if (paymentRef != null) 'paymentRef': paymentRef,
    });

    final data = res.data;
    if (data is Map && data['orderId'] != null) {
      return data['orderId'].toString();
    }
    throw StateError('Invalid response from placeOrderCallable');
  }
}
