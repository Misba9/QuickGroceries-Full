import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quick_grocery_delivery/core/firebase/callable_payload.dart';

class DeliveryOpsApi {
  DeliveryOpsApi({FirebaseFunctions? functions})
      : _fn = functions,
        _regions = functions == null
            ? const ['us-central1', 'asia-south1']
            : const [];

  final FirebaseFunctions? _fn;
  final List<String> _regions;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

    return _callMap('confirmDelivery', payload);
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
    await _callMap('reportCustomerNotReachable', payload);
  }

  Future<Map<String, dynamic>> recordDeliveryPayment({
    required String orderId,
    required String riderId,
    required String collectionMethod,
  }) async {
    final payload = sanitizeCallableData({
      'orderId': orderId,
      'riderId': riderId,
      'collectionMethod': collectionMethod,
    });
    debugCallableData('recordDeliveryPaymentCallable', payload);
    try {
      return await _callMap('recordDeliveryPaymentCallable', payload);
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase();
      if (code == 'not-found' || code == 'unavailable') {
        return _recordPaymentDirectFirestore(
          orderId: orderId,
          riderId: riderId,
          collectionMethod: collectionMethod,
        );
      }
      throw Exception(e.message ?? 'Could not record payment');
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
      await _callMap('cancelOrderByRider', payload);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not cancel assignment');
    }
  }

  Future<Map<String, dynamic>> _callMap(
    String callableName,
    Map<String, dynamic> payload,
  ) async {
    if (_fn != null) {
      final res = await _fn.httpsCallable(callableName).call(payload);
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }

    FirebaseFunctionsException? last;
    for (final region in _regions) {
      try {
        final fn = FirebaseFunctions.instanceFor(
          app: Firebase.app(),
          region: region,
        );
        final res = await fn.httpsCallable(callableName).call(payload);
        final data = res.data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return {};
      } on FirebaseFunctionsException catch (e) {
        last = e;
        final code = e.code.toLowerCase();
        if (code != 'not-found' && code != 'unavailable') rethrow;
      }
    }
    if (last != null) throw last;
    throw Exception('Service unavailable');
  }

  Future<Map<String, dynamic>> _recordPaymentDirectFirestore({
    required String orderId,
    required String riderId,
    required String collectionMethod,
  }) async {
    final ref = _db.collection('orders').doc(orderId);
    double paidAmount = 0;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Order not found');
      final data = snap.data()!;
      final assigned =
          (data['deliveryBoyId'] ?? data['delivery_boy_id'] ?? '').toString();
      if (assigned.isEmpty || assigned != riderId) {
        throw Exception('You are not assigned to this order');
      }
      final method = (data['paymentMethod'] ?? data['payment_method'] ?? 'cod')
          .toString()
          .toLowerCase();
      if (method != 'cod' && method != 'cash_on_delivery') {
        throw Exception('This order is already paid online');
      }
      final alreadyPaid = data['isPaid'] == true ||
          ((data['paymentStatus'] ?? data['payment_status'] ?? '')
                  .toString()
                  .toLowerCase() ==
              'paid');
      if (alreadyPaid) {
        paidAmount = _orderGrandTotal(data);
        return;
      }
      paidAmount = _orderGrandTotal(data);
      if (paidAmount <= 0) throw Exception('Invalid order amount');

      tx.set(ref, {
        'paymentStatus': 'paid',
        'payment_status': 'paid',
        'isPaid': true,
        'collectionMethod': collectionMethod,
        'collection_method': collectionMethod,
        'paidAmount': paidAmount,
        'paid_amount': paidAmount,
        'paidAt': FieldValue.serverTimestamp(),
        'paid_at': FieldValue.serverTimestamp(),
        'collectedBy': riderId,
        'collected_by': riderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return {
      'ok': true,
      'orderId': orderId,
      'paidAmount': paidAmount,
      'collectionMethod': collectionMethod,
    };
  }

  static double _orderGrandTotal(Map<String, dynamic> data) {
    double n(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse('$v') ?? 0;
    }

    final bill = data['bill'];
    if (bill is Map) {
      final total = n(bill['grandTotal'] ?? bill['total']);
      if (total > 0) return total;
    }
    final products = (data['products'] as List?) ?? const [];
    var sum = 0.0;
    for (final raw in products) {
      if (raw is! Map) continue;
      final qty = n(raw['itemCount'] ?? raw['quantity']).clamp(1, 99999);
      final line = n(raw['totalPrice'] ?? raw['lineTotal']);
      if (line > 0) {
        sum += line;
      } else {
        sum += n(raw['price'] ?? raw['sellingPrice'] ?? raw['pricePaid']) * qty;
      }
    }
    return sum + n(data['deliveryCharge'] ?? data['delivery_charge']);
  }
}
