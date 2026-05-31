import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import '../models/order_model.dart';
import 'order_bill_totals.dart';
import 'receipt_product_format.dart';

class ReceiptOrderMapper {
  ReceiptOrderMapper._();

  static ReceiptOrderData fromOrder(
    OrderModel order, {
    required String vendorId,
    ReceiptMode mode = ReceiptMode.invoice,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
    String? storeName,
  }) {
    final products = order.products
        .where((p) => p.vendorId == vendorId)
        .toList();
    final bill = OrderBillTotals.resolve(order);

    return ReceiptOrderData(
      orderId: order.id,
      invoiceNumber: _invoiceId(order.id),
      createdAt: DateTime.tryParse(order.createdDate) ?? order.createdAt,
      customerName: order.customerName,
      phone: order.phone,
      address: order.address,
      items: products
          .map(
            (p) => ReceiptLineItem(
              name: p.name,
              quantity: p.itemCount,
              qtyLine: productInvoiceQtyLine(p),
              lineTotal: productLineAmount(p),
            ),
          )
          .toList(),
      bill: ReceiptBill(
        subtotal: bill.subtotal,
        couponDiscount: bill.couponDiscount,
        itemSavings: bill.itemSavings,
        deliveryFee: bill.deliveryFee,
        surgeFee: bill.surgeFee,
        handlingCharge: bill.handlingCharge,
        platformFee: bill.platformFee,
        tax: bill.tax,
        grandTotal: bill.grandTotal,
      ),
      paymentMethod: order.isPaid ? 'Online (Paid)' : 'Cash on Delivery',
      statusLabel: _statusLabel(order),
      etaLabel: '15-20 min',
      deliverySlotLabel: order.deliverySlotRaw != null
          ? _slotLabel(order.deliverySlotRaw!)
          : null,
      deliveryTypeLabel: order.deliveryType.trim().isNotEmpty
          ? order.deliveryType
          : null,
      instructionLines: order.deliveryInstructionsRaw != null
          ? _instructionLines(order.deliveryInstructionsRaw!)
          : const [],
      storeName: storeName,
      mode: mode,
      paperSize: paperSize,
    );
  }

  static String _invoiceId(String id) {
    final short =
        id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
    return short;
  }

  static String _statusLabel(OrderModel order) {
    if (order.isCancelled) return 'Cancelled';
    if (order.isDelivered) return 'Delivered';
    final s = order.modernStatus.trim().isNotEmpty
        ? order.modernStatus
        : order.orderStatus.trim();
    return s.isEmpty ? 'Pending' : s;
  }

  static String _slotLabel(Map<String, dynamic> slot) {
    final name = (slot['slotName'] ?? slot['label'] ?? '').toString();
    final express = slot['isExpress'] == true ||
        slot['slotType']?.toString().toLowerCase() == 'express';
    if (express) {
      final cleaned = name.replaceAll(
        RegExp(r'^Express\s*[·•\-]\s*', caseSensitive: false),
        '',
      );
      return 'Express • $cleaned';
    }
    return name.isEmpty ? 'Scheduled' : name;
  }

  static List<String> _instructionLines(Map<String, dynamic> m) {
    final lines = <String>[];
    final gate = (m['gateCode'] ?? m['gate_code'] ?? '').toString();
    final landmark = (m['landmark'] ?? '').toString();
    final notes = (m['notes'] ?? '').toString();
    final text = (m['instructionText'] ?? m['text'] ?? '').toString();
    if (gate.isNotEmpty) lines.add('Gate code: $gate');
    if (landmark.isNotEmpty) lines.add('Landmark: $landmark');
    if (m['leaveAtDoor'] == true || m['leave_at_door'] == true) {
      lines.add('Leave at door');
    }
    if (notes.isNotEmpty) lines.add('Notes: $notes');
    if (lines.isEmpty && text.isNotEmpty) lines.add(text);
    return lines;
  }
}
