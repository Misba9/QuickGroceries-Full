import 'package:quick_grocery_admin/core/analytics/admin_date_ranges.dart';
import 'package:quick_grocery_admin/core/analytics/admin_order_record.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/customers/models/customer_crm_models.dart';

abstract final class CustomerStatsAggregator {
  static Map<String, CustomerOrderStats> fromOrders(List<OrderModel> orders) {
    final map = <String, _Mutable>{};

    for (final o in orders) {
      final uid = o.uuid.trim();
      if (uid.isEmpty) continue;
      final m = map.putIfAbsent(uid, _Mutable.new);
      m.totalOrders++;

      final created = DateTime.tryParse(o.createdDate)?.toLocal();
      if (created != null) {
        if (m.lastOrderAt == null || created.isAfter(m.lastOrderAt!)) {
          m.lastOrderAt = created;
        }
      }

      if (o.isCancelled) continue;
      if (o.isDelivered) {
        m.completedOrders++;
        m.totalSpend += o.getTotalAmount();
      }
    }

    return map.map((uid, m) => MapEntry(uid, m.toStats()));
  }

  static Map<String, CustomerOrderStats> fromOrderMaps(
    List<Map<String, dynamic>> docs,
  ) {
    final map = <String, _Mutable>{};

    for (final d in docs) {
      final uid = (d['uuid'] ?? d['customerId'] ?? '').toString().trim();
      if (uid.isEmpty) continue;

      final r = AdminOrderRecord.fromMap(d, docId: d['id']?.toString());
      final m = map.putIfAbsent(uid, _Mutable.new);
      m.totalOrders++;

      final created = r.createdAt;
      if (created != null) {
        if (m.lastOrderAt == null || created.isAfter(m.lastOrderAt!)) {
          m.lastOrderAt = created;
        }
      }

      if (r.isCancelled) continue;
      if (r.isDelivered) {
        m.completedOrders++;
        m.totalSpend += r.total;
      }
    }

    return map.map((uid, m) => MapEntry(uid, m.toStats()));
  }

  static double totalDeliveredRevenue(List<Map<String, dynamic>> orderDocs) {
    var sum = 0.0;
    for (final d in orderDocs) {
      final r = AdminOrderRecord.fromMap(d, docId: d['id']?.toString());
      if (r.isDelivered && !r.isCancelled) sum += r.total;
    }
    return sum;
  }

  static CustomerListSummary summarize({
    required List<CustomerEnriched> customers,
    required double totalRevenue,
  }) {
    final todayStart = AdminDateRanges.todayStart;
    var activeToday = 0;
    var newToday = 0;
    var onlineNow = 0;
    var repeat = 0;

    for (final e in customers) {
      final c = e.customer;
      if (c.isOnline) onlineNow++;
      final joined = c.createdAtTs;
      if (joined != null && AdminDateRanges.isOnLocalDay(joined, todayStart)) {
        newToday++;
      }
      final last = c.lastActiveTs ?? e.stats.lastOrderAt;
      if (last != null && AdminDateRanges.isOnLocalDay(last, todayStart)) {
        activeToday++;
      }
      if (e.stats.completedOrders >= 2) repeat++;
    }

    return CustomerListSummary(
      totalCustomers: customers.length,
      activeToday: activeToday,
      newToday: newToday,
      onlineNow: onlineNow,
      totalRevenue: totalRevenue,
      repeatBuyers: repeat,
    );
  }
}

class _Mutable {
  int totalOrders = 0;
  int completedOrders = 0;
  double totalSpend = 0;
  DateTime? lastOrderAt;

  CustomerOrderStats toStats() => CustomerOrderStats(
        totalOrders: totalOrders,
        completedOrders: completedOrders,
        totalSpend: totalSpend,
        lastOrderAt: lastOrderAt,
      );
}
