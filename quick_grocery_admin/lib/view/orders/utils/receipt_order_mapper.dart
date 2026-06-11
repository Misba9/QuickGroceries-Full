import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_bill_totals.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_eta_utils.dart';
import 'package:quick_grocery_admin/view/orders/utils/receipt_product_format.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

/// Maps admin [OrderModel] → shared [ReceiptOrderData].
class ReceiptOrderMapper {
  ReceiptOrderMapper._();

  static ReceiptOrderData fromOrder(
    OrderModel order, {
    ReceiptMode mode = ReceiptMode.invoice,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
    String? storeName,
    List<ProductItem>? productsOverride,
    String? etaLabel,
    String? customerNameOverride,
    CustomerModel? customer,
  }) {
    final products = productsOverride ?? order.products;
    final bill = OrderBillTotals.resolve(order);
    final phone = _resolvePhone(order, customer);

    return ReceiptOrderData(
      orderId: order.id,
      invoiceNumber: _invoiceId(order.id),
      createdAt: DateTime.tryParse(order.createdDate),
      customerName: customerNameOverride ?? order.customerName,
      phone: phone,
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
        deliveryPartnerTip: bill.deliveryPartnerTip,
        grandTotal: bill.grandTotal,
      ),
      paymentMethod: order.isPaid ? 'Online (Paid)' : 'Cash on Delivery',
      statusLabel: _statusLabel(order),
      etaLabel: etaLabel ?? OrderEtaUtils.etaLabel(order),
      deliverySlotLabel: order.deliverySlot != null
          ? order.deliverySlotLabel
          : null,
      deliveryTypeLabel: order.deliveryType.trim().isNotEmpty
          ? order.deliveryType
          : (order.deliverySlot?.isExpress == true
              ? 'Express Delivery'
              : null),
      instructionLines: order.deliveryInstructions?.displayLines() ?? const [],
      storeName: storeName,
      couponCode: order.couponCode,
      mode: mode,
      paperSize: paperSize,
    );
  }

  static String _invoiceId(String id) {
    final short =
        id.length > 8 ? id.substring(id.length - 8).toUpperCase() : id.toUpperCase();
    return short;
  }

  static String _resolvePhone(OrderModel order, CustomerModel? customer) {
    final onOrder = order.phone.trim();
    if (onOrder.isNotEmpty) return onOrder;
    final fromProfile = customer?.phoneNumber.trim() ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    return '';
  }

  static String _statusLabel(OrderModel order) {
    if (order.isCancelled) return 'Cancelled';
    if (order.isDelivered) return 'Delivered';
    final s = order.orderStatus.trim();
    return s.isEmpty ? 'Pending' : s;
  }
}
