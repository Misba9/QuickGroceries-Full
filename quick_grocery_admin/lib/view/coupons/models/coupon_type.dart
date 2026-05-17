enum CouponType {
  firstOrder('first_order', 'First Order Coupon'),
  specialOffer('special_offer', 'Special Offer'),
  festivalOffer('festival_offer', 'Festival Offer'),
  freeDelivery('free_delivery', 'Free Delivery Coupon'),
  percentageDiscount('percentage_discount', 'Percentage Discount'),
  flatDiscount('flat_discount', 'Flat Discount'),
  vendorSpecific('vendor_specific', 'Vendor Specific'),
  productSpecific('product_specific', 'Product Specific');

  const CouponType(this.id, this.label);
  final String id;
  final String label;

  static CouponType fromId(String? raw) {
    return CouponType.values.firstWhere(
      (e) => e.id == raw,
      orElse: () => CouponType.percentageDiscount,
    );
  }

  bool get isFirstOrder => this == CouponType.firstOrder;
  bool get needsVendors => this == CouponType.vendorSpecific;
  bool get needsProducts => this == CouponType.productSpecific;
  bool get isPercentage =>
      this == CouponType.percentageDiscount ||
      this == CouponType.firstOrder ||
      this == CouponType.specialOffer ||
      this == CouponType.festivalOffer;
  bool get isFlat => this == CouponType.flatDiscount;
  bool get isFreeDelivery => this == CouponType.freeDelivery;
}

enum CouponListFilter {
  all('All'),
  active('Active'),
  expired('Expired'),
  firstOrder('First Order'),
  vendorSpecific('Vendor Specific');

  const CouponListFilter(this.label);
  final String label;
}
