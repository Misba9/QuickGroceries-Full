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

  Future<Map<String, dynamic>> confirmDelivery({
    required String orderId,
    required String riderId,
    required int deliveryDurationSec,
    required double distanceTravelledKm,
  }) async {
    final payload = sanitizeCallableData({
      'orderId': orderId,
      'riderId': riderId,
      'deliveryDurationSec': deliveryDurationSec,
      'distanceTravelledKm': distanceTravelledKm,
    });
    debugCallableData('confirmDelivery', payload);

    try {
      final res = await _fn.httpsCallable('confirmDelivery').call(payload);
      final data = res.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return {};
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Delivery confirmation failed');
    }
  }

  Future<void> reportCustomerNotReachable({
    required String orderId,
    required String riderId,
    String? note,
  }) async {
    final payload = sanitizeCallableData({
      'orderId': orderId,
      'riderId': riderId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    debugCallableData('reportCustomerNotReachable', payload);
    try {
      await _fn.httpsCallable('reportCustomerNotReachable').call(payload);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not report issue');
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
