import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/cart_models.dart';

/// Reads `coupons/` collection (legacy + advanced schema).
class CouponService {
  CouponService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<CouponEntry>> watchActive() {
    return _firestore.collection('coupons').snapshots().map((snap) {
      return snap.docs
          .map((d) => CouponEntry.fromDoc(d))
          .where((c) => c.isActive && !c.isExpired && !c.isNotStarted)
          .toList();
    });
  }

  Future<List<CouponEntry>> fetchActive() async {
    final snap = await _firestore.collection('coupons').get();
    return snap.docs
        .map((d) => CouponEntry.fromDoc(d))
        .where((c) => c.isActive && !c.isExpired && !c.isNotStarted)
        .toList();
  }
}

class CouponEntry {
  final String id;
  final String code;
  final String title;
  final int discountPercent;
  final int flatAmount;
  final bool isActive;
  final int minOrderValue;
  final int maxDiscountAmount;
  final String description;
  final String couponType;
  final bool freeDelivery;
  final bool firstOrderOnly;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final List<String> applicableCategoryIds;
  final List<String> applicableVendorIds;

  CouponEntry({
    required this.id,
    required this.code,
    this.title = '',
    required this.discountPercent,
    required this.flatAmount,
    required this.isActive,
    required this.minOrderValue,
    required this.maxDiscountAmount,
    required this.description,
    required this.couponType,
    required this.freeDelivery,
    required this.firstOrderOnly,
    this.startDate,
    this.expiryDate,
    this.applicableCategoryIds = const [],
    this.applicableVendorIds = const [],
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isNotStarted =>
      startDate != null && startDate!.isAfter(DateTime.now());

  bool get isFirstOrderOffer =>
      firstOrderOnly || couponType == 'first_order';

  /// Quick eligibility (min order only — full rules on apply via Cloud Function).
  bool isClientEligible(double subtotal) =>
      isActive && !isExpired && !isNotStarted && subtotal >= minOrderValue;

  String get displayDiscount {
    if (freeDelivery && discountPercent <= 0 && flatAmount <= 0) {
      return 'FREE DELIVERY';
    }
    if (flatAmount > 0) return '₹$flatAmount OFF';
    if (discountPercent > 0) return '$discountPercent% OFF';
    return 'OFFER';
  }

  /// Blinkit-style subtitle under the coupon code.
  String get displaySubtitle {
    if (description.trim().isNotEmpty) return description.trim();
    if (title.trim().isNotEmpty) return title.trim();
    final buf = StringBuffer(displayDiscount);
    if (maxDiscountAmount > 0 && discountPercent > 0) {
      buf.write(' up to ₹$maxDiscountAmount');
    }
    if (minOrderValue > 0) {
      buf.write(' on orders above ₹$minOrderValue');
    } else if (freeDelivery) {
      buf.write(' on your order');
    }
    return buf.toString();
  }

  factory CouponEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    DateTime? expiry;
    DateTime? start;
    final exp = m['expiry_date'] ?? m['expiresAt'];
    if (exp is Timestamp) expiry = exp.toDate();
    final st = m['start_date'] ?? m['startDate'];
    if (st is Timestamp) start = st.toDate();

    final type = (m['coupon_type'] ?? '').toString();
    List<String> readIds(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return CouponEntry(
      id: d.id,
      code: (m['code'] ?? '').toString().toUpperCase(),
      title: (m['title'] ?? '').toString(),
      discountPercent: (m['discount'] as num?)?.toInt() ?? 0,
      flatAmount: (m['flat_amount'] as num?)?.toInt() ?? 0,
      isActive: m['is_active'] != false && m['isActive'] != false,
      minOrderValue:
          (m['minimum_order_amount'] as num?)?.toInt() ??
          (m['minOrderValue'] as num?)?.toInt() ??
          0,
      maxDiscountAmount: (m['maximum_discount_amount'] as num?)?.toInt() ?? 0,
      description: (m['description'] ?? '').toString(),
      couponType: type.isEmpty ? 'percentage_discount' : type,
      freeDelivery: m['free_delivery'] == true || type == 'free_delivery',
      firstOrderOnly: m['first_order_only'] == true || type == 'first_order',
      startDate: start,
      expiryDate: expiry,
      applicableCategoryIds: readIds(
        m['applicable_category_ids'] ?? m['applicableCategories'],
      ),
      applicableVendorIds: readIds(
        m['applicable_vendor_ids'] ?? m['applicableVendors'],
      ),
    );
  }

  AppliedCoupon toApplied() => AppliedCoupon(
        id: id,
        code: code,
        discountPercent: discountPercent,
        flatAmount: flatAmount.toDouble(),
        maxDiscountAmount: maxDiscountAmount.toDouble(),
        freeDelivery: freeDelivery,
        couponType: couponType,
        firstOrderOnly: firstOrderOnly,
      );
}
