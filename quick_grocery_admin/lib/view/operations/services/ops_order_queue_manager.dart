import 'package:quick_grocery_admin/view/operations/models/ops_dashboard_models.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_priority.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_order_status_theme.dart';

/// Builds and filters the live active-order queue.
abstract final class OpsOrderQueueManager {
  static const defaultLimit = 50;

  static List<OpsLiveOrder> buildActiveQueue({
    required List<Map<String, dynamic>> orders,
    required Map<String, String> vendorNames,
    required Map<String, String> riderNames,
    required Set<String> previousActiveIds,
    int limit = defaultLimit,
  }) {
    final active = orders.where(OpsFirestoreHelpers.isActive).toList();
    active.sort(OpsFirestoreHelpers.compareOrdersNewestFirst);

    return active
        .take(limit)
        .map(
          (d) => OpsLiveOrder.fromMap(
            d,
            vendorNames: vendorNames,
            riderNames: riderNames,
            previousActiveIds: previousActiveIds,
          ),
        )
        .toList();
  }

  static List<OpsLiveOrder> filterQueue({
    required List<OpsLiveOrder> queue,
    String search = '',
    OpsQueueStatus? statusFilter,
    OpsOrderPriority? priorityFilter,
    bool highPriorityOnly = false,
  }) {
    var list = List<OpsLiveOrder>.from(queue);
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.id.toLowerCase().contains(q) ||
                o.customerName.toLowerCase().contains(q) ||
                o.vendorName.toLowerCase().contains(q) ||
                o.riderName.toLowerCase().contains(q) ||
                o.statusLabel.toLowerCase().contains(q),
          )
          .toList();
    }
    if (statusFilter != null) {
      list = list.where((o) => o.status == statusFilter).toList();
    }
    if (priorityFilter != null) {
      list = list.where((o) => o.priority == priorityFilter).toList();
    }
    if (highPriorityOnly) {
      list = list.where((o) => o.priority == OpsOrderPriority.high).toList();
    }
    return list;
  }
}
