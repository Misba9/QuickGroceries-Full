import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

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
    this.deliveryPartnerTip = 0,
    this.codConvenienceFee = 0,
    this.codFeeDescription = 'COD Convenience Fee',
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
  final double deliveryPartnerTip;
  final double codConvenienceFee;
  final String codFeeDescription;
  final double grandTotal;

  double get discount => couponDiscount;

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
    final codFee = n(m['codConvenienceFee'] ?? m['codFee']);
    final codDesc = (m['codFeeDescription'] ?? '').toString().trim();

    if (grand <= 0 && subtotal > 0) {
      grand = subtotal -
          coupon +
          n(m['deliveryFee']) +
          n(m['surgeFee']) +
          n(m['handlingCharge']) +
          n(m['platformFee']) +
          n(m['deliveryPartnerTip'] ?? m['tipAmount']) +
          codFee +
          n(m['tax']);
    }

    return OrderBillTotals(
      subtotal: subtotal,
      itemSavings: n(m['itemSavings']),
      couponDiscount: coupon,
      deliveryFee: n(m['deliveryFee']),
      surgeFee: n(m['surgeFee']),
      handlingCharge: n(m['handlingCharge']),
      platformFee: n(m['platformFee']),
      deliveryPartnerTip: n(m['deliveryPartnerTip'] ?? m['tipAmount']),
      codConvenienceFee: codFee,
      codFeeDescription:
          codDesc.isEmpty ? 'COD Convenience Fee' : codDesc,
      tax: n(m['tax']),
      grandTotal: grand,
    );
  }

  static OrderBillTotals resolve(OrderModel order) {
    final fromBill = fromMap(
      order.billRaw.isNotEmpty ? order.billRaw : null,
    );
    if (fromBill != null) return fromBill;

    final itemsSubtotal = order.products.fold<double>(
      0,
      (sum, p) => sum + p.lineTotal,
    );
    return OrderBillTotals(
      subtotal: itemsSubtotal,
      deliveryFee: order.deliveryCharge.toDouble(),
      grandTotal: itemsSubtotal + order.deliveryCharge,
    );
  }

  void debugLog({String? tag}) {
    if (!kDebugMode) return;
    final p = tag != null ? '[$tag] ' : '';
    debugPrint('${p}Subtotal: $subtotal');
    debugPrint('${p}Discount: $couponDiscount');
    debugPrint('${p}Delivery: $deliveryFee');
    debugPrint('${p}Grand Total: $grandTotal');
  }
}
