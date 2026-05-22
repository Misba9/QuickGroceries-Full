import 'package:intl/intl.dart';
import 'package:quick_grocery_admin/model/order_model.dart';

/// ETA and delay helpers for dispatch UI.
abstract final class OrderEtaUtils {
  static const _slaMinutes = 45;

  static bool isDelayed(OrderModel o) {
    if (o.isDelivered || o.isCancelled) return false;
    final created = DateTime.tryParse(o.createdDate);
    if (created == null) return false;
    return DateTime.now().difference(created).inMinutes > _slaMinutes;
  }

  static String etaLabel(OrderModel o) {
    if (o.isDelivered) return 'Delivered';
    if (o.isCancelled) return '—';
    final created = DateTime.tryParse(o.createdDate);
    if (created == null) return '—';
    final eta = created.add(const Duration(minutes: _slaMinutes));
    if (DateTime.now().isAfter(eta)) {
      final late = DateTime.now().difference(eta).inMinutes;
      return '${late}m late';
    }
    return DateFormat('HH:mm').format(eta);
  }

  static String minutesSince(OrderModel o) {
    final created = DateTime.tryParse(o.createdDate);
    if (created == null) return '—';
    final m = DateTime.now().difference(created).inMinutes;
    return '${m}m ago';
  }
}
