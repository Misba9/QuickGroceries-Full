import 'package:quickgrocery/core/inventory/inventory_limits.dart';
import 'package:quickgrocery/l10n/app_localizations.dart';

/// User-facing copy when quantity cannot increase (stock / max-order caps).
abstract final class InventoryLimitMessages {
  static String outOfStock(AppLocalizations l10n) => l10n.itemOutOfStock;

  /// Message when user taps + at or above the allowed cap.
  static String incrementBlocked({
    required AppLocalizations l10n,
    required int stock,
    required int maxOrder,
    required int currentCount,
  }) {
    if (stock <= 0) return outOfStock(l10n);

    final cap = InventoryLimits.effectiveMaxQuantity(
      stock: stock,
      maxOrder: maxOrder,
    );
    if (cap <= 0) return outOfStock(l10n);

    final limitedByMaxOrder =
        maxOrder > 0 && maxOrder < stock && currentCount >= maxOrder;

    if (limitedByMaxOrder) {
      return l10n.maxOrderLimitReached;
    }

    if (stock == 1) return l10n.onlyOneItemAvailable;
    return l10n.onlyNItemsAvailable(stock);
  }

  /// Shorter label for compact UI (e.g. product card at max).
  static String atMaxHint({
    required AppLocalizations l10n,
    required int stock,
    required int maxOrder,
  }) {
    if (stock <= 0) return outOfStock(l10n);
    if (maxOrder > 0 && maxOrder < stock) {
      return l10n.maxOrderLimitReached;
    }
    if (stock == 1) return l10n.onlyOneItemAvailable;
    return l10n.onlyNItemsAvailable(stock);
  }
}
