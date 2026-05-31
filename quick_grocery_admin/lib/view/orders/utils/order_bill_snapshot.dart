/// Parsed `bill` object from modern order documents.
class OrderBillSnapshot {
  const OrderBillSnapshot({
    this.subtotal = 0,
    this.itemSavings = 0,
    this.couponDiscount = 0,
    this.deliveryFee = 0,
    this.surgeFee = 0,
    this.handlingCharge = 0,
    this.platformFee = 0,
    this.tax = 0,
    this.total = 0,
  });

  final double subtotal;
  final double itemSavings;
  final double couponDiscount;
  final double deliveryFee;
  final double surgeFee;
  final double handlingCharge;
  final double platformFee;
  final double tax;
  final double total;

  bool get hasPlatformFee => platformFee > 0;
  bool get hasTax => tax > 0;
  bool get hasHandling => handlingCharge > 0;
  bool get hasSurge => surgeFee > 0;
  bool get hasCoupon => couponDiscount > 0;

  static OrderBillSnapshot? fromFirestore(Map<String, dynamic> data) {
    final raw = data['bill'];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    double n(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return OrderBillSnapshot(
      subtotal: n(m['subtotal']),
      itemSavings: n(m['itemSavings']),
      couponDiscount: n(m['couponDiscount']),
      deliveryFee: n(m['deliveryFee']),
      surgeFee: n(m['surgeFee']),
      handlingCharge: n(m['handlingCharge']),
      platformFee: n(m['platformFee']),
      tax: n(m['tax']),
      total: n(m['total']),
    );
  }
}
