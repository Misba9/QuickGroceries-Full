import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/orders/utils/receipt_order_mapper.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart' as receipt;

/// Admin wrapper — delegates to shared thermal template.
class ThermalReceiptPdfBuilder {
  ThermalReceiptPdfBuilder._();

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

  static Future<pw.Document> build({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
    String? deliveryEta,
  }) async {
    final data = ReceiptOrderMapper.fromOrder(
      order,
      mode: mode,
      paperSize: paperSize,
      storeName: vendor?.shopName,
      etaLabel: deliveryEta,
      customerNameOverride: customer?.name,
    );
    return receipt.ThermalReceiptPdfBuilder.build(data);
  }

  static PdfPageFormat pageFormatForOrder(
    OrderModel order, {
    receipt.ReceiptMode mode = receipt.ReceiptMode.invoice,
    receipt.ReceiptPaperSize paperSize = receipt.ReceiptPaperSize.mm80,
  }) =>
      receipt.ThermalReceiptPdfBuilder.pageFormatFor(
        ReceiptOrderMapper.fromOrder(order, mode: mode, paperSize: paperSize),
      );
}
