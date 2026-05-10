import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cart_models.dart';

/// Persists per-user carts under `cart/{uid}`.
///
/// Document shape (kept flat for cheap reads on app cold-start):
/// ```
/// cart/{uid} = {
///   userId: <uid>,
///   items: [ CartItem.toMap(), ... ],
///   coupon: AppliedCoupon.toMap() | null,
///   subtotal: double,
///   deliveryFee: double,
///   tax: double,
///   total: double,
///   updatedAt: serverTimestamp,
///   clientId: <random per app boot, used to drop our own echoes>,
/// }
/// ```
class CartRepository {
  CartRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('cart').doc(uid);

  Stream<CartSnapshotData?> watch(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return CartSnapshotData.fromMap(data);
    });
  }

  Future<void> save({
    required String uid,
    required List<CartItem> items,
    required AppliedCoupon? coupon,
    required BillBreakdown bill,
    required String clientId,
  }) async {
    await _doc(uid).set({
      'userId': uid,
      'items': items.map((e) => e.toMap()).toList(),
      'coupon': coupon?.toMap(),
      'subtotal': bill.subtotal,
      'deliveryFee': bill.deliveryFee,
      'tax': bill.tax,
      'total': bill.total,
      'updatedAt': FieldValue.serverTimestamp(),
      'clientId': clientId,
    }, SetOptions(merge: false));
  }

  Future<void> clear(String uid) async {
    // Use delete so the doc disappears once order is placed; cheaper than
    // overwriting an empty array.
    await _doc(uid).delete();
  }
}

/// Read-side projection of the cart document.
class CartSnapshotData {
  final List<CartItem> items;
  final AppliedCoupon? coupon;
  final String? clientId;

  CartSnapshotData({
    required this.items,
    required this.coupon,
    required this.clientId,
  });

  factory CartSnapshotData.fromMap(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = <CartItem>[];
    if (rawItems is List) {
      for (final entry in rawItems) {
        if (entry is Map) {
          items.add(CartItem.fromMap(Map<String, dynamic>.from(entry)));
        }
      }
    }
    AppliedCoupon? coupon;
    final rawCoupon = data['coupon'];
    if (rawCoupon is Map) {
      coupon = AppliedCoupon.fromMap(Map<String, dynamic>.from(rawCoupon));
    }
    return CartSnapshotData(
      items: items,
      coupon: coupon,
      clientId: data['clientId']?.toString(),
    );
  }
}
