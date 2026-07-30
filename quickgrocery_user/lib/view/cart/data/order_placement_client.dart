import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:quickgrocery/core/firebase/callable_payload.dart';
import 'package:quickgrocery/models/address_model.dart';

import '../domain/cart_models.dart';
import '../domain/order_line_snapshot.dart';

/// Server-side order placement with stock validation and decrement.
class OrderPlacementClient {
  OrderPlacementClient({FirebaseFunctions? functions})
    : _fn = functions,
      _regions = functions == null
          ? const ['asia-south1', 'us-central1']
          : const [];

  static const functionName = 'placeOrderCallable';

  final FirebaseFunctions? _fn;
  final List<String> _regions;

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
    String? razorpayOrderId,
    String? razorpaySignature,
    double tipAmount = 0,
    String? idempotencyKey,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('User must be signed in to place an order.');
    }

    final authPhone = user.phoneNumber?.trim() ?? '';
    final resolvedMobile = address.resolvedMobile(authPhone);

    final payload = sanitizeCallableData({
      'items': items
          .where((e) => !e.isComboLine)
          .map(OrderLineSnapshot.fromCartItem)
          .toList(),
      'comboItems': items
          .where((e) => e.isComboLine)
          .map((e) => e.toMap())
          .toList(),
      'bill': bill.toMap(),
      if (coupon != null) 'coupon': coupon.toMap(),
      'address': {
        'id': address.id,
        'name': address.name.trim(),
        'mobile': resolvedMobile,
        'address': address.address,
        'area': address.area,
        'city': address.city,
        'type': address.type,
      },
      'currentLocation': currentAddressString,
      'lat': currentLatLng.latitude,
      'lng': currentLatLng.longitude,
      if (slot != null) 'delivery_slot': slot.toMap(),
      if (slot != null) 'deliverySlot': slot.toMap(),
      'delivery_instructions': instructions.legacyText,
      'deliveryInstructions': instructions.toMap(),
      'paymentMethod': paymentMethod.id,
      if (paymentRef != null) 'paymentRef': paymentRef,
      if (paymentRef != null) 'razorpay_payment_id': paymentRef,
      if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
      if (razorpaySignature != null) 'razorpay_signature': razorpaySignature,
      if (tipAmount > 0) 'tipAmount': tipAmount.round(),
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotencyKey': idempotencyKey,
    });
    debugCallableData(functionName, payload);

    final res = await _callPlaceOrder(payload);

    final data = res.data;
    if (data is Map && data['orderId'] != null) {
      final orderId = data['orderId'].toString();
      if (data['duplicate'] == true) {
        debugPrint(
          'ORDER CALLABLE DEDUPE function=$functionName orderId=$orderId',
        );
      }
      return orderId;
    }
    throw StateError('Invalid response from $functionName');
  }

  /// True for errors where the server may still be processing the first request.
  static bool isTransientFunctionsError(FirebaseFunctionsException e) {
    return e.code == 'deadline-exceeded' ||
        e.code == 'unavailable' ||
        e.code == 'internal' ||
        e.code == 'unknown';
  }

  Future<HttpsCallableResult<dynamic>> _callPlaceOrder(
    Map<String, dynamic> payload,
  ) async {
    final injected = _fn;
    if (injected != null) {
      return _callRegion(injected, 'injected', payload);
    }

    FirebaseFunctionsException? lastFunctionsError;
    Object? lastError;
    StackTrace? lastStack;

    for (final region in _regions) {
      try {
        return await _callRegion(
          FirebaseFunctions.instanceFor(region: region),
          region,
          payload,
        );
      } on FirebaseFunctionsException catch (e, stack) {
        lastFunctionsError = e;
        lastStack = stack;
        _logFunctionsError(e, stack, region);
        if (!_shouldTryNextRegion(e)) rethrow;
      } catch (e, stack) {
        lastError = e;
        lastStack = stack;
        debugPrint(
          'ORDER CALLABLE ERROR function=$functionName region=$region error=$e',
        );
        debugPrintStack(stackTrace: stack);
        rethrow;
      }
    }

    if (lastFunctionsError != null) {
      Error.throwWithStackTrace(
        lastFunctionsError,
        lastStack ?? StackTrace.current,
      );
    }
    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStack ?? StackTrace.current);
    }
    throw StateError('Order service unavailable');
  }

  Future<HttpsCallableResult<dynamic>> _callRegion(
    FirebaseFunctions functions,
    String region,
    Map<String, dynamic> payload,
  ) async {
    debugPrint('ORDER CALLABLE START function=$functionName region=$region');
    return functions.httpsCallable(functionName).call(payload);
  }

  bool _shouldTryNextRegion(FirebaseFunctionsException e) {
    return e.code == 'not-found' || e.code == 'unavailable';
  }

  void _logFunctionsError(
    FirebaseFunctionsException e,
    StackTrace stack,
    String region,
  ) {
    debugPrint(
      'ORDER CALLABLE ERROR function=$functionName region=$region '
      'code=${e.code} message=${e.message} details=${e.details}',
    );
    debugPrintStack(stackTrace: stack);
  }
}
