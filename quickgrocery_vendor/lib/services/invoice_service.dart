import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import '../models/order_model.dart';
import '../models/vendor_model.dart';
import 'thermal_receipt_pdf.dart';

class InvoiceService {
  Future<pw.Document> generateInvoicePdf(
    OrderModel order,
    VendorModel vendor, {
    ReceiptMode mode = ReceiptMode.invoice,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async =>
      ThermalReceiptPdf.build(
        order,
        vendor,
        mode: mode,
        paperSize: paperSize,
      );

  Future<void> printInvoice(
    OrderModel order,
    VendorModel vendor, {
    ReceiptMode mode = ReceiptMode.invoice,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    final pdf = await generateInvoicePdf(
      order,
      vendor,
      mode: mode,
      paperSize: paperSize,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      format: ThermalReceiptPdf.pageFormatFor(
        order,
        vendor,
        mode: mode,
        paperSize: paperSize,
      ),
      name: 'receipt_${order.id}',
    );
  }

  Future<void> shareInvoice(
    OrderModel order,
    VendorModel vendor, {
    ReceiptMode mode = ReceiptMode.invoice,
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    final pdf = await generateInvoicePdf(
      order,
      vendor,
      mode: mode,
      paperSize: paperSize,
    );
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt_${order.id.substring(0, 8)}.pdf',
    );
  }
}
