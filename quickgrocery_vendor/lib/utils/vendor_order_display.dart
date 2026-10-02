import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import '../models/order_model.dart';
import 'vendor_order_utils.dart';

/// Shared formatting for vendor order list + detail screens.
abstract final class VendorOrderDisplay {
  /// Best-effort order placement time in the device local timezone.
  static DateTime? placedAt(OrderModel order) {
    return OrderDateTimeFormat.resolve(
      createdAt: order.createdAt,
      createdDate: order.createdDate.isNotEmpty
          ? order.createdDate
          : VendorOrderUtils.parseCreatedDate(order)?.toIso8601String(),
    )?.toLocal();
  }

  static String formatPlacedAt(OrderModel order) {
    final dt = placedAt(order);
    if (dt == null) {
      final raw = order.createdDate.trim();
      return raw.isEmpty ? '—' : raw;
    }
    return OrderDateTimeFormat.format(dt);
  }

  static String formatTimestamp(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return OrderDateTimeFormat.format(parsed);
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
}
