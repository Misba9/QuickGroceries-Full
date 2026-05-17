import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order_model.dart';
import '../models/vendor_model.dart';
import 'thermal_receipt_pdf.dart';

class InvoiceService {
  Future<pw.Document> generateInvoicePdf(
    OrderModel order,
    VendorModel vendor,
  ) async =>
      ThermalReceiptPdf.build(order, vendor);

  Future<void> printInvoice(OrderModel order, VendorModel vendor) async {
    final pdf = await generateInvoicePdf(order, vendor);
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      format: ThermalReceiptPdf.pageFormat,
      name: 'receipt_${order.id}',
    );
  }

  Future<void> shareInvoice(OrderModel order, VendorModel vendor) async {
    final pdf = await generateInvoicePdf(order, vendor);
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'receipt_${order.id.substring(0, 8)}.pdf',
    );
  }
}
