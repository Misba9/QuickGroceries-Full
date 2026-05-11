import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure helpers for admin analytics — reads both legacy and modern order docs.
abstract final class OrderAnalyticsParser {
  static DateTime? parseCreatedAt(Map<String, dynamic> d) {
    final ca = d['createdAt'];
    if (ca is Timestamp) return ca.toDate();
    if (ca is DateTime) return ca;
    final raw = d['created_date'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static bool isCancelled(Map<String, dynamic> d) {
    if (d['isCancelled'] == true) return true;
    final s = (d['status'] ?? d['order_status'] ?? '').toString().toLowerCase();
    return s.contains('cancel');
  }

  static bool paymentFailed(Map<String, dynamic> d) {
    return (d['paymentStatus'] ?? '').toString().toLowerCase() == 'failed';
  }

  static bool isDelivered(Map<String, dynamic> d) {
    if (d['isDelivered'] == true) return true;
    final st = (d['status'] ?? '').toString().toLowerCase();
    if (st == 'delivered') return true;
    final legacy = (d['order_status'] ?? '').toString().toLowerCase();
    return legacy == 'delivered';
  }

  /// Eligible for **real revenue**: delivered, not cancelled, payment not failed.
  static bool isRevenueEligible(Map<String, dynamic> d) {
    if (!isDelivered(d)) return false;
    if (isCancelled(d)) return false;
    if (paymentFailed(d)) return false;
    return true;
  }

  static bool isPending(Map<String, dynamic> d) {
    if (isCancelled(d)) return false;
    if (isDelivered(d)) return false;
    return true;
  }

  static String customerUid(Map<String, dynamic> d) =>
      (d['uuid'] ?? d['userId'] ?? '').toString();

  /// Net billable amount using [bill] when present, else legacy line items.
  ///
  /// Preferred: `bill.total` (already reflects fees, tax, coupon discount).
  /// Fallback formula: subtotal + platform + delivery + handling + surge + tax
  /// − couponDiscount − refundAmount.
  static double revenueFromOrder(Map<String, dynamic> d) {
    final bill = d['bill'];
    if (bill is Map) {
      final total = bill['total'];
      if (total is num) return total.toDouble();
      final sub = (bill['subtotal'] as num?)?.toDouble() ?? 0;
      final plat = (bill['platformFee'] as num?)?.toDouble() ?? 0;
      final del = (bill['deliveryFee'] as num?)?.toDouble() ?? 0;
      final hand = (bill['handlingCharge'] as num?)?.toDouble() ?? 0;
      final surge = (bill['surgeFee'] as num?)?.toDouble() ?? 0;
      final tax = (bill['tax'] as num?)?.toDouble() ?? 0;
      final disc = (bill['couponDiscount'] as num?)?.toDouble() ?? 0;
      final refund = (bill['refundAmount'] as num?)?.toDouble() ?? 0;
      return sub + plat + del + hand + surge + tax - disc - refund;
    }
    double sub = 0;
    for (final p in (d['products'] as List?) ?? const []) {
      if (p is Map<String, dynamic>) {
        final price = (p['price'] ?? 0).toDouble();
        final qty = (p['itemCount'] ?? 0) as num? ?? 0;
        sub += price * qty.toInt();
      }
    }
    final del = (d['delivery_charge'] ?? 0).toDouble();
    final pf = (d['platform_fee'] ?? d['platformFee'] ?? 0).toDouble();
    final disc = (d['discount_total'] ?? d['discount'] ?? 0).toDouble();
    final refund = (d['refund_amount'] ?? 0).toDouble();
    return sub + del + pf - disc - refund;
  }

  static double refundFromOrder(Map<String, dynamic> d) {
    final bill = d['bill'];
    if (bill is Map && bill['refundAmount'] is num) {
      return (bill['refundAmount'] as num).toDouble();
    }
    return (d['refund_amount'] ?? 0).toDouble();
  }

  static double discountFromOrder(Map<String, dynamic> d) {
    final bill = d['bill'];
    if (bill is Map && bill['couponDiscount'] is num) {
      return (bill['couponDiscount'] as num).toDouble();
    }
    final c = d['coupon'];
    if (c is Map && c['discountValue'] is num) {
      return (c['discountValue'] as num).toDouble();
    }
    return 0;
  }

  static Duration? deliveryDuration(Map<String, dynamic> d) {
    final start = _parseTsOrString(d['confrimTime']) ?? parseCreatedAt(d);
    final end = _parseTsOrString(d['deliveredTime']) ??
        _parseTsOrString(d['orderDeliveredTime']);
    if (start == null || end == null) return null;
    final diff = end.difference(start);
    return diff.isNegative ? null : diff;
  }

  static DateTime? _parseTsOrString(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static String? zoneKey(Map<String, dynamic> d) {
    final snap = d['address_snapshot'];
    if (snap is Map) {
      final area = snap['area']?.toString();
      if (area != null && area.isNotEmpty) return area;
    }
    final addr = d['address']?.toString() ?? '';
    if (addr.length < 3) return null;
    return addr.length > 24 ? addr.substring(0, 24) : addr;
  }
}
