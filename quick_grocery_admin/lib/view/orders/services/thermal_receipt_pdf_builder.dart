import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';

/// Premium 80mm thermal receipt (Blinkit / Zepto style) with UTF-8 INR support.
class ThermalReceiptPdfBuilder {
  ThermalReceiptPdfBuilder._();

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

  static String formatInr(double n) {
    final v = n.abs();
    final s = v == v.roundToDouble() ? _inr0.format(v) : _inr2.format(v);
    return n < 0 ? '-$s' : s;
  }

  static Future<pw.Document> build({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    String storeName = 'QUICK GROCERY',
    String storeSubtitle = 'Fresh groceries • Delivered fast',
    String? deliveryEta,
  }) async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    final date = DateTime.tryParse(order.createdDate);
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
        : order.createdDate;

    final subtotal = order.getSubtotal();
    final delivery = order.deliveryCharge.toDouble();
    var discount = 0.0;
    for (final p in order.products) {
      discount += (p.slashedPrice - p.price) * p.itemCount;
    }
    if (discount < 0) discount = 0;
    final total = order.getTotalAmount();
    final eta = deliveryEta ?? _etaText(order);
    final trackUrl = 'quickgrocery.app/order/${order.id}';
    final qrPayload = trackUrl;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        maxPages: 1,
        build: (ctx) => [
          _header(storeName, storeSubtitle),
          _divider(),
          _metaRow('Order', _shortId(order.id)),
          _metaRow('Date', dateStr),
          pw.SizedBox(height: 3),
          pw.Center(child: _statusBadge(order)),
          pw.SizedBox(height: 4),
          _sectionLabel('CUSTOMER'),
          pw.Text(
            customer?.name ?? order.customerName,
            style: _bold(9),
          ),
          pw.Text(order.phone, style: _muted(8)),
          pw.SizedBox(height: 3),
          _sectionLabel('DELIVER TO'),
          pw.Text(order.address, style: _text(8)),
          if (vendor != null) ...[
            pw.SizedBox(height: 3),
            _sectionLabel('STORE'),
            pw.Text(vendor.shopName, style: _bold(8)),
          ],
          _divider(),
          _sectionLabel('ITEMS'),
          pw.SizedBox(height: 2),
          ...order.products.map(_itemLine),
          _divider(),
          _moneyRow('Subtotal', subtotal),
          if (discount > 0)
            _moneyRow('Discount', -discount, valueColor: PdfColors.green800),
          _moneyRow('Delivery', delivery),
          pw.SizedBox(height: 2),
          _totalRow(total),
          _divider(),
          _metaRow('Payment', order.isPaid ? 'Online (Paid)' : 'Cash on delivery'),
          _metaRow('Status', _statusLabel(order)),
          _metaRow('ETA', eta),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrPayload,
              width: 52,
              height: 52,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'Scan for order tracking',
              style: _muted(7),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Center(
            child: pw.Text(
              'Track: $trackUrl',
              style: _text(7),
              textAlign: pw.TextAlign.center,
            ),
          ),
          _divider(),
          pw.Center(child: pw.Text('Thank you!', style: _bold(9))),
          pw.Center(child: pw.Text('Visit again', style: _muted(7))),
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              'support@quickgrocery.com',
              style: _muted(6.5),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.TextStyle _text(double size, {PdfColor? c}) =>
      pw.TextStyle(fontSize: size, color: c ?? PdfColors.black);

  static pw.TextStyle _bold(double size, {PdfColor? c}) =>
      pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: c);

  static pw.TextStyle _muted(double size) =>
      pw.TextStyle(fontSize: size, color: PdfColors.grey700);

  static pw.Widget _header(String title, String subtitle) => pw.Column(
        children: [
          pw.Center(
            child: pw.Text(
              title,
              style: _bold(13),
              textAlign: pw.TextAlign.center,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Center(
              child: pw.Text(
                subtitle,
                style: _muted(7),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ],
      );

  static pw.Widget _divider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Container(
          width: double.infinity,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey500, width: 0.5),
            ),
          ),
        ),
      );

  static pw.Widget _sectionLabel(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1),
        child: pw.Text(t, style: _bold(7, c: PdfColors.grey800)),
      );

  static pw.Widget _metaRow(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 48,
              child: pw.Text('$label:', style: _muted(7.5)),
            ),
            pw.Expanded(child: pw.Text(value, style: _text(8))),
          ],
        ),
      );

  static pw.Widget _moneyRow(
    String label,
    double amount, {
    PdfColor? valueColor,
  }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 1.5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: _text(8)),
            pw.Text(
              formatInr(amount),
              style: _bold(8, c: valueColor),
            ),
          ],
        ),
      );

  static pw.Widget _totalRow(double total) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('TOTAL', style: _bold(10)),
          pw.Text(formatInr(total), style: _bold(11)),
        ],
      );

  static pw.Widget _itemLine(ProductItem p) {
    final lineTotal = p.price * p.itemCount;
    final name =
        p.name.length > 26 ? '${p.name.substring(0, 26)}…' : p.name;
    final unit = p.unit.isNotEmpty ? ' · ${p.unit}' : '';

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: _bold(8)),
                pw.Text(
                  '${p.itemCount} x ${formatInr(p.price)}$unit',
                  style: _muted(7),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(formatInr(lineTotal), style: _bold(8)),
        ],
      ),
    );
  }

  static pw.Widget _statusBadge(OrderModel order) {
    if (order.isCancelled) {
      return _pill('CANCELLED', PdfColors.red50, PdfColors.red800);
    }
    if (order.isDelivered) {
      return _pill('DELIVERED', PdfColors.green50, PdfColors.green800);
    }
    if (order.isPaid) {
      return _pill('PAID', PdfColors.green50, PdfColors.green800);
    }
    return _pill('COD', const PdfColor.fromInt(0xFFFFF7ED), PdfColors.orange800);
  }

  static pw.Widget _pill(String label, PdfColor bg, PdfColor fg) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Text(label, style: _bold(8, c: fg)),
      );

  static String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 14)}…' : id;

  static String _etaText(OrderModel order) {
    if (order.isDelivered) return 'Delivered';
    if (order.isCancelled) return 'Cancelled';
    return '15-20 mins';
  }

  static String _statusLabel(OrderModel order) {
    if (order.isCancelled) return 'Cancelled';
    if (order.isDelivered) return 'Delivered';
    final s = order.orderStatus.trim();
    return s.isEmpty ? 'Processing' : s;
  }
}
