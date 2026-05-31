import 'package:flutter/foundation.dart';

import '../../view/cart/domain/cart_models.dart';

/// Canonical order totals — single source of truth from Firestore `bill`.
@immutable
class OrderBillTotals {
  const OrderBillTotals({
    required this.subtotal,
    this.itemSavings = 0,
    this.couponDiscount = 0,
    this.deliveryFee = 0,
    this.surgeFee = 0,
    this.handlingCharge = 0,
    this.platformFee = 0,
    this.tax = 0,
    required this.grandTotal,
  });

  final double subtotal;
  final double itemSavings;
  final double couponDiscount;
  final double deliveryFee;
  final double surgeFee;
  final double handlingCharge;
  final double platformFee;
  final double tax;
  final double grandTotal;

  /// Amount subtracted in [computeGrandTotal] (coupon / promo only).
  double get discount => couponDiscount;

  double computeGrandTotal() => _round(
        subtotal -
            couponDiscount +
            deliveryFee +
            surgeFee +
            handlingCharge +
            platformFee +
            tax,
      );

  static OrderBillTotals fromBillBreakdown(BillBreakdown bill) =>
      OrderBillTotals(
        subtotal: bill.subtotal,
        itemSavings: bill.itemSavings,
        couponDiscount: bill.couponDiscount,
        deliveryFee: bill.deliveryFee,
        surgeFee: bill.surgeFee,
        handlingCharge: bill.handlingCharge,
        platformFee: bill.platformFee,
        tax: bill.tax,
        grandTotal: bill.total,
      );

  static OrderBillTotals? fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final m = Map<String, dynamic>.from(raw);
    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    final subtotal = n(m['subtotal']);
    final coupon = n(m['couponDiscount'] ?? m['discount']);
    var grand = n(m['grandTotal'] ?? m['total']);
    final delivery = n(m['deliveryFee']);
    final surge = n(m['surgeFee']);
    final handling = n(m['handlingCharge']);
    final platform = n(m['platformFee']);
    final taxAmt = n(m['tax']);

    if (grand <= 0 && subtotal > 0) {
      grand = OrderBillTotals(
        subtotal: subtotal,
        couponDiscount: coupon,
        deliveryFee: delivery,
        surgeFee: surge,
        handlingCharge: handling,
        platformFee: platform,
        tax: taxAmt,
        grandTotal: 0,
      ).computeGrandTotal();
    }

    return OrderBillTotals(
      subtotal: subtotal,
      itemSavings: n(m['itemSavings']),
      couponDiscount: coupon,
      deliveryFee: delivery,
      surgeFee: surge,
      handlingCharge: handling,
      platformFee: platform,
      tax: taxAmt,
      grandTotal: grand,
    );
  }

  static OrderBillTotals? fromOrderMap(Map<String, dynamic> data) =>
      fromMap(
        data['bill'] is Map
            ? Map<String, dynamic>.from(data['bill'] as Map)
            : null,
      );

  /// Legacy orders without `bill`: items sum + delivery only.
  static OrderBillTotals fromLineTotals({
    required double itemsSubtotal,
    int deliveryCharge = 0,
  }) {
    final delivery = deliveryCharge.toDouble();
    return OrderBillTotals(
      subtotal: itemsSubtotal,
      deliveryFee: delivery,
      grandTotal: itemsSubtotal + delivery,
    );
  }

  Map<String, dynamic> toMap() => {
        'subtotal': subtotal,
        'itemSavings': itemSavings,
        'couponDiscount': couponDiscount,
        'discount': couponDiscount,
        'deliveryFee': deliveryFee,
        'surgeFee': surgeFee,
        'handlingCharge': handlingCharge,
        'platformFee': platformFee,
        'tax': tax,
        'total': grandTotal,
        'grandTotal': grandTotal,
      };

  void debugLog({String? tag}) {
    if (!kDebugMode) return;
    final p = tag != null ? '[$tag] ' : '';
    debugPrint('${p}Items Total (subtotal): $subtotal');
    debugPrint('${p}Subtotal: $subtotal');
    debugPrint('${p}Item savings (info): $itemSavings');
    debugPrint('${p}Discount (coupon): $couponDiscount');
    debugPrint('${p}Delivery: $deliveryFee');
    debugPrint('${p}Platform Fee: $platformFee');
    debugPrint('${p}Tax: $tax');
    debugPrint('${p}Grand Total: $grandTotal');
  }

  void validateAgainstItems(
    Iterable<double> lineTotals, {
    String? tag,
  }) {
    if (!kDebugMode) return;
    final itemsTotal =
        lineTotals.fold<double>(0, (sum, v) => sum + v);
    final computed = computeGrandTotal();

    if ((itemsTotal - subtotal).abs() > 0.02) {
      debugPrint(
        '${tag != null ? '[$tag] ' : ''}'
        'BILL WARNING: sum(item.totalPrice)=$itemsTotal != subtotal=$subtotal',
      );
    }
    if ((computed - grandTotal).abs() > 0.02) {
      debugPrint(
        '${tag != null ? '[$tag] ' : ''}'
        'BILL WARNING: computed grand total=$computed != saved=$grandTotal',
      );
    }
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));
}
