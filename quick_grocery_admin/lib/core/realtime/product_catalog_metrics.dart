import 'package:quick_grocery_admin/model/product_model.dart';

/// Aggregated product stats for dashboard cards (from live product index).
class ProductCatalogMetrics {
  const ProductCatalogMetrics({
    this.total = 0,
    this.active = 0,
    this.outOfStock = 0,
    this.lowStock = 0,
    this.deleted = 0,
  });

  final int total;
  final int active;
  final int outOfStock;
  final int lowStock;
  final int deleted;

  static const empty = ProductCatalogMetrics();

  static const int lowStockThreshold = 5;

  static ProductCatalogMetrics fromProducts(Iterable<ProductModel> products) {
    var total = 0;
    var active = 0;
    var outOfStock = 0;
    var lowStock = 0;
    var deleted = 0;

    for (final p in products) {
      total++;
      if (p.isDeleted) {
        deleted++;
        continue;
      }
      final stock = int.tryParse(p.stock.trim()) ?? 0;
      if (p.isActive) active++;
      if (stock <= 0) {
        outOfStock++;
      } else if (p.isActive && stock <= lowStockThreshold) {
        lowStock++;
      }
    }

    return ProductCatalogMetrics(
      total: total,
      active: active,
      outOfStock: outOfStock,
      lowStock: lowStock,
      deleted: deleted,
    );
  }
}
