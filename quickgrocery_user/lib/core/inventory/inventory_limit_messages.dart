import 'package:quickgrocery/core/inventory/inventory_limits.dart';

/// User-facing copy when quantity cannot increase (stock / max-order caps).
abstract final class InventoryLimitMessages {
  static const String outOfStock = 'This item is out of stock';

  /// Message when user taps + at or above the allowed cap.
  static String incrementBlocked({
    required int stock,
    required int maxOrder,
    required int currentCount,
  }) {
    if (stock <= 0) return outOfStock;

    final cap = InventoryLimits.effectiveMaxQuantity(
      stock: stock,
      maxOrder: maxOrder,
    );
    if (cap <= 0) return outOfStock;

    final limitedByMaxOrder =
        maxOrder > 0 && maxOrder < stock && currentCount >= maxOrder;

    if (limitedByMaxOrder) {
      return 'Maximum order limit reached';
    }

    if (stock == 1) return 'Only 1 item available';
    return 'Only $stock items available';
  }

  /// Shorter label for compact UI (e.g. product card at max).
  static String atMaxHint({
    required int stock,
    required int maxOrder,
  }) {
    if (stock <= 0) return outOfStock;
    if (maxOrder > 0 && maxOrder < stock) {
      return 'Maximum order limit reached';
    }
    if (stock == 1) return 'Only 1 item available';
    return 'Only $stock items available';
  }
}
