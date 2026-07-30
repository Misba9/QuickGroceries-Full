import 'receipt_options.dart';

/// Platform-neutral order payload for receipts (map from app models).
class ReceiptOrderData {
  const ReceiptOrderData({
    required this.orderId,
    required this.invoiceNumber,
    this.createdAt,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.items,
    required this.bill,
    required this.paymentMethod,
    required this.statusLabel,
    required this.etaLabel,
    this.deliverySlotLabel,
    this.deliveryTypeLabel,
    this.instructionLines = const [],
    this.storeName,
    this.trackUrl,
    this.couponCode,
    this.mode = ReceiptMode.invoice,
    this.paperSize = ReceiptPaperSize.mm80,
  });

  final String orderId;
  final String invoiceNumber;
  final DateTime? createdAt;
  final String customerName;
  final String phone;
  final String address;
  final List<ReceiptLineItem> items;
  final ReceiptBill bill;
  final String paymentMethod;
  final String statusLabel;
  final String etaLabel;
  final String? deliverySlotLabel;
  final String? deliveryTypeLabel;
  final List<String> instructionLines;
  final String? storeName;
  final String? trackUrl;
  final String? couponCode;
  final ReceiptMode mode;
  final ReceiptPaperSize paperSize;

  bool get isPackingSlip => mode == ReceiptMode.packingSlip;
  bool get showPrices => !isPackingSlip;

  String get trackingUrl =>
      trackUrl ?? 'quickgrocery.app/order/${orderId.toLowerCase()}';

  /// e.g. `standard • demo`
  String? get typeAndStoreLine {
    final parts = <String>[];
    final type = deliveryTypeLabel?.trim() ?? '';
    final store = storeName?.trim() ?? '';
    if (type.isNotEmpty) parts.add(type);
    if (store.isNotEmpty) parts.add(store);
    if (parts.isEmpty) return null;
    return parts.join(' • ');
  }

  ReceiptOrderData copyWith({String? phone}) => ReceiptOrderData(
        orderId: orderId,
        invoiceNumber: invoiceNumber,
        createdAt: createdAt,
        customerName: customerName,
        phone: phone ?? this.phone,
        address: address,
        items: items,
        bill: bill,
        paymentMethod: paymentMethod,
        statusLabel: statusLabel,
        etaLabel: etaLabel,
        deliverySlotLabel: deliverySlotLabel,
        deliveryTypeLabel: deliveryTypeLabel,
        instructionLines: instructionLines,
        storeName: storeName,
        trackUrl: trackUrl,
        couponCode: couponCode,
        mode: mode,
        paperSize: paperSize,
      );
}

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.qtyLine,
    required this.lineTotal,
  });

  final String name;
  final int quantity;
  /// e.g. `Qty: 1 | 1 kg`
  final String qtyLine;
  final double lineTotal;
}

class ReceiptBill {
  const ReceiptBill({
    required this.subtotal,
    this.couponDiscount = 0,
    this.itemSavings = 0,
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
  final double couponDiscount;
  final double itemSavings;
  final double deliveryFee;
  final double surgeFee;
  final double handlingCharge;
  final double platformFee;
  final double tax;
  final double deliveryPartnerTip;
  final double codConvenienceFee;
  final String codFeeDescription;
  final double grandTotal;

  double get mrpTotal => subtotal + itemSavings;
}
