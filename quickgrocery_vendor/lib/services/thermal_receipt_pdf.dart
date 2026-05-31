import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart' as receipt;

import '../models/order_model.dart';
import '../models/vendor_model.dart';
import '../utils/receipt_order_mapper.dart';

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

  static Future<pw.Document> build(
    OrderModel order,
    VendorModel vendor, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) async {
    final data = ReceiptOrderMapper.fromOrder(
      order,
      vendorId: vendor.id,
      mode: mode,
      paperSize: paperSize,
      storeName: vendor.shopName,
    );
    return receipt.ThermalReceiptPdfBuilder.build(data);
  }

  static PdfPageFormat pageFormatFor(
    OrderModel order,
    VendorModel vendor, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) =>
      receipt.ThermalReceiptPdfBuilder.pageFormatFor(
        ReceiptOrderMapper.fromOrder(
          order,
          vendorId: vendor.id,
          mode: mode,
          paperSize: paperSize,
          storeName: vendor.shopName,
        ),
      );
}
