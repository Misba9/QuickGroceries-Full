import 'cart_models.dart';

/// Pure pricing engine. No Firebase, no widgets — easy to unit-test.
///
/// Order of operations:
///   1. Subtotal and slashed-subtotal are the sum of effective per-line totals.
///   2. Coupon discount is a flat % of subtotal.
///   3. Free-delivery threshold is checked against subtotal **after** coupon
///      so coupons that knock the cart under the threshold trigger delivery
///      fees again — matches the user's invoice on quick-commerce apps.
///   4. Surge multiplier multiplies the delivery fee only.
///   5. Tax is applied on (subtotal - couponDiscount) — i.e. taxable items.
class PricingCalculator {
  const PricingCalculator();

  BillBreakdown compute({
    required List<CartItem> items,
    required PricingConfig config,
    AppliedCoupon? coupon,
    int? deliveryChargeOverride,
  }) {
    if (items.isEmpty) {
      return BillBreakdown(
        subtotal: 0,
        slashedSubtotal: 0,
        itemSavings: 0,
        couponDiscount: 0,
        deliveryFee: 0,
        surgeFee: 0,
        handlingCharge: config.handlingCharge.toDouble(),
        platformFee: config.platformFee.toDouble(),
        tax: 0,
        total: config.handlingCharge.toDouble() + config.platformFee.toDouble(),
        isFreeDelivery: false,
        meetsMinimumOrder: false,
        minimumOrderValue: config.minOrderValue.toDouble(),
      );
    }

    double subtotal = 0;
    double slashedSubtotal = 0;
    for (final item in items) {
      subtotal += item.lineTotal;
      slashedSubtotal += item.lineSlashedTotal;
    }

    final itemSavings = (slashedSubtotal - subtotal).clamp(0.0, double.infinity);

    final couponPercent = coupon?.discountPercent ?? 0;
    final couponDiscount = subtotal * (couponPercent / 100.0);

    final taxableAmount = (subtotal - couponDiscount).clamp(0.0, double.infinity);
    final tax = taxableAmount * (config.taxPercent / 100.0);

    final taxedSubtotal = taxableAmount;
    final freeDeliveryThreshold = config.isFreeDeliveryEnabled
        ? config.freeDeliveryThreshold.toDouble()
        : double.infinity;
    final isFreeDelivery = taxedSubtotal >= freeDeliveryThreshold;

    final baseDelivery = (deliveryChargeOverride ??
            (config.standardDeliveryCharge > 0
                ? config.standardDeliveryCharge
                : config.defaultDeliveryCharge))
        .toDouble();

    final deliveryFee = (!config.isDeliveryChargesEnabled || isFreeDelivery)
        ? 0.0
        : baseDelivery;

    double surgeFee = 0;
    if (config.surgeActive && config.surgeMultiplier > 1 && deliveryFee > 0) {
      surgeFee = deliveryFee * (config.surgeMultiplier - 1);
    }

    final total = taxableAmount +
        deliveryFee +
        surgeFee +
        config.handlingCharge.toDouble() +
        config.platformFee.toDouble() +
        tax;

    return BillBreakdown(
      subtotal: _round(subtotal),
      slashedSubtotal: _round(slashedSubtotal),
      itemSavings: _round(itemSavings),
      couponDiscount: _round(couponDiscount),
      deliveryFee: _round(deliveryFee),
      surgeFee: _round(surgeFee),
      handlingCharge: config.handlingCharge.toDouble(),
      platformFee: config.platformFee.toDouble(),
      tax: _round(tax),
      total: _round(total),
      isFreeDelivery: isFreeDelivery,
      meetsMinimumOrder: subtotal >= config.minOrderValue,
      minimumOrderValue: config.minOrderValue.toDouble(),
    );
  }

  static double _round(double v) => double.parse(v.toStringAsFixed(2));
}
