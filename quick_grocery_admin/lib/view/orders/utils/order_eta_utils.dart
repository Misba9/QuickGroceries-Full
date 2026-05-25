import 'package:quick_grocery_admin/core/utils/duration_format.dart';
import 'package:quick_grocery_admin/model/order_model.dart';

/// ETA and delay helpers for dispatch UI (uses global [DurationFormat]).
abstract final class OrderEtaUtils {
  static const _slaMinutes = 45;
  static const _sla = Duration(minutes: _slaMinutes);

  static bool isDelayed(OrderModel o) {
    if (o.isDelivered || o.isCancelled) return false;
    final created = DateTime.tryParse(o.createdDate)?.toLocal();
    if (created == null) return false;
    return DateTime.now().difference(created) > _sla;
  }

  static String etaLabel(OrderModel o) {
    if (o.isDelivered) return 'Delivered';
    if (o.isCancelled) return '—';
    final created = DateTime.tryParse(o.createdDate)?.toLocal();
    return DurationFormat.formatEta(createdAt: created, sla: _sla);
  }

  static String minutesSince(OrderModel o) {
    final created = DateTime.tryParse(o.createdDate)?.toLocal();
    return DurationFormat.formatElapsed(created);
  }

  static String lateLabel(OrderModel o) {
    if (o.isDelivered || o.isCancelled) return '';
    final created = DateTime.tryParse(o.createdDate)?.toLocal();
    if (created == null) return '';
    final deadline = created.add(_sla);
    return DurationFormat.formatLate(deadline, prefix: 'Late by ');
  }
}
