import 'package:quickgrocery/core/product/product_quantity_label.dart';
import 'package:quickgrocery/models/order_model.dart';

import 'cart_models.dart';

/// Permanent product line written to Firestore on checkout.
class OrderLineSnapshot {
  OrderLineSnapshot._();

  static Map<String, dynamic> fromCartItem(CartItem item) {
    final pack = _packFor(item);
    final qty = item.itemCount > 0 ? item.itemCount : 1;
    final sellingPrice = item.unitEffectivePrice;
    final mrp = item.unitEffectiveSlashedPrice;
    final discountAmount =
        (mrp - sellingPrice).clamp(0.0, double.infinity);
    final lineTotal = sellingPrice * qty;
    final variant = _variantFor(item, pack);

    return {
      'productId': item.productId,
      'name': item.name,
      'productName': item.name,
      'image': item.image,
      'category': item.category,
      'quantity': item.itemCount,
      'itemCount': item.itemCount,
      if (pack.amount != null) 'weight': pack.amount,
      if (pack.unit.isNotEmpty) 'unit': pack.unit,
      if (variant.isNotEmpty) 'variantName': variant,
      'unitPerItem': item.unitPerItem,
      if (item.packQuantity.isNotEmpty) 'packQuantity': item.packQuantity,
      if (item.packWeight.isNotEmpty) 'packWeight': item.packWeight,
      if (item.measurementType.isNotEmpty)
        'measurementType': item.measurementType,
      'selectedWeightInGrams': item.selectedWeightInGrams,
      'unitType': item.unit,
      'pricePaid': sellingPrice,
      'sellingPrice': sellingPrice,
      'discountedPrice': sellingPrice,
      'mrp': mrp,
      'originalPrice': mrp,
      'discountAmount': discountAmount,
      'lineTotal': lineTotal,
      'price': sellingPrice,
      'unitPrice': sellingPrice,
      'totalPrice': lineTotal,
      'slashedPrice': mrp,
      'vendor_id': item.vendorId,
      'vendorId': item.vendorId,
      'isVegetable': item.isVegetable,
    };
  }

  static ProductItem toProductItem(CartItem item) =>
      ProductItem.fromMap(fromCartItem(item));

  static _Pack _packFor(CartItem item) {
    if (item.isVegetable) {
      final g = item.selectedWeightInGrams;
      if (g >= 1000) {
        final kg = g / 1000;
        final amt = kg == kg.roundToDouble() ? kg.round() : kg;
        return _Pack(amount: amt, unit: 'kg');
      }
      return _Pack(amount: g, unit: 'gm');
    }
    final label = formatProductQuantityLabel(
      unitPerItem: item.unitPerItem,
      unit: item.unit,
      packQuantity: item.packQuantity,
      packWeight: item.packWeight,
      measurementType: item.measurementType,
    );
    final parsed = _parseLabel(label);
    if (parsed != null) return parsed;
    if (item.packWeight.isNotEmpty && item.unit.isNotEmpty) {
      final n = num.tryParse(item.packWeight);
      if (n != null) return _Pack(amount: n, unit: _normUnit(item.unit));
    }
    return const _Pack();
  }

  static String _variantFor(CartItem item, _Pack pack) {
    if (item.isVegetable) {
      final g = item.selectedWeightInGrams;
      if (g >= 1000) {
        final kg = g / 1000;
        return kg == kg.roundToDouble() ? '$kg kg' : '${kg.toStringAsFixed(1)} kg';
      }
      return '$g gm';
    }
    final label = formatProductQuantityLabel(
      unitPerItem: item.unitPerItem,
      unit: item.unit,
      packQuantity: item.packQuantity,
      packWeight: item.packWeight,
      measurementType: item.measurementType,
    );
    if (label.isNotEmpty) return label;
    if (pack.amount != null && pack.unit.isNotEmpty) {
      return '${pack.amount} ${pack.unit}';
    }
    return '';
  }

  static _Pack? _parseLabel(String label) {
    final m =
        RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$').firstMatch(label.trim());
    if (m == null) return null;
    final n = num.tryParse(m.group(1)!);
    if (n == null) return null;
    return _Pack(amount: n, unit: _normUnit(m.group(2)!));
  }

  static String _normUnit(String u) {
    final x = u.toLowerCase();
    if (x == 'g') return 'gm';
    if (x == 'ltr' || x == 'liter' || x == 'litre') return 'L';
    if (x == 'pc') return 'pcs';
    return u;
  }
}

class _Pack {
  const _Pack({this.amount, this.unit = ''});
  final num? amount;
  final String unit;
}
