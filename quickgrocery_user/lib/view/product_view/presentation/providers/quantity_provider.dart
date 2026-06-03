import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickgrocery/core/inventory/inventory_limits.dart';

/// Composite key for [productQuantityProvider] — public so the family
/// can be referenced from other libraries without leaking private types.
class QuantityKey {
  const QuantityKey({
    required this.productId,
    required this.stock,
    required this.maxOrder,
  });
  final String productId;
  final int stock;
  final int maxOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantityKey &&
          other.productId == productId &&
          other.stock == stock &&
          other.maxOrder == maxOrder;

  @override
  int get hashCode => Object.hash(productId, stock, maxOrder);
}

/// Local-only quantity selector for the product detail screen.
/// One independent instance per product id (autoDispose family).
class QuantityNotifier extends AutoDisposeFamilyNotifier<int, QuantityKey> {
  @override
  int build(QuantityKey arg) => 1;

  /// Returns false when stock / max-order cap blocks the increment.
  bool increment() {
    final next = state + 1;
    final cap = InventoryLimits.effectiveMaxQuantity(
      stock: arg.stock,
      maxOrder: arg.maxOrder,
    );
    if (cap <= 0 || next > cap) return false;
    state = next;
    return true;
  }

  void decrement() {
    if (state <= 1) return;
    state -= 1;
  }

  void set(int value) {
    if (value < 1) {
      state = 1;
      return;
    }
    final cap = InventoryLimits.effectiveMaxQuantity(
      stock: arg.stock,
      maxOrder: arg.maxOrder,
    );
    if (cap > 0 && value > cap) {
      state = cap;
      return;
    }
    state = value;
  }
}

final productQuantityProvider =
    NotifierProvider.autoDispose.family<QuantityNotifier, int, QuantityKey>(
      QuantityNotifier.new,
    );

/// Convenience helper so callers can build a key inline.
ProviderListenable<int> quantityFor({
  required String productId,
  required int stock,
  required int maxOrder,
}) {
  return productQuantityProvider(
    QuantityKey(productId: productId, stock: stock, maxOrder: maxOrder),
  );
}

QuantityNotifier quantityNotifier(
  WidgetRef ref, {
  required String productId,
  required int stock,
  required int maxOrder,
}) {
  return ref.read(
    productQuantityProvider(
      QuantityKey(productId: productId, stock: stock, maxOrder: maxOrder),
    ).notifier,
  );
}

/// Local-only weight chip selector for vegetables. Defaults to 1000g.
class WeightNotifier extends AutoDisposeFamilyNotifier<int, String> {
  @override
  int build(String arg) => 1000;

  void set(int grams) {
    if (grams <= 0) return;
    state = grams;
  }
}

final productWeightProvider =
    NotifierProvider.autoDispose.family<WeightNotifier, int, String>(
      WeightNotifier.new,
    );
