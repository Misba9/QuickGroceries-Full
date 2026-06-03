import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment helpers for [OrderModel] — online Razorpay vs COD collection.
class OrderPaymentInfo {
  const OrderPaymentInfo({
    required this.paymentMethod,
    required this.paymentStatus,
    required this.isPaidLegacy,
    required this.razorpayPaymentId,
    required this.transactionId,
    required this.paidAmount,
    required this.paidAt,
    required this.collectionMethod,
    required this.bill,
    required this.productsSubtotal,
    required this.deliveryCharge,
  });

  final String paymentMethod;
  final String paymentStatus;
  final bool isPaidLegacy;
  final String razorpayPaymentId;
  final String transactionId;
  final double paidAmount;
  final DateTime? paidAt;
  final String collectionMethod;
  final Map<String, dynamic>? bill;
  final double productsSubtotal;
  final int deliveryCharge;

  static OrderPaymentInfo fromOrderData(
    Map<String, dynamic> data, {
    required double productsSubtotal,
    required int deliveryCharge,
    Map<String, dynamic>? bill,
  }) {
    DateTime? paidAt;
    final rawPaid = data['paidAt'] ?? data['paid_at'];
    if (rawPaid is Timestamp) {
      paidAt = rawPaid.toDate();
    } else if (rawPaid is String && rawPaid.isNotEmpty) {
      paidAt = DateTime.tryParse(rawPaid);
    }

    return OrderPaymentInfo(
      paymentMethod: (data['paymentMethod'] ?? data['payment_method'] ?? 'cod')
          .toString(),
      paymentStatus: (data['paymentStatus'] ?? data['payment_status'] ?? 'pending')
          .toString(),
      isPaidLegacy: data['isPaid'] == true,
      razorpayPaymentId: (data['razorpayPaymentId'] ??
              data['paymentRef'] ??
              data['razorpay_payment_id'] ??
              '')
          .toString(),
      transactionId: (data['transactionId'] ?? data['paymentRef'] ?? '').toString(),
      paidAmount: _dbl(data['paidAmount'] ?? data['paid_amount']),
      paidAt: paidAt,
      collectionMethod:
          (data['collectionMethod'] ?? data['collection_method'] ?? '').toString(),
      bill: bill,
      productsSubtotal: productsSubtotal,
      deliveryCharge: deliveryCharge,
    );
  }

  static double _dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }

  String get methodLower => paymentMethod.toLowerCase();

  bool get isOnlinePaid {
    final m = methodLower;
    if (m == 'cod' || m == 'cash_on_delivery') return false;
    final ps = paymentStatus.toLowerCase();
    if (m == 'razorpay' || m == 'online' || m == 'upi' || m == 'card') {
      return ps == 'paid' || isPaidLegacy || razorpayPaymentId.isNotEmpty;
    }
    if (ps == 'paid' || isPaidLegacy) return m != 'cod';
    return false;
  }

  bool get isCod => !isOnlinePaid;

  bool get isPaymentCollected =>
      paymentStatus.toLowerCase() == 'paid' || isPaidLegacy;

  bool get requiresCodCollection => isCod && !isPaymentCollected;

  double get orderTotal {
    final billTotal = bill != null
        ? _dbl(bill!['grandTotal'] ?? bill!['total'])
        : 0.0;
    if (billTotal > 0) return billTotal;
    return productsSubtotal + deliveryCharge.toDouble();
  }

  double get displayPaidAmount =>
      paidAmount > 0 ? paidAmount : (isPaymentCollected ? orderTotal : 0);
}
