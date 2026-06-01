import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

class OrderCancelApi {
  OrderCancelApi({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(
              app: Firebase.app(),
              region: _region,
            );

  static const _region = 'us-central1';
  final FirebaseFunctions _fn;

  Future<void> cancelByCustomer({
    required String orderId,
    String? reason,
  }) async {
    try {
      await _fn.httpsCallable('cancelOrderByCustomer').call({
        'orderId': orderId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not cancel order');
    }
  }
}
