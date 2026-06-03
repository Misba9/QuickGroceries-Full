import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/delivery_tip_settings.dart';
import '../../cart/domain/cart_models.dart' show OrderStatus;

const _settingsDocPath = 'app_settings/delivery_tips';

/// Result of a successful tip increase on an order.
class TipUpdateResult {
  const TipUpdateResult({
    required this.orderId,
    required this.previousTip,
    required this.newTip,
    required this.delta,
    required this.deliveryPartnerId,
  });

  final String orderId;
  final double previousTip;
  final double newTip;
  final double delta;
  final String deliveryPartnerId;
}

/// User-facing tip errors (never show raw Firebase exceptions in UI).
class DeliveryTipException implements Exception {
  DeliveryTipException(this.message);

  final String message;

  @override
  String toString() => message;

  factory DeliveryTipException.unauthenticated() =>
      DeliveryTipException('Please sign in to add a tip.');

  factory DeliveryTipException.fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return DeliveryTipException(
          'You do not have permission to update this order.',
        );
      case 'not-found':
        return DeliveryTipException('Order not found.');
      case 'unavailable':
        return DeliveryTipException(
          'Network error. Check your connection and try again.',
        );
      default:
        return DeliveryTipException(
          e.message?.trim().isNotEmpty == true
              ? e.message!
              : 'Could not update tip. Please try again.',
        );
    }
  }
}

class DeliveryTipService {
  DeliveryTipService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  DeliveryTipSettings? _cachedSettings;

  Future<DeliveryTipSettings> fetchSettings({bool force = false}) async {
    if (!force && _cachedSettings != null) return _cachedSettings!;
    try {
      final snap = await _db.doc(_settingsDocPath).get();
      final settings = DeliveryTipSettings.fromMap(
        snap.exists ? snap.data() : null,
      );
      _cachedSettings = settings;
      if (kDebugMode) {
        debugPrint('TIP SETTINGS: enabled=${settings.enabled} max=${settings.maxTipAmount}');
      }
      return settings;
    } catch (e, stack) {
      debugPrint('TIP SETTINGS ERROR: $e');
      debugPrintStack(stackTrace: stack);
      _cachedSettings = DeliveryTipSettings.defaults();
      return _cachedSettings!;
    }
  }

  /// Increases tip by [delta] (never overwrites — always adds).
  Future<TipUpdateResult> addTipDelta({
    required String orderId,
    required int delta,
    bool allowAfterDelivered = false,
    String? paymentRef,
    String paymentStatus = 'pending',
  }) async {
    if (delta <= 0) {
      throw DeliveryTipException('Please enter a valid tip amount.');
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw DeliveryTipException.unauthenticated();
    }

    final settings = await fetchSettings();
    if (!settings.enabled) {
      throw DeliveryTipException('Delivery partner tips are currently disabled.');
    }

    final orderRef = _db.collection('orders').doc(orderId);
    double previousTip = 0;
    double newTip = 0;
    String deliveryPartnerId = '';

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(orderRef);
        if (!snap.exists) {
          throw DeliveryTipException('Order not found.');
        }
        final data = snap.data()!;
        final owner = _str(data['uuid']);
        if (owner != uid) {
          throw DeliveryTipException('This order does not belong to your account.');
        }
        if (data['isCancelled'] == true) {
          throw DeliveryTipException('This order was cancelled.');
        }

        final status = _resolveStatus(data);
        final delivered =
            data['isDelivered'] == true || status == OrderStatus.delivered;

        if (delivered && !allowAfterDelivered) {
          throw DeliveryTipException(
            'Tips can only be increased while your order is active.',
          );
        }
        if (!delivered && !_isActiveForTipIncrease(status)) {
          throw DeliveryTipException(
            'Tips can only be updated while your order is active.',
          );
        }

        previousTip = _currentTipAmount(data);
        newTip = previousTip + delta;
        if (newTip <= previousTip) {
          throw DeliveryTipException('Tip can only be increased, not reduced.');
        }
        if (newTip > settings.maxTipAmount) {
          throw DeliveryTipException(
            'Maximum tip is ₹${settings.maxTipAmount}.',
          );
        }

        deliveryPartnerId = _str(
          data['deliveryBoyId'] ?? data['delivery_boy_id'] ?? data['deliveryPartnerId'],
        );

        final billRaw = data['bill'] is Map
            ? Map<String, dynamic>.from(data['bill'] as Map)
            : <String, dynamic>{};
        final bill = _mergeTipIntoBill(billRaw, newTip);
        final tipStatus = delivered ? 'earned' : 'pending';

        final patch = <String, dynamic>{
          'bill': bill,
          'tipAmount': newTip.round(),
          'tipStatus': tipStatus,
          'tipUpdatedAt': FieldValue.serverTimestamp(),
        };
        if (previousTip <= 0) {
          patch['tipAddedAt'] = FieldValue.serverTimestamp();
        }

        tx.update(orderRef, patch);
      });
    } on DeliveryTipException {
      rethrow;
    } on FirebaseException catch (e, stack) {
      debugPrint('TIP FIREBASE ERROR: code=${e.code} message=${e.message}');
      debugPrintStack(stackTrace: stack);
      throw DeliveryTipException.fromFirebase(e);
    } catch (e, stack) {
      debugPrint('TIP ERROR: $e');
      debugPrintStack(stackTrace: stack);
      if (e is DeliveryTipException) rethrow;
      throw DeliveryTipException(
        'Could not update tip. Please try again.',
      );
    }

    final tipTxId = await _createTipTransaction(
      orderId: orderId,
      customerId: uid,
      deliveryPartnerId: deliveryPartnerId,
      amount: delta,
      paymentStatus: paymentStatus,
      paymentRef: paymentRef,
    );

    if (kDebugMode) {
      debugPrint(
        'TIP SUCCESS: orderId=$orderId oldTip=$previousTip newTip=$newTip '
        'delta=$delta tipTransaction=$tipTxId',
      );
    }

    return TipUpdateResult(
      orderId: orderId,
      previousTip: previousTip,
      newTip: newTip,
      delta: delta.toDouble(),
      deliveryPartnerId: deliveryPartnerId,
    );
  }

  /// Sets tip to [newTotal] (must be greater than current).
  Future<TipUpdateResult> setOrderTipTotal({
    required String orderId,
    required double newTotal,
    bool allowAfterDelivered = false,
    String? paymentRef,
    String paymentStatus = 'pending',
  }) async {
    final orderSnap = await _db.collection('orders').doc(orderId).get();
    if (!orderSnap.exists) {
      throw DeliveryTipException('Order not found.');
    }
    final current = _currentTipAmount(orderSnap.data() ?? {});
    final delta = newTotal.round() - current.round();
    if (delta <= 0) {
      throw DeliveryTipException('Tip must be higher than the current amount.');
    }
    return addTipDelta(
      orderId: orderId,
      delta: delta,
      allowAfterDelivered: allowAfterDelivered,
      paymentRef: paymentRef,
      paymentStatus: paymentStatus,
    );
  }

  Future<String> _createTipTransaction({
    required String orderId,
    required String customerId,
    required String deliveryPartnerId,
    required int amount,
    required String paymentStatus,
    String? paymentRef,
  }) async {
    try {
      final doc = await _db.collection('tip_transactions').add({
        'orderId': orderId,
        'customerId': customerId,
        'deliveryPartnerId': deliveryPartnerId,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentStatus': paymentStatus,
        if (paymentRef != null && paymentRef.isNotEmpty) 'paymentRef': paymentRef,
      });
      if (kDebugMode) {
        debugPrint('TIP TRANSACTION: id=${doc.id} amount=$amount status=$paymentStatus');
      }
      return doc.id;
    } catch (e, stack) {
      debugPrint('TIP TRANSACTION ERROR (order tip still saved): $e');
      debugPrintStack(stackTrace: stack);
      return '';
    }
  }

  static double _currentTipAmount(Map<String, dynamic> data) {
    final direct = _num(data['tipAmount']);
    if (direct > 0) return direct;
    final bill = data['bill'];
    if (bill is Map) {
      return _num(bill['deliveryPartnerTip'] ?? bill['tipAmount']);
    }
    return 0;
  }

  static OrderStatus _resolveStatus(Map<String, dynamic> data) {
    if (data['isCancelled'] == true) return OrderStatus.cancelled;
    if (data['isDelivered'] == true) return OrderStatus.delivered;
    final modern = (data['status'] as String?)?.trim();
    if (modern != null && modern.isNotEmpty) {
      return OrderStatus.fromId(modern);
    }
    final legacy = (data['order_status'] as String?)?.toLowerCase() ?? '';
    if (legacy.contains('cancel')) return OrderStatus.cancelled;
    if (legacy.contains('deliver')) return OrderStatus.delivered;
    if (legacy.contains('way') || legacy.contains('picked')) {
      return OrderStatus.outForDelivery;
    }
    if (legacy.contains('assign') || legacy.contains('rider')) {
      return OrderStatus.deliveryAssigned;
    }
    return OrderStatus.orderPlaced;
  }

  static bool _isActiveForTipIncrease(OrderStatus status) {
    return status == OrderStatus.orderPlaced ||
        status == OrderStatus.deliveryAssigned ||
        status == OrderStatus.outForDelivery;
  }

  static Map<String, dynamic> _mergeTipIntoBill(
    Map<String, dynamic> bill,
    double tipAmount,
  ) {
    final baseTotal = _num(bill['total'] ?? bill['grandTotal']);
    final previousTip = _num(bill['deliveryPartnerTip'] ?? bill['tipAmount']);
    final rounded = double.parse(
      (baseTotal - previousTip + tipAmount).toStringAsFixed(2),
    );
    return {
      ...bill,
      'deliveryPartnerTip': tipAmount.round(),
      'tipAmount': tipAmount.round(),
      'total': rounded,
      'grandTotal': rounded,
    };
  }

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString().trim();
  }
}

final deliveryTipServiceProvider = DeliveryTipService();
