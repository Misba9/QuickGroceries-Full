import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared parsing and order classification for ops dashboard streams.
abstract final class OpsFirestoreHelpers {
  static DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate().toLocal();
    if (v is DateTime) return v.toLocal();
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
    }
    if (v is num) {
      final ms = v.toInt();
      if (ms > 0) return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    }
    if (v is Map) {
      final sec = v['_seconds'] ?? v['seconds'];
      if (sec is num) {
        final nano = (v['_nanoseconds'] ?? v['nanoseconds'] ?? 0) as num;
        return DateTime.fromMillisecondsSinceEpoch(
          sec.toInt() * 1000 + nano ~/ 1000000,
        ).toLocal();
      }
    }
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }

  static DateTime startOfLocalDay([DateTime? ref]) {
    final n = (ref ?? DateTime.now()).toLocal();
    return DateTime(n.year, n.month, n.day);
  }

  static bool isOnLocalDay(DateTime? dt, DateTime dayStart) {
    if (dt == null) return false;
    final local = dt.toLocal();
    final start = startOfLocalDay(local);
    return !local.isBefore(start) && local.isBefore(start.add(const Duration(days: 1)));
  }

  static bool isInLocalRange(DateTime? dt, DateTime start, DateTime endExclusive) {
    if (dt == null) return false;
    final local = dt.toLocal();
    return !local.isBefore(start) && local.isBefore(endExclusive);
  }

  static String orderStatusRaw(Map<String, dynamic> d) =>
      (d['order_status'] ?? d['status'] ?? '').toString().toLowerCase().trim();

  static bool isCancelled(Map<String, dynamic> d) {
    if (d['isCancelled'] == true) return true;
    final s = orderStatusRaw(d);
    return s.contains('cancel') || s.contains('refund');
  }

  static bool isDelivered(Map<String, dynamic> d) {
    if (isCancelled(d)) return false;
    if (d['isDelivered'] == true) return true;
    return orderStatusRaw(d).contains('deliver');
  }

  static bool isActive(Map<String, dynamic> d) =>
      !isCancelled(d) && !isDelivered(d);

  static double orderTotal(Map<String, dynamic> d) {
    final bill = d['bill'];
    if (bill is Map && bill['total'] != null) {
      return (bill['total'] as num).toDouble();
    }
    var sum = 0.0;
    final products = d['products'];
    if (products is List) {
      for (final p in products) {
        if (p is! Map) continue;
        final price = (p['price'] as num?)?.toDouble() ?? 0;
        final qty = (p['itemCount'] as num?)?.toInt() ?? 1;
        sum += price * qty;
      }
    }
    sum += (d['delivery_charge'] as num?)?.toDouble() ?? 0;
    return sum;
  }

  static String paymentStatusLabel(Map<String, dynamic> d) {
    final ps = (d['paymentStatus'] ?? d['payment_status'] ?? '').toString();
    if (ps.isNotEmpty) return ps;
    final paid = d['isPaid'] == true;
    final method = (d['paymentMethod'] ?? d['payment_method'] ?? '')
        .toString()
        .toUpperCase();
    if (method.isNotEmpty) return paid ? '$method · Paid' : method;
    return paid ? 'Paid' : 'COD';
  }

  static bool isCod(Map<String, dynamic> d) {
    if (d['isPaid'] == true) return false;
    final m = (d['paymentMethod'] ?? d['payment_method'] ?? '')
        .toString()
        .toLowerCase();
    return m.isEmpty || m.contains('cod');
  }

  static bool isExpress(Map<String, dynamic> d) {
    final t = (d['delivery_type'] ?? d['deliveryType'] ?? '')
        .toString()
        .toLowerCase();
    return t.contains('express');
  }

  static Set<String> vendorIdsFromOrder(Map<String, dynamic> d) {
    final ids = <String>{};
    final products = d['products'];
    if (products is! List) return ids;
    for (final p in products) {
      if (p is! Map) continue;
      final id = (p['vendor_id'] ?? p['vendorId'] ?? '').toString();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  static String riderId(Map<String, dynamic> d) =>
      (d['deliveryBoyId'] ??
              d['delivery_boy_id'] ??
              d['assignedDeliveryBoyId'] ??
              '')
          .toString();

  static DateTime? createdAt(Map<String, dynamic> d) {
    for (final key in ['createdAt', 'created_date', 'createdDate']) {
      final parsed = parseDate(d[key]);
      if (parsed != null && parsed.millisecondsSinceEpoch > 0) {
        return parsed;
      }
    }

    final id = d['id']?.toString() ?? '';
    final idMs = int.tryParse(id);
    if (idMs != null && idMs > 0) {
      return DateTime.fromMillisecondsSinceEpoch(idMs).toLocal();
    }
    return null;
  }

  /// Newest-first comparator for raw Firestore order maps.
  static int compareOrdersNewestFirst(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final ta = createdAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = createdAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return tb.compareTo(ta);
  }

  static String shortOrderId(String id) =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
