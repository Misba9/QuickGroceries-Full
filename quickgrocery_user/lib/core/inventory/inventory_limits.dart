/// Central stock / max-order rules shared by cart, listing, and checkout.
class InventoryLimits {
  InventoryLimits._();

  /// True when the SKU cannot be purchased (listing, PDP, cart).
  static bool isOutOfStock({
    required int stock,
    required bool isAvailable,
    String? stockStatus,
  }) {
    if (!isAvailable) return true;
    if (stockStatus == 'out_of_stock') return true;
    return stock <= 0;
  }

  /// Max units a customer may add for one line (0 maxOrder = unlimited by cap).
  static int effectiveMaxQuantity({
    required int stock,
    required int maxOrder,
  }) {
    if (stock <= 0) return 0;
    if (maxOrder <= 0) return stock;
    return maxOrder < stock ? maxOrder : stock;
  }

  static int clampQuantity({
    required int requested,
    required int stock,
    required int maxOrder,
    int minOrder = 1,
  }) {
    final max = effectiveMaxQuantity(stock: stock, maxOrder: maxOrder);
    if (max <= 0) return 0;
    final floor = minOrder < 1 ? 1 : minOrder;
    if (requested < floor) return floor;
    return requested > max ? max : requested;
  }

  /// Cart line is blocked at checkout when OOS, unavailable, or over limits.
  static bool isCartLineBlocked({
    required int stock,
    required int itemCount,
    required int maxOrder,
    required bool isAvailable,
    String? stockStatus,
  }) {
    if (isOutOfStock(stock: stock, isAvailable: isAvailable, stockStatus: stockStatus)) {
      return true;
    }
    if (itemCount > stock) return true;
    if (maxOrder > 0 && itemCount > maxOrder) return true;
    return false;
  }

  static String maxOrderHint(int maxOrder) {
    if (maxOrder <= 0) return '';
    return 'Maximum $maxOrder items per order';
  }
}
