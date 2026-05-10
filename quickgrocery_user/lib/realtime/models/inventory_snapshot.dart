/// Tiny projection of a product used by carts / cards to react to
/// inventory & price changes without subscribing to the full model.
///
/// Lets us emit a `Map<productId, InventorySnapshot>` per inventory
/// stream tick — cart lines look up by id and patch in O(1).
class InventorySnapshot {
  const InventorySnapshot({
    required this.id,
    required this.price,
    required this.slashedPrice,
    required this.stock,
    required this.isAvailable,
  });

  final String id;
  final double price;
  final double slashedPrice;
  final int stock;
  final bool isAvailable;

  bool get inStock => isAvailable && stock > 0;
}
