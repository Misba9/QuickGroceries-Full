import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/view/coupons/models/coupon_type.dart';

class AdminCouponModel {
  AdminCouponModel({
    required this.id,
    required this.code,
    required this.couponType,
    required this.discountPercent,
    required this.flatAmount,
    required this.minimumOrderAmount,
    required this.maximumDiscountAmount,
    required this.startDate,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.perUserLimit,
    required this.applicableVendorIds,
    required this.applicableProductIds,
    required this.applicableCategoryIds,
    required this.freeDelivery,
    required this.firstOrderOnly,
    required this.onePerDevice,
    required this.isActive,
    required this.description,
    required this.analyticsTotalUsage,
    required this.analyticsFailedAttempts,
    required this.analyticsRevenue,
    required this.analyticsFirstOrderUsers,
    required this.createdAt,
  });

  final String id;
  final String code;
  final CouponType couponType;
  final int discountPercent;
  final int flatAmount;
  final int minimumOrderAmount;
  final int maximumDiscountAmount;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final int usageLimit;
  final int usedCount;
  final int perUserLimit;
  final List<String> applicableVendorIds;
  final List<String> applicableProductIds;
  final List<String> applicableCategoryIds;
  final bool freeDelivery;
  final bool firstOrderOnly;
  final bool onePerDevice;
  final bool isActive;
  final String description;
  final int analyticsTotalUsage;
  final int analyticsFailedAttempts;
  final double analyticsRevenue;
  final int analyticsFirstOrderUsers;
  final DateTime? createdAt;

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get isNotStarted =>
      startDate != null && startDate!.isAfter(DateTime.now());

  String get statusLabel {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isNotStarted) return 'Scheduled';
    return 'Active';
  }

  factory AdminCouponModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? {};
    return AdminCouponModel.fromMap(m, doc.id);
  }

  factory AdminCouponModel.fromMap(Map<String, dynamic> m, String id) {
    DateTime? readTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    List<String> readList(dynamic v) {
      if (v is! List) return [];
      return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }

    final type = CouponType.fromId(m['coupon_type']?.toString());
    return AdminCouponModel(
      id: id,
      code: (m['code'] ?? '').toString().toUpperCase(),
      couponType: type,
      discountPercent: (m['discount'] as num?)?.toInt() ?? 0,
      flatAmount: (m['flat_amount'] as num?)?.toInt() ?? 0,
      minimumOrderAmount:
          (m['minimum_order_amount'] as num?)?.toInt() ??
          (m['minOrderValue'] as num?)?.toInt() ??
          0,
      maximumDiscountAmount:
          (m['maximum_discount_amount'] as num?)?.toInt() ?? 0,
      startDate: readTs(m['start_date']),
      expiryDate: readTs(m['expiry_date'] ?? m['expiresAt']),
      usageLimit: (m['usage_limit'] as num?)?.toInt() ?? 0,
      usedCount: (m['used_count'] as num?)?.toInt() ?? 0,
      perUserLimit: (m['per_user_limit'] as num?)?.toInt() ?? 1,
      applicableVendorIds: readList(m['applicable_vendor_ids']),
      applicableProductIds: readList(m['applicable_product_ids']),
      applicableCategoryIds: readList(m['applicable_category_ids']),
      freeDelivery: m['free_delivery'] == true || type.isFreeDelivery,
      firstOrderOnly:
          m['first_order_only'] == true || type.isFirstOrder,
      onePerDevice: m['one_per_device'] == true,
      isActive: m['is_active'] != false && m['isActive'] != false,
      description: (m['description'] ?? '').toString(),
      analyticsTotalUsage:
          (m['analytics_total_usage'] as num?)?.toInt() ?? 0,
      analyticsFailedAttempts:
          (m['analytics_failed_attempts'] as num?)?.toInt() ?? 0,
      analyticsRevenue: (m['analytics_revenue'] as num?)?.toDouble() ?? 0,
      analyticsFirstOrderUsers:
          (m['analytics_first_order_users'] as num?)?.toInt() ?? 0,
      createdAt: readTs(m['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code.trim().toUpperCase(),
      'coupon_type': couponType.id,
      'discount': discountPercent,
      'flat_amount': flatAmount,
      'minimum_order_amount': minimumOrderAmount,
      'maximum_discount_amount': maximumDiscountAmount,
      'minOrderValue': minimumOrderAmount,
      if (startDate != null) 'start_date': Timestamp.fromDate(startDate!),
      if (expiryDate != null) 'expiry_date': Timestamp.fromDate(expiryDate!),
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'per_user_limit': perUserLimit,
      'applicable_vendor_ids': applicableVendorIds,
      'applicable_product_ids': applicableProductIds,
      'applicable_category_ids': applicableCategoryIds,
      'free_delivery': freeDelivery || couponType.isFreeDelivery,
      'first_order_only': firstOrderOnly || couponType.isFirstOrder,
      'one_per_device': onePerDevice,
      'is_active': isActive,
      'isActive': isActive,
      'description': description,
    };
  }
}

class CouponAnalyticsSummary {
  const CouponAnalyticsSummary({
    required this.totalUsage,
    required this.totalRevenue,
    required this.firstOrderUsers,
    required this.failedAttempts,
    required this.mostUsedCouponCode,
    required this.mostUsedCount,
  });

  final int totalUsage;
  final double totalRevenue;
  final int firstOrderUsers;
  final int failedAttempts;
  final String mostUsedCouponCode;
  final int mostUsedCount;

  static const empty = CouponAnalyticsSummary(
    totalUsage: 0,
    totalRevenue: 0,
    firstOrderUsers: 0,
    failedAttempts: 0,
    mostUsedCouponCode: '—',
    mostUsedCount: 0,
  );
}
