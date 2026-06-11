import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart' as receipt;

import '../models/order_model.dart';
import '../models/vendor_model.dart';
import '../services/customer_phone_resolver.dart';
import '../utils/receipt_order_mapper.dart';
import '../utils/vendor_order_display.dart';

/// Vendor wrapper — same template as admin (80mm thermal).
class ThermalReceiptPdf {
  static const double widthMm = 80;

  static PdfPageFormat get pageFormat => PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        400 * PdfPageFormat.mm,
        marginLeft: 2 * PdfPageFormat.mm,
        marginRight: 2 * PdfPageFormat.mm,
        marginTop: 2 * PdfPageFormat.mm,
        marginBottom: 2 * PdfPageFormat.mm,
      );

  static String formatInr(double n) =>
      receipt.ThermalReceiptPdfBuilder.formatInr(n);

  static Future<receipt.ReceiptOrderData> receiptData(
    OrderModel order,
    VendorModel vendor, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) async {
    final resolved = await CustomerPhoneResolver.resolve(
      orderPhone: order.phone,
      customerUid: order.uuid,
    );
    final displayPhone = VendorOrderDisplay.formatPhone(
      resolved.isNotEmpty ? resolved : order.phone,
    );
    return ReceiptOrderMapper.fromOrder(
      order,
      vendorId: vendor.id,
      mode: mode,
      paperSize: paperSize,
      storeName: vendor.shopName,
      phone: displayPhone,
    );
  }

  static Future<pw.Document> build(
    OrderModel order,
    VendorModel vendor, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) async {
    final data = await receiptData(order, vendor, mode: mode, paperSize: paperSize);
    return receipt.ThermalReceiptPdfBuilder.build(data);
  }

  static Future<PdfPageFormat> pageFormatFor(
    OrderModel order,
    VendorModel vendor, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) async =>
      receipt.ThermalReceiptPdfBuilder.pageFormatFor(
        await receiptData(order, vendor, mode: mode, paperSize: paperSize),
      );
}
