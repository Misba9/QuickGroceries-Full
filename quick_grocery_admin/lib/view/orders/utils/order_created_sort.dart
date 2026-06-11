import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Sort [OrderModel] lists newest-first (used after Firestore fetch/stream).
int compareOrdersNewestFirst(OrderModel a, OrderModel b) {
  return _sortAt(b).compareTo(_sortAt(a));
}

DateTime _sortAt(OrderModel order) {
  final parsed = OpsFirestoreHelpers.createdAt({
    'id': order.id,
    'created_date': order.createdDate,
  });
  return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
}
