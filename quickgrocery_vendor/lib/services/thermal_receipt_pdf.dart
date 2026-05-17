import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order_model.dart';
import '../models/vendor_model.dart';

/// Store copy — 80mm thermal receipt with Noto Sans (INR).
class ThermalReceiptPdf {
  static const double widthMm = 80;

  static PdfPageFormat get pageFormat => PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        280 * PdfPageFormat.mm,
        marginLeft: 2 * PdfPageFormat.mm,
        marginRight: 2 * PdfPageFormat.mm,
        marginTop: 2 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
      );

  static String formatInr(double n) {
    final whole = n == n.roundToDouble();
    final text = whole
        ? '₹${n.round()}'
        : '₹${n.toStringAsFixed(2)}';
    return text;
  }

  static Future<pw.Document> build(
    OrderModel order,
    VendorModel vendor,
  ) async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final items =
        order.products.where((p) => p.vendorId == vendor.id).toList();
    var subtotal = 0.0;
    for (final p in items) {
      subtotal += p.price * p.itemCount;
    }

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );
    final date = DateTime.tryParse(order.createdDate);
    final dateStr = date != null ? _formatDate(date) : order.createdDate;
    final trackUrl = 'quickgrocery.app/order/${order.id}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        maxPages: 1,
        build: (_) => [
          pw.Center(
            child: pw.Text(
              vendor.shopName.toUpperCase(),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Center(
            child: pw.Text(
              'Store packing slip',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ),
          _divider(),
          _row('Order', order.id),
          _row('Date', dateStr),
          pw.SizedBox(height: 3),
          pw.Center(child: _badge(order.isPaid ? 'PAID' : 'COD', order.isPaid)),
          pw.SizedBox(height: 4),
          _row('Customer', order.customerName),
          pw.Text(order.phone, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 2),
          pw.Text('DELIVER TO', style: _labelStyle()),
          pw.Text(order.address, style: const pw.TextStyle(fontSize: 8)),
          _divider(),
          pw.Text('ITEMS', style: _labelStyle()),
          pw.SizedBox(height: 2),
          ...items.map((p) {
            final t = p.price * p.itemCount;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          p.name,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${p.itemCount} x ${formatInr(p.price)}',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    formatInr(t),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          _divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Store total', style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                formatInr(subtotal),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: trackUrl,
              width: 48,
              height: 48,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'Track: $trackUrl',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              'Pack with care',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return doc;
  }

  static pw.TextStyle _labelStyle() => pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey800,
      );

  static pw.Widget _divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
            ),
          ),
        ),
      );

  static pw.Widget _row(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 52,
              child: pw.Text(
                '$k:',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
            ),
            pw.Expanded(child: pw.Text(v, style: const pw.TextStyle(fontSize: 8))),
          ],
        ),
      );

  static pw.Widget _badge(String label, bool paid) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: pw.BoxDecoration(
          color: paid ? PdfColors.green50 : const PdfColor.fromInt(0xFFFFF7ED),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: paid ? PdfColors.green800 : PdfColors.orange800,
          ),
        ),
      );

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }
}
