import '../models/order_model.dart';
import 'vendor_order_utils.dart';

/// Shared formatting for vendor order list + detail screens.
abstract final class VendorOrderDisplay {
  /// Best-effort order placement time in the device local timezone.
  static DateTime? placedAt(OrderModel order) {
    final fromField = order.createdAt;
    if (fromField != null) return fromField.toLocal();

    final parsed = VendorOrderUtils.parseCreatedDate(order);
    return parsed?.toLocal();
  }

  static String formatPlacedAt(OrderModel order) {
    final dt = placedAt(order);
    if (dt == null) {
      final raw = order.createdDate.trim();
      return raw.isEmpty ? '—' : raw;
    }
    return _formatLocal(dt);
  }

  static String formatTimestamp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return _formatLocal(parsed.toLocal());
  }

  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length == 10) return '+91 $digits';
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+${digits.substring(0, 2)} ${digits.substring(2)}';
    }
    return phone.trim();
  }

  static String _formatLocal(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  }
}
