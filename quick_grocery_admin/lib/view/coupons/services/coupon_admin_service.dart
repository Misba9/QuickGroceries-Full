import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/view/coupons/models/admin_coupon_model.dart';
import 'package:quick_grocery_admin/view/coupons/models/coupon_type.dart';

class CouponAdminService {
  CouponAdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<AdminCouponModel>> watchCoupons() {
    return _db.collection('coupons').snapshots().map((s) {
      final list = s.docs.map(AdminCouponModel.fromDoc).toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  Future<void> createCoupon(AdminCouponModel coupon) async {
    await _db.collection('coupons').add({
      ...coupon.toFirestore(),
      'used_count': 0,
      'analytics_total_usage': 0,
      'analytics_failed_attempts': 0,
      'analytics_revenue': 0,
      'analytics_first_order_users': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCoupon(AdminCouponModel coupon) async {
    await _db.collection('coupons').doc(coupon.id).update(coupon.toFirestore());
  }

  Future<void> deleteCoupon(String id) async {
    await _db.collection('coupons').doc(id).delete();
  }

  List<AdminCouponModel> filterCoupons(
    List<AdminCouponModel> coupons, {
    required String search,
    required CouponListFilter filter,
  }) {
    var list = coupons;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (c) =>
                c.code.toLowerCase().contains(q) ||
                c.description.toLowerCase().contains(q) ||
                c.couponType.label.toLowerCase().contains(q),
          )
          .toList();
    }

    switch (filter) {
      case CouponListFilter.active:
        list = list
            .where((c) => c.isActive && !c.isExpired && !c.isNotStarted)
            .toList();
        break;
      case CouponListFilter.expired:
        list = list.where((c) => c.isExpired).toList();
        break;
      case CouponListFilter.firstOrder:
        list = list.where((c) => c.firstOrderOnly).toList();
        break;
      case CouponListFilter.vendorSpecific:
        list = list
            .where((c) => c.couponType == CouponType.vendorSpecific)
            .toList();
        break;
      case CouponListFilter.all:
        break;
    }
    return list;
  }

  CouponAnalyticsSummary summarize(List<AdminCouponModel> coupons) {
    if (coupons.isEmpty) return CouponAnalyticsSummary.empty;

    var totalUsage = 0;
    var failed = 0;
    var firstOrder = 0;
    var revenue = 0.0;
    String topCode = '—';
    var topCount = 0;

    for (final c in coupons) {
      totalUsage += c.analyticsTotalUsage;
      failed += c.analyticsFailedAttempts;
      firstOrder += c.analyticsFirstOrderUsers;
      revenue += c.analyticsRevenue;
      final usage = c.usedCount > 0 ? c.usedCount : c.analyticsTotalUsage;
      if (usage > topCount) {
        topCount = usage;
        topCode = c.code;
      }
    }

    return CouponAnalyticsSummary(
      totalUsage: totalUsage,
      totalRevenue: revenue,
      firstOrderUsers: firstOrder,
      failedAttempts: failed,
      mostUsedCouponCode: topCode,
      mostUsedCount: topCount,
    );
  }

  Future<List<MapEntry<String, String>>> fetchVendorOptions() async {
    final snap = await _db.collection('vendors').get();
    return snap.docs
        .map((d) {
          final name = (d.data()['shop_name'] ?? d.data()['first_name'] ?? d.id)
              .toString();
          return MapEntry(d.id, name);
        })
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  Future<List<MapEntry<String, String>>> fetchCategoryOptions() async {
    final snap = await _db.collection('categories').get();
    return snap.docs
        .map((d) => MapEntry(d.id, (d.data()['name'] ?? d.id).toString()))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  Future<List<MapEntry<String, String>>> fetchProductOptions({
    int limit = 200,
  }) async {
    final snap = await _db.collection('products').limit(limit).get();
    return snap.docs
        .map((d) => MapEntry(d.id, (d.data()['name'] ?? d.id).toString()))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }
}
