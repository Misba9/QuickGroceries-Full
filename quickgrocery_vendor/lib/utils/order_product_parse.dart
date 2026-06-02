import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

class OrderProductParse {
  OrderProductParse._();

  static List<ProductItem> linesFromOrder(Map<String, dynamic> data) {
    final raw = data['products'] ?? data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static ProductItem fromMap(Map<String, dynamic> data) {
    final qty = _qty(data);
    final prices = _resolveLinePrices(data, qty);
    var unitPrice = prices.selling;
    var totalPrice = prices.lineTotal;
    if (unitPrice <= 0 && totalPrice > 0 && qty > 0) {
      unitPrice = totalPrice / qty;
    }
    if (totalPrice <= 0 && unitPrice > 0) {
      totalPrice = unitPrice * qty;
    }

    final pack = _resolvePack(data);
    final name =
        (data['productName'] ?? data['name'] ?? '').toString().trim();

    return ProductItem(
      name: name,
      image: (data['image'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      unit: (data['unitType'] ?? '').toString(),
      price: unitPrice,
      slashedPrice: prices.original,
      itemCount: qty,
      vendorId: (data['vendor_id'] ?? data['vendorId'] ?? '').toString(),
      unitPerItem: (data['unitPerItem'] ?? '').toString(),
      packQuantity: (data['packQuantity'] ?? '').toString(),
      packWeight: pack.packWeightStr,
      measurementType:
          (data['measurementType'] ?? data['measurement_type'] ?? '')
              .toString(),
      variantName: pack.variantLabel,
      weightAmount: pack.amount,
      packUnit: pack.unit,
      totalPrice: totalPrice > 0 ? totalPrice : null,
      selectedWeightInGrams: _int(data['selectedWeightInGrams']),
    );
  }

  static void debugLogLines(List<ProductItem> items, {String? tag}) {
    if (!kDebugMode) return;
    if (tag != null) debugPrint('--- invoice items: $tag ---');
    for (var i = 0; i < items.length; i++) {
      final p = items[i];
      debugPrint('[${i}] Product: ${p.name}');
      debugPrint('[${i}] Quantity: ${p.itemCount}');
      debugPrint('[${i}] Weight: ${p.weightAmount}');
      debugPrint('[${i}] Unit: ${p.packUnit}');
      debugPrint('[${i}] Variant: ${p.variantName}');
    }
  }

  static ({double selling, double original, double lineTotal}) _resolveLinePrices(
    Map<String, dynamic> data,
    int qty,
  ) {
    final sellingExplicit = _dbl(data['sellingPrice']);
    final originalExplicit = _dbl(data['originalPrice']);
    final lineTotalExplicit = _dbl(data['lineTotal'] ?? data['totalPrice']);

    if (sellingExplicit > 0) {
      return (
        selling: sellingExplicit,
        original: originalExplicit > 0 ? originalExplicit : sellingExplicit,
        lineTotal: lineTotalExplicit > 0
            ? lineTotalExplicit
            : sellingExplicit * qty,
      );
    }

    var unitPrice = _dbl(data['unitPrice'] ?? data['price']);
    final slashed = _dbl(data['slashedPrice']);
    var lineTotal = lineTotalExplicit;
    if (unitPrice <= 0 && lineTotal > 0 && qty > 0) {
      unitPrice = lineTotal / qty;
    }
    if (slashed > 0 && slashed < unitPrice) {
      return (
        selling: slashed,
        original: unitPrice,
        lineTotal: lineTotal > 0 ? lineTotal : slashed * qty,
      );
    }
    return (
      selling: unitPrice,
      original: slashed > unitPrice ? slashed : unitPrice,
      lineTotal: lineTotal > 0 ? lineTotal : unitPrice * qty,
    );
  }

  static int _qty(Map<String, dynamic> data) {
    final q = _int(data['quantity'] ?? data['itemCount']) ?? 0;
    return q > 0 ? q : 1;
  }

  static _PackFields _resolvePack(Map<String, dynamic> data) {
    final variant =
        (data['variantName'] ?? data['variant'] ?? '').toString().trim();
    final unitField = (data['unit'] ?? '').toString().trim();
    final unitType = (data['unitType'] ?? '').toString().trim();
    final packWeightRaw =
        (data['packWeight'] ?? '').toString().trim();

    final amount = _num(data['weight']);
    if (amount != null && unitField.isNotEmpty) {
      final unit = _normalizeUnit(unitField);
      return _PackFields(
        amount: amount,
        unit: unit,
        variantLabel: variant.isNotEmpty ? variant : _label(amount, unit),
        packWeightStr: packWeightRaw.isNotEmpty ? packWeightRaw : '$amount',
      );
    }

    if (variant.isNotEmpty && RegExp(r'\d').hasMatch(variant)) {
      final parsed = _parseSizeLabel(variant);
      if (parsed != null) {
        return _PackFields(
          amount: parsed.$1,
          unit: parsed.$2,
          variantLabel: variant,
          packWeightStr: packWeightRaw.isNotEmpty ? packWeightRaw : '${parsed.$1}',
        );
      }
      return _PackFields(variantLabel: variant, packWeightStr: packWeightRaw);
    }

    final grams = _int(data['selectedWeightInGrams']);
    if (grams != null && grams > 0) {
      if (grams >= 1000) {
        final kg = grams / 1000;
        final amt = kg == kg.roundToDouble() ? kg.round() : kg;
        return _PackFields(
          amount: amt,
          unit: 'kg',
          variantLabel: variant.isNotEmpty ? variant : _label(amt, 'kg'),
          packWeightStr: '$grams',
        );
      }
      return _PackFields(
        amount: grams,
        unit: 'gm',
        variantLabel: variant.isNotEmpty ? variant : '$grams gm',
        packWeightStr: '$grams',
      );
    }

    if (packWeightRaw.isNotEmpty) {
      final w = _num(packWeightRaw);
      final u = _normalizeUnit(unitType.isNotEmpty ? unitType : unitField);
      if (w != null && u.isNotEmpty) {
        return _PackFields(
          amount: w,
          unit: u,
          variantLabel: variant.isNotEmpty ? variant : _label(w, u),
          packWeightStr: packWeightRaw,
        );
      }
    }

    return _PackFields(
      variantLabel: variant,
      packWeightStr: packWeightRaw,
      unit: unitField.isNotEmpty ? _normalizeUnit(unitField) : '',
    );
  }

  static (num, String)? _parseSizeLabel(String label) {
    final m =
        RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]+)$').firstMatch(label.trim());
    if (m == null) return null;
    final amount = _num(m.group(1));
    final unit = _normalizeUnit(m.group(2)!);
    if (amount == null || unit.isEmpty) return null;
    return (amount, unit);
  }

  static String _label(num amount, String unit) {
    final s = amount == amount.roundToDouble()
        ? amount.round().toString()
        : amount.toString();
    return '$s $unit';
  }

  static String _normalizeUnit(String raw) {
    final x = raw.trim().toLowerCase();
    switch (x) {
      case 'g':
      case 'gram':
      case 'grams':
        return 'gm';
      case 'kilogram':
      case 'kilograms':
        return 'kg';
      case 'ltr':
      case 'liter':
      case 'litre':
      case 'liters':
      case 'litres':
        return 'L';
      case 'milliliter':
      case 'milliliters':
        return 'ml';
      case 'piece':
      case 'pieces':
      case 'pc':
        return 'pcs';
      default:
        return raw.trim();
    }
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim()) ?? 0;
    }
    return 0;
  }

  static num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String && v.trim().isNotEmpty) return num.tryParse(v.trim());
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String && v.trim().isNotEmpty) return int.tryParse(v.trim());
    return null;
  }
}

class _PackFields {
  const _PackFields({
    this.amount,
    this.unit = '',
    this.variantLabel = '',
    this.packWeightStr = '',
  });

  final num? amount;
  final String unit;
  final String variantLabel;
  final String packWeightStr;
}
