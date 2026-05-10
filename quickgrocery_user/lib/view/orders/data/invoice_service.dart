import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../domain/order_models.dart';

/// Generates a clean PDF invoice for a [LiveOrder] and shares it via the
/// system share sheet. Designed to work entirely on-device — no Cloud
/// Function dependency.
class InvoiceService {
  const InvoiceService();

  String _money(num v) => 'Rs. ${v.toStringAsFixed(2)}';

  Future<File> generateAndShare(LiveOrder order) async {
    final doc = pw.Document();
    final money = _money;
    final addr = order.addressSnapshot;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Quick Grocery',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Tax invoice',
                      style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Order #${order.id}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      order.createdAt.toLocal().toString().split('.').first,
                      style: const pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Billed to',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(order.customerName),
                    pw.Text(order.phone),
                    if (addr != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${addr['address'] ?? ''}, ${addr['area'] ?? ''}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(order.paymentMethodId.toUpperCase()),
                    pw.Text('Status: ${order.paymentStatus}'),
                    if ((order.paymentRef ?? '').isNotEmpty)
                      pw.Text(
                        'Ref: ${order.paymentRef}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.black),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headers: const ['Item', 'Qty', 'Price', 'Total'],
            data: order.legacy.products
                .map((p) => [
                      p.name,
                      '${p.itemCount}',
                      money(p.price),
                      money(p.price * p.itemCount),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  ..._billRows(order.billSnapshot, money),
                  pw.Divider(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        money(order.total),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thank you for shopping with Quick Grocery.',
            style: const pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/invoice_${order.id}.pdf');
    await file.writeAsBytes(await doc.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Invoice ${order.id}',
      text: 'Quick Grocery invoice for order ${order.id}',
    );

    return file;
  }

  List<pw.Widget> _billRows(
    Map<String, dynamic> bill,
    String Function(num) money,
  ) {
    final entries = <(String, num?)>[
      ('Subtotal', bill['subtotal'] as num?),
      ('Coupon', bill['couponDiscount'] as num?),
      ('Delivery', bill['deliveryFee'] as num?),
      ('Surge', bill['surgeFee'] as num?),
      ('Handling', bill['handlingCharge'] as num?),
      ('Platform fee', bill['platformFee'] as num?),
      ('Tax', bill['tax'] as num?),
    ];
    return [
      for (final (title, v) in entries)
        if (v != null)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(money(v), style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
    ];
  }
}
