import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../domain/order_models.dart';
import 'thermal_receipt_pdf.dart';

/// Generates a compact 80mm thermal receipt PDF and shares it.
class InvoiceService {
  const InvoiceService();

  Future<File> generateAndShare(LiveOrder order) async {
    final doc = await ThermalReceiptPdf.build(order);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${order.id}.pdf');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Receipt ${order.id}',
      text: 'Quick Grocery receipt for order ${order.id}',
    );

    return file;
  }
}
