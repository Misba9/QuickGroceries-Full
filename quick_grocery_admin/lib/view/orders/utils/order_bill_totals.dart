import 'package:flutter/foundation.dart';
import 'package:quick_grocery_admin/model/order_model.dart';

/// Canonical order totals from Firestore `bill` — do not recalculate in UI/PDF.
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
  final double grandTotal;

  double get discount => couponDiscount;

  double computeGrandTotal() => _round(
        subtotal -
            couponDiscount +
            deliveryFee +
            surgeFee +
            handlingCharge +
            platformFee +
            deliveryPartnerTip +
            tax,
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
    final tip = n(m['deliveryPartnerTip'] ?? m['tipAmount']);

    if (grand <= 0 && subtotal > 0) {
      grand = OrderBillTotals(
        subtotal: subtotal,
        couponDiscount: coupon,
        deliveryFee: delivery,
        surgeFee: surge,
        handlingCharge: handling,
        platformFee: platform,
        deliveryPartnerTip: tip,
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
      deliveryPartnerTip: tip,
      tax: taxAmt,
      grandTotal: grand,
    );
  }

  static OrderBillTotals resolve(OrderModel order) {
    final fromBill = fromMap(
      order.billRaw.isNotEmpty ? order.billRaw : null,
    );
    if (fromBill != null) {
      var couponDiscount = fromBill.couponDiscount;
      if (couponDiscount <= 0 && order.appliedCoupon != null) {
        couponDiscount = order.appliedCoupon!.discountAmountFor(
          subtotal: fromBill.subtotal,
        );
      }
      if ((couponDiscount - fromBill.couponDiscount).abs() > 0.009) {
        final grand = fromBill.grandTotal > 0
            ? fromBill.grandTotal
            : OrderBillTotals(
                subtotal: fromBill.subtotal,
                itemSavings: fromBill.itemSavings,
                couponDiscount: couponDiscount,
                deliveryFee: fromBill.deliveryFee,
                surgeFee: fromBill.surgeFee,
                handlingCharge: fromBill.handlingCharge,
                platformFee: fromBill.platformFee,
                deliveryPartnerTip: fromBill.deliveryPartnerTip,
                tax: fromBill.tax,
                grandTotal: 0,
              ).computeGrandTotal();
        return OrderBillTotals(
          subtotal: fromBill.subtotal,
          itemSavings: fromBill.itemSavings,
          couponDiscount: couponDiscount,
          deliveryFee: fromBill.deliveryFee,
          surgeFee: fromBill.surgeFee,
          handlingCharge: fromBill.handlingCharge,
          platformFee: fromBill.platformFee,
          deliveryPartnerTip: fromBill.deliveryPartnerTip,
          tax: fromBill.tax,
          grandTotal: grand,
        );
      }
      return fromBill;
    }

    final itemsSubtotal = order.products.fold<double>(
      0,
      (sum, p) => sum + p.lineTotal,
    );
    return OrderBillTotals.fromLineTotals(
      itemsSubtotal: itemsSubtotal,
      deliveryCharge: order.deliveryCharge,
    );
  }

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

  void debugLog({String? tag}) {
    if (!kDebugMode) return;
    final p = tag != null ? '[$tag] ' : '';
    debugPrint('${p}Items Total: $subtotal');
    debugPrint('${p}Subtotal: $subtotal');
    debugPrint('${p}Discount: $couponDiscount');
    debugPrint('${p}Delivery: $deliveryFee');
    debugPrint('${p}Grand Total: $grandTotal');
  }

  void validateAgainstOrder(OrderModel order, {String? tag}) {
    validateAgainstItems(
      order.products.map((p) => p.lineTotal),
      tag: tag,
    );
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
        'BILL WARNING: items=$itemsTotal != subtotal=$subtotal',
      );
    }
    if ((computed - grandTotal).abs() > 0.02) {
      debugPrint(
        '${tag != null ? '[$tag] ' : ''}'
        'BILL WARNING: computed=$computed != grandTotal=$grandTotal',
      );
    }
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));
}
