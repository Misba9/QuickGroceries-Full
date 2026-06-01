import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/view/operations/utils/ops_firestore_helpers.dart';

/// Per-rider order counters derived from live `orders` snapshots.
class DeliveryBoyOrderStats {
  const DeliveryBoyOrderStats({
    this.assigned = 0,
    this.active = 0,
    this.completed = 0,
  });

  final int assigned;
  final int active;
  final int completed;

  int get total => assigned + active + completed;

  static const empty = DeliveryBoyOrderStats();
}

/// Aggregates rider order stats from Firestore order documents.
abstract final class DeliveryBoyOrderStatsAggregator {
  static bool isInTransit(Map<String, dynamic> d) {
    final s = OpsFirestoreHelpers.orderStatusRaw(d);
    return s.contains('picked') ||
        s.contains('on the way') ||
        s.contains('on_the_way') ||
        s.contains('going') ||
        s.contains('shop') ||
        s.contains('transit') ||
        s.contains('out_for');
  }

  static bool belongsToRider(Map<String, dynamic> d, String riderId) {
    if (riderId.isEmpty) return false;
    return OpsFirestoreHelpers.riderId(d) == riderId;
  }

  /// Returns stats map keyed by delivery boy id + orders grouped by rider.
  static ({
    Map<String, DeliveryBoyOrderStats> statsByRider,
    Map<String, List<Map<String, dynamic>>> ordersByRider,
  }) aggregate(List<Map<String, dynamic>> orderDocs) {
    final statsByRider = <String, DeliveryBoyOrderStats>{};
    final ordersByRider = <String, List<Map<String, dynamic>>>{};

    for (final d in orderDocs) {
      final riderId = OpsFirestoreHelpers.riderId(d);
      if (riderId.isEmpty) continue;
      if (OpsFirestoreHelpers.isCancelled(d)) continue;

      ordersByRider.putIfAbsent(riderId, () => []).add(d);
    }

    for (final entry in ordersByRider.entries) {
      final riderId = entry.key;
      var assigned = 0;
      var active = 0;
      var completed = 0;

      for (final d in entry.value) {
        if (OpsFirestoreHelpers.isDelivered(d)) {
          completed++;
        } else if (isInTransit(d)) {
          active++;
        } else {
          assigned++;
        }
      }

      statsByRider[riderId] = DeliveryBoyOrderStats(
        assigned: assigned,
        active: active,
        completed: completed,
      );

      final total = assigned + active + completed;
      if (kDebugMode && total > 0) {
        debugPrint(
          '[DeliveryBoyStats]\n'
          'deliveryBoyId: $riderId\n'
          'assigned: $assigned\n'
          'active: $active\n'
          'completed: $completed\n'
          'total: $total',
        );
      }
    }

    for (final list in ordersByRider.values) {
      list.sort((a, b) {
        final da = OpsFirestoreHelpers.createdAt(a);
        final db = OpsFirestoreHelpers.createdAt(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });
    }

    return (statsByRider: statsByRider, ordersByRider: ordersByRider);
  }
}
