/// Coupon snapshot saved on order documents (`coupon` field).
class OrderAppliedCoupon {
  const OrderAppliedCoupon({
    required this.id,
    required this.code,
    this.discountPercent = 0,
    this.flatAmount = 0,
    this.maxDiscountAmount = 0,
    this.savingsPreview = 0,
    this.freeDelivery = false,
    this.couponType = '',
  });

  final String id;
  final String code;
  final double discountPercent;
  final double flatAmount;
  final double maxDiscountAmount;
  final double savingsPreview;
  final bool freeDelivery;
  final String couponType;

  static OrderAppliedCoupon? fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final code = (raw['code'] ?? '').toString().trim();
    if (code.isEmpty) return null;

    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return OrderAppliedCoupon(
      id: (raw['id'] ?? '').toString(),
      code: code.toUpperCase(),
      discountPercent: n(raw['discount']),
      flatAmount: n(raw['flat_amount'] ?? raw['flatAmount']),
      maxDiscountAmount: n(raw['max_discount_amount'] ?? raw['maxDiscountAmount']),
      savingsPreview: n(raw['savingsPreview'] ?? raw['savings_preview']),
      freeDelivery: raw['free_delivery'] == true || raw['freeDelivery'] == true,
      couponType: (raw['coupon_type'] ?? raw['couponType'] ?? '').toString(),
    );
  }

  /// Best-effort discount when `bill.couponDiscount` is missing on legacy orders.
  double discountAmountFor({required double subtotal}) {
    if (savingsPreview > 0) return savingsPreview;
    if (flatAmount > 0) return flatAmount.clamp(0, subtotal);
    if (discountPercent > 0) {
      var amount = subtotal * (discountPercent / 100);
      if (maxDiscountAmount > 0) {
        amount = amount.clamp(0, maxDiscountAmount);
      }
      return amount.clamp(0, subtotal);
    }
    return 0;
  }
}
