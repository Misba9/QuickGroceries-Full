import 'package:flutter/foundation.dart';
import 'package:quickgrocery/core/widgets/discount_badge.dart';
import 'package:quickgrocery/models/order_model.dart';

/// Resolved unit/line amounts from an order snapshot line (never live catalog).
class OrderLinePricing {
  const OrderLinePricing({
    required this.pricePaid,
    required this.mrp,
    required this.lineTotal,
    required this.quantity,
    required this.discountAmount,
  });

  final double pricePaid;
  final double mrp;
  final double lineTotal;
  final int quantity;
  final double discountAmount;

  bool get hasDiscount => mrp > pricePaid + 0.01;

  int get discountPercent => DiscountBadge.calculate(
        price: pricePaid,
        originalPrice: mrp,
      );

  String get savingsLabel {
    if (!hasDiscount) return '';
    if (discountPercent > 0) return '$discountPercent% OFF';
    return 'Saved ₹${discountAmount.round()}';
  }

  static OrderLinePricing fromProductItem(ProductItem item) {
    final unitPaid = item.unitPricePaid;
    final unitMrp = item.unitMrp;
    final qty = item.itemCount > 0 ? item.itemCount : 1;
    final line = item.lineTotal;
    final unitDiscount =
        (unitMrp - unitPaid).clamp(0.0, double.infinity);
    return OrderLinePricing(
      pricePaid: unitPaid,
      mrp: unitMrp,
      lineTotal: line,
      quantity: qty,
      discountAmount: unitDiscount * qty,
    );
  }
}

/// Parse persisted order line prices (checkout snapshot + legacy orders).
OrderLinePricing resolveOrderLinePricing(
  Map<String, dynamic> data,
  int quantity,
) {
  double d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0;
  }

  final qty = quantity > 0 ? quantity : 1;
  final lineTotalExplicit = d(data['lineTotal'] ?? data['totalPrice']);

  final pricePaid = d(
    data['pricePaid'] ??
        data['sellingPrice'] ??
        data['discountedPrice'] ??
        data['unitPrice'],
  );

  if (pricePaid > 0) {
    var mrp = d(data['mrp'] ?? data['originalPrice']);
    if (mrp <= pricePaid) {
      mrp = d(data['slashedPrice']);
      if (mrp <= pricePaid) mrp = pricePaid;
    }
    final discountAmount = d(data['discountAmount']);
    final lineTotal = lineTotalExplicit > 0
        ? lineTotalExplicit
        : pricePaid * qty;
    return OrderLinePricing(
      pricePaid: pricePaid,
      mrp: mrp,
      lineTotal: lineTotal,
      quantity: qty,
      discountAmount: discountAmount > 0
          ? discountAmount
          : (mrp - pricePaid).clamp(0.0, double.infinity) * qty,
    );
  }

  var unitPrice = d(data['price']);
  final slashed = d(data['slashedPrice']);
  var lineTotal = lineTotalExplicit;
  if (unitPrice <= 0 && lineTotal > 0) {
    unitPrice = lineTotal / qty;
  }

  // Legacy: MRP in `price`, selling in `slashedPrice`.
  if (slashed > 0 && slashed < unitPrice) {
    final selling = slashed;
    final mrp = unitPrice;
    lineTotal = lineTotal > 0 ? lineTotal : selling * qty;
    return OrderLinePricing(
      pricePaid: selling,
      mrp: mrp,
      lineTotal: lineTotal,
      quantity: qty,
      discountAmount: (mrp - selling).clamp(0.0, double.infinity) * qty,
    );
  }

  final mrp = slashed > unitPrice + 0.01 ? slashed : unitPrice;
  lineTotal = lineTotal > 0 ? lineTotal : unitPrice * qty;
  return OrderLinePricing(
    pricePaid: unitPrice,
    mrp: mrp,
    lineTotal: lineTotal,
    quantity: qty,
    discountAmount: (mrp - unitPrice).clamp(0.0, double.infinity) * qty,
  );
}

void validateOrderLinesAgainstSubtotal({
  required Iterable<ProductItem> products,
  required double subtotal,
  String? tag,
}) {
  if (!kDebugMode) return;
  final itemsTotal = products.fold<double>(0, (s, p) => s + p.lineTotal);
  if ((itemsTotal - subtotal).abs() > 0.02) {
    debugPrint(
      '${tag != null ? '[$tag] ' : ''}'
      'BILL WARNING: sum(line paid totals)=$itemsTotal != subtotal=$subtotal',
    );
  }
}

String formatOrderMoney(double value) {
  final v = value.abs();
  return v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(2);
}
