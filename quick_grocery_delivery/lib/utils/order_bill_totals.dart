import 'package:quick_grocery_delivery/models/order_model.dart';

/// Parsed `bill` object from order documents.
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
    this.extraLines = const [],
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
  final List<BillExtraLine> extraLines;

  static const _knownBillKeys = {
    'subtotal',
    'itemSavings',
    'couponDiscount',
    'discount',
    'deliveryFee',
    'surgeFee',
    'handlingCharge',
    'platformFee',
    'tax',
    'deliveryPartnerTip',
    'tipAmount',
    'codConvenienceFee',
    'codFee',
    'codFeeDescription',
    'total',
    'grandTotal',
    'isFreeDelivery',
  };

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

    final extras = <BillExtraLine>[];
    for (final entry in m.entries) {
      if (_knownBillKeys.contains(entry.key)) continue;
      final value = n(entry.value);
      if (value == 0) continue;
      extras.add(
        BillExtraLine(
          label: _humanizeBillKey(entry.key),
          value: value,
        ),
      );
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
      extraLines: extras,
    );
  }

  static OrderBillTotals resolve(OrderModel order) {
    final fromBill = fromMap(order.bill);
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

  static double mrpTotal(OrderModel order) {
    return order.products.fold<double>(
      0,
      (sum, p) => sum + p.unitMrp * p.itemCount,
    );
  }

  static double productDiscount(OrderModel order, OrderBillTotals bill) {
    if (bill.itemSavings > 0) return bill.itemSavings;
    final mrp = mrpTotal(order);
    return (mrp - bill.subtotal).clamp(0.0, double.infinity);
  }

  static String? couponCodeFromOrder(OrderModel order) {
    final raw = order.couponRaw;
    if (raw == null) return null;
    final code = (raw['code'] ?? '').toString().trim();
    return code.isEmpty ? null : code.toUpperCase();
  }

  static String _humanizeBillKey(String key) {
    final spaced = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .trim();
    if (spaced.isEmpty) return key;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class BillExtraLine {
  const BillExtraLine({required this.label, required this.value});

  final String label;
  final double value;
}
