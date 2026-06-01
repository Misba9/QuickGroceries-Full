import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quick_grocery_delivery/core/firebase/callable_payload.dart';

class DeliveryOpsApi {
  DeliveryOpsApi({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            );

  static const _region = 'us-central1';

  final FirebaseFunctions _fn;

  Future<Map<String, dynamic>> confirmDeliveryWithOtp({
    required String orderId,
    required String riderId,
    required String otp,
    required int deliveryDurationSec,
    required double distanceTravelledKm,
  }) async {
    final payload = sanitizeCallableData({
      'orderId': orderId,
      'riderId': riderId,
      'otp': otp.trim(),
      'deliveryDurationSec': deliveryDurationSec,
      'distanceTravelledKm': distanceTravelledKm,
    });
    debugCallableData('confirmDeliveryWithOtp', payload);

    try {
      final res = await _fn
          .httpsCallable('confirmDeliveryWithOtp')
          .call(payload);
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Delivery confirmation failed');
    }
  }

  Future<void> cancelOrderByRider({
    required String orderId,
    required String riderId,
    String? reason,
  }) async {
    final payload = sanitizeCallableData({
      'orderId': orderId,
      'riderId': riderId,
      if (reason != null) 'reason': reason,
    });
    try {
      await _fn.httpsCallable('cancelOrderByRider').call(payload);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not cancel assignment');
    }
  }
}
