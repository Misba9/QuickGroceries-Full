import 'package:quickgrocery/models/order_model.dart';

/// Sort [OrderModel] lists newest-first (used after Firestore fetch/stream).
int compareOrdersNewestFirst(OrderModel a, OrderModel b) {
  return _sortAt(b).compareTo(_sortAt(a));
}

DateTime _sortAt(OrderModel order) {
  final parsed = DateTime.tryParse(order.createdDate.trim());
  if (parsed != null && parsed.millisecondsSinceEpoch > 0) {
    return parsed;
  }

  final idMs = int.tryParse(order.id);
  if (idMs != null && idMs > 0) {
    return DateTime.fromMillisecondsSinceEpoch(idMs);
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
