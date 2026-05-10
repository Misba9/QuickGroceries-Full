import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cart_models.dart';

/// Reads `coupons/` collection.
///
/// Document shape (legacy + new fields):
/// ```
/// {
///   code: "WELCOME10",
///   discount: 10,                 // integer percent
///   isActive: true,               // optional, default true
///   minOrderValue: 199,           // optional, hides coupon below this
///   description: "10% off your first order"  // optional
/// }
/// ```
class CouponService {
  CouponService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<CouponEntry>> watchActive() {
    return _firestore.collection('coupons').snapshots().map((snap) {
      return snap.docs
          .map((d) => CouponEntry.fromDoc(d))
          .where((c) => c.isActive)
          .toList();
    });
  }

  Future<List<CouponEntry>> fetchActive() async {
    final snap = await _firestore.collection('coupons').get();
    return snap.docs
        .map((d) => CouponEntry.fromDoc(d))
        .where((c) => c.isActive)
        .toList();
  }
}

class CouponEntry {
  final String id;
  final String code;
  final int discountPercent;
  final bool isActive;
  final int minOrderValue;
  final String description;

  CouponEntry({
    required this.id,
    required this.code,
    required this.discountPercent,
    required this.isActive,
    required this.minOrderValue,
    required this.description,
  });

  factory CouponEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return CouponEntry(
      id: d.id,
      code: (m['code'] ?? '').toString(),
      discountPercent: (m['discount'] as num?)?.toInt() ?? 0,
      isActive: m['isActive'] as bool? ?? true,
      minOrderValue: (m['minOrderValue'] as num?)?.toInt() ?? 0,
      description: (m['description'] ?? '').toString(),
    );
  }

  AppliedCoupon toApplied() => AppliedCoupon(
        id: id,
        code: code,
        discountPercent: discountPercent,
      );
}
