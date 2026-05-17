import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/order_models.dart';

/// Compact 80mm thermal receipt with Noto Sans (INR + UTF-8).
class ThermalReceiptPdf {
  static const double widthMm = 80;

  static PdfPageFormat get pageFormat => PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        320 * PdfPageFormat.mm,
        marginLeft: 2 * PdfPageFormat.mm,
        marginRight: 2 * PdfPageFormat.mm,
        marginTop: 2 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
      );

  static final _inr0 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );
  static final _inr2 = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String formatInr(num n) {
    final v = n.toDouble().abs();
    final s = v == v.roundToDouble() ? _inr0.format(v) : _inr2.format(v);
    return n < 0 ? '-$s' : s;
  }

  static Future<pw.Document> build(LiveOrder order) async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    final products = order.legacy.products;
    final bill = order.billSnapshot;
    final addr = order.addressSnapshot;
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt.toLocal());
    final paid = order.paymentStatus.toLowerCase().contains('paid') ||
        order.paymentStatus.toLowerCase().contains('success');
    final trackUrl = 'quickgrocery.app/order/${order.id}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        maxPages: 1,
        build: (_) => [
          _header(),
          _divider(),
          _meta('Order', order.id.length > 14 ? '${order.id.substring(0, 14)}…' : order.id),
          _meta('Date', dateStr),
          pw.SizedBox(height: 3),
          pw.Center(child: _badge(paid ? 'PAID' : 'COD', paid)),
          pw.SizedBox(height: 4),
          _label('CUSTOMER'),
          pw.Text(order.customerName, style: _bold(9)),
          pw.Text(order.phone, style: _muted(8)),
          if (addr != null) ...[
            pw.SizedBox(height: 3),
            _label('DELIVER TO'),
            pw.Text(
              '${addr['address'] ?? ''}, ${addr['area'] ?? ''}',
              style: _text(8),
            ),
          ],
          _divider(),
          _label('ITEMS'),
          pw.SizedBox(height: 2),
          ...products.map((p) {
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
                        pw.Text(p.name, style: _bold(8)),
                        pw.Text(
                          '${p.itemCount} x ${formatInr(p.price)}',
                          style: _muted(7),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 6),
                  pw.Text(formatInr(t), style: _bold(8)),
                ],
              ),
            );
          }),
          _divider(),
          ..._billLines(bill),
          pw.SizedBox(height: 2),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL', style: _bold(10)),
              pw.Text(formatInr(order.total), style: _bold(11)),
            ],
          ),
          _divider(),
          _meta('Payment', order.paymentMethodId.toUpperCase()),
          _meta('Status', order.paymentStatus),
          _meta('ETA', '15-20 mins'),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: trackUrl,
              width: 52,
              height: 52,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text('Scan for order tracking', style: _muted(7)),
          ),
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text('Track: $trackUrl', style: _text(7)),
          ),
          _divider(),
          pw.Center(child: pw.Text('Thank you!', style: _bold(9))),
          pw.Center(child: pw.Text('Visit again', style: _muted(7))),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text('support@quickgrocery.com', style: _muted(6.5)),
          ),
        ],
      ),
    );
    return doc;
  }

  static pw.TextStyle _text(double s) => pw.TextStyle(fontSize: s);
  static pw.TextStyle _bold(double s, {PdfColor? color}) =>
      pw.TextStyle(
        fontSize: s,
        fontWeight: pw.FontWeight.bold,
        color: color,
      );
  static pw.TextStyle _muted(double s) =>
      pw.TextStyle(fontSize: s, color: PdfColors.grey700);

  static pw.Widget _header() => pw.Column(
        children: [
          pw.Center(child: pw.Text('QUICK GROCERY', style: _bold(13))),
          pw.SizedBox(height: 1),
          pw.Center(
            child: pw.Text(
              'Fresh groceries • Delivered fast',
              style: _muted(7),
            ),
          ),
        ],
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

  static pw.Widget _label(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Text(t, style: _bold(7, color: PdfColors.grey800)),
      );

  static pw.Widget _meta(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 48, child: pw.Text('$k:', style: _muted(7.5))),
            pw.Expanded(child: pw.Text(v, style: _text(8))),
          ],
        ),
      );

  static List<pw.Widget> _billLines(Map<String, dynamic> bill) {
    const keys = [
      ('Subtotal', 'subtotal'),
      ('Coupon', 'couponDiscount'),
      ('Delivery', 'deliveryFee'),
      ('Surge', 'surgeFee'),
      ('Handling', 'handlingCharge'),
      ('Platform fee', 'platformFee'),
      ('Tax', 'tax'),
    ];
    return [
      for (final (title, key) in keys)
        if (bill[key] != null && (bill[key] as num) != 0)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1.5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(title, style: _text(8)),
                pw.Text(formatInr(bill[key] as num), style: _bold(8)),
              ],
            ),
          ),
    ];
  }

  static pw.Widget _badge(String label, bool paid) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: pw.BoxDecoration(
          color: paid ? PdfColors.green50 : const PdfColor.fromInt(0xFFFFF7ED),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(
          label,
          style: _bold(
            8,
            color: paid ? PdfColors.green800 : PdfColors.orange800,
          ),
        ),
      );
}
