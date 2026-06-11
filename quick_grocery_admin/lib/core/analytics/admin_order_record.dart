import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Normalized order row for shared admin analytics (Firestore map or [OrderModel]).
class AdminOrderRecord {
  const AdminOrderRecord({
    required this.id,
    required this.createdAt,
    required this.deliveredAt,
    required this.isDelivered,
    required this.isCancelled,
    required this.isPaid,
    required this.total,
    required this.deliveryBoyId,
    required this.address,
    required this.deliveryType,
    required this.orderStatus,
    required this.products,
  });

  final String id;
  final DateTime? createdAt;
  final DateTime? deliveredAt;
  final bool isDelivered;
  final bool isCancelled;
  final bool isPaid;
  final double total;
  final String deliveryBoyId;
  final String address;
  final String deliveryType;
  final String orderStatus;
  final List<AdminOrderProduct> products;

  bool get isActive => !isCancelled && !isDelivered;

  factory AdminOrderRecord.fromMap(Map<String, dynamic> d, {String? docId}) {
    return AdminOrderRecord(
      id: docId ?? d['id']?.toString() ?? '',
      createdAt: OpsFirestoreHelpers.createdAt(d),
      deliveredAt: _parse(
        d['deliveredTime'] ??
            d['orderDeliveredTime'] ??
            d['delivered_at'] ??
            d['deliveredAt'],
      ),
      isDelivered: _isDelivered(d),
      isCancelled: _isCancelled(d),
      isPaid: d['isPaid'] == true,
      total: _total(d),
      deliveryBoyId: (d['deliveryBoyId'] ?? d['delivery_boy_id'] ?? '').toString(),
      address: (d['address'] ?? '').toString(),
      deliveryType: (d['delivery_type'] ?? d['deliveryType'] ?? '').toString(),
      orderStatus: (d['order_status'] ?? d['status'] ?? '').toString(),
      products: _products(d['products']),
    );
  }

  factory AdminOrderRecord.fromOrderModel(OrderModel o) {
    return AdminOrderRecord(
      id: o.id,
      createdAt: OpsFirestoreHelpers.createdAt({
        'id': o.id,
        'created_date': o.createdDate,
      }),
      deliveredAt: DateTime.tryParse(o.orderDeliveredTime)?.toLocal(),
      isDelivered: o.isDelivered,
      isCancelled: o.isCancelled,
      isPaid: o.isPaid,
      total: o.getTotalAmount(),
      deliveryBoyId: o.deliveryBoyId,
      address: o.address,
      deliveryType: o.deliveryType,
      orderStatus: o.orderStatus,
      products: o.products
          .map(
            (p) => AdminOrderProduct(
              category: p.category,
              vendorId: p.vendorId,
              itemCount: p.itemCount,
            ),
          )
          .toList(),
    );
  }

  static DateTime? _parse(dynamic v) {
    if (v is Timestamp) return v.toDate().toLocal();
    if (v is DateTime) return v.toLocal();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  static bool _isCancelled(Map<String, dynamic> d) {
    if (d['isCancelled'] == true) return true;
    final s = (d['order_status'] ?? d['status'] ?? '').toString().toLowerCase();
    return s.contains('cancel') || s.contains('refund');
  }

  static bool _isDelivered(Map<String, dynamic> d) {
    if (_isCancelled(d)) return false;
    if (d['isDelivered'] == true) return true;
    return (d['order_status'] ?? d['status'] ?? '')
        .toString()
        .toLowerCase()
        .contains('deliver');
  }

  static double _total(Map<String, dynamic> d) {
    final bill = d['bill'];
    if (bill is Map && bill['total'] != null) {
      return (bill['total'] as num).toDouble();
    }
    var sum = 0.0;
    final products = d['products'];
    if (products is List) {
      for (final p in products) {
        if (p is! Map) continue;
        sum += ((p['price'] as num?)?.toDouble() ?? 0) *
            ((p['itemCount'] as num?)?.toInt() ?? 1);
      }
    }
    sum += (d['delivery_charge'] as num?)?.toDouble() ?? 0;
    return sum;
  }

  static List<AdminOrderProduct> _products(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (p) => AdminOrderProduct(
            category: (p['category'] ?? '').toString(),
            vendorId: (p['vendor_id'] ?? p['vendorId'] ?? '').toString(),
            itemCount: (p['itemCount'] as num?)?.toInt() ?? 1,
          ),
        )
        .toList();
  }
}

class AdminOrderProduct {
  const AdminOrderProduct({
    required this.category,
    required this.vendorId,
    required this.itemCount,
  });

  final String category;
  final String vendorId;
  final int itemCount;
}
