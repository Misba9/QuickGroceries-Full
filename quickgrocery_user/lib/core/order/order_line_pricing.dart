import 'package:flutter/foundation.dart';
import 'package:quickgrocery/models/order_model.dart';

@immutable
class OrderLinePricing {
  const OrderLinePricing({
    required this.mrp,
    required this.pricePaid,
    required this.quantity,
    required this.lineTotal,
  });

  final double mrp;
  final double pricePaid;
  final int quantity;
  final double lineTotal;

  bool get hasDiscount => mrp > pricePaid + 0.01;
  double get savingsAmount =>
      hasDiscount ? (mrp - pricePaid) * quantity : 0.0;
  int get savingsPercent =>
      hasDiscount && mrp > 0 ? ((1 - (pricePaid / mrp)) * 100).round() : 0;

  String get savingsLabel {
    if (!hasDiscount) return '';
    if (savingsPercent > 0) return '$savingsPercent% OFF';
    return 'Saved ₹${savingsAmount.toStringAsFixed(0)}';
  }

  factory OrderLinePricing.fromProductItem(ProductItem p) {
    final qty = p.itemCount > 0 ? p.itemCount : 1;
    final paid = _positive(p.unitPricePaid, fallback: p.price);
    final mrp = _positive(p.unitMrp, fallback: paid);
    final line = _positive(
      p.lineTotal,
      fallback: paid * qty,
    );
    return OrderLinePricing(
      mrp: mrp,
      pricePaid: paid,
      quantity: qty,
      lineTotal: line,
    );
  }
}

OrderLinePricing resolveOrderLinePricing(
  Map<String, dynamic> data,
  int quantity,
) {
  final qty = quantity > 0 ? quantity : 1;
  double n(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  final unitPaid = _positive(
    n(data['sellingPrice']) > 0 ? n(data['sellingPrice']) : n(data['pricePaid']),
    fallback: n(data['discountedPrice']) > 0
        ? n(data['discountedPrice'])
        : (n(data['price']) > 0 ? n(data['price']) : n(data['unitPrice'])),
  );
  final unitMrp = _positive(
    n(data['mrp']) > 0 ? n(data['mrp']) : n(data['originalPrice']),
    fallback: n(data['slashedPrice']) > 0 ? n(data['slashedPrice']) : unitPaid,
  );

  final lineTotal = _positive(
    n(data['lineTotal']) > 0 ? n(data['lineTotal']) : n(data['totalPrice']),
    fallback: unitPaid * qty,
  );

  final discountAmount = n(data['discountAmount']);
  final mrpFromDiscount = unitPaid + (discountAmount > 0 ? discountAmount : 0);
  final resolvedMrp = mrpFromDiscount > unitMrp ? mrpFromDiscount : unitMrp;

  return OrderLinePricing(
    mrp: resolvedMrp,
    pricePaid: unitPaid,
    quantity: qty,
    lineTotal: lineTotal,
  );
}

String formatOrderMoney(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

void validateOrderLinesAgainstSubtotal({
  required List<ProductItem> products,
  required double subtotal,
  String? tag,
}) {
  if (!kDebugMode) return;
  final fromLines = products.fold<double>(
    0,
    (sum, p) => sum + OrderLinePricing.fromProductItem(p).lineTotal,
  );
  if ((fromLines - subtotal).abs() > 0.05) {
    debugPrint(
      '${tag != null ? '[$tag] ' : ''}'
      'ORDER LINE WARNING: line sum=$fromLines != subtotal=$subtotal',
    );
  }
}

double _positive(double value, {required double fallback}) {
  if (value > 0) return value;
  return fallback > 0 ? fallback : 0;
}
