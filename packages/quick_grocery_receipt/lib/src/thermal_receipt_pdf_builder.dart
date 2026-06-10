import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'receipt_models.dart';
import 'receipt_options.dart';

/// Unified 58mm / 80mm / A4 thermal receipt PDF (PeriPeri 80mm compatible).
class ThermalReceiptPdfBuilder {
  ThermalReceiptPdfBuilder._();

  static const String brandTitle = 'QUICK GROCERIES';
  static const String brandSubtitle = 'Fresh groceries delivered fast';
  static const String supportEmail = 'support@quickgrocery.com';

  static PdfPageFormat pageFormatFor(ReceiptOrderData data) {
    final w = data.paperSize.widthMm;
    final itemCount = data.items.length;
    final baseMm = data.isPackingSlip ? 160.0 : 200.0;
    final heightMm = (baseMm + itemCount * 14.0).clamp(220.0, 900.0);
    final margin = data.paperSize == ReceiptPaperSize.a4 ? 8.0 : 2.0;
    return PdfPageFormat(
      w * PdfPageFormat.mm,
      heightMm * PdfPageFormat.mm,
      marginLeft: margin * PdfPageFormat.mm,
      marginRight: margin * PdfPageFormat.mm,
      marginTop: margin * PdfPageFormat.mm,
      marginBottom: margin * PdfPageFormat.mm,
    );
  }

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

  static Future<pw.Document> build(ReceiptOrderData data) async {
    final mono = pw.Font.courier();
    final monoBold = pw.Font.courierBold();
    final inrBold = await PdfGoogleFonts.notoSansBold();

    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load(
        'packages/quick_grocery_receipt/assets/images/qg_logo.png',
      );
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final scale = _fontScale(data.paperSize);
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: mono,
        bold: monoBold,
      ),
    );

    final date = data.createdAt;
    final dateStr = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : '—';
    final timeStr =
        date != null ? DateFormat('hh:mm a').format(date) : '—';

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormatFor(data),
        maxPages: 1,
        build: (context) => [
          _logoHeader(logo, scale),
          _divider(),
          _labelValue('Invoice', data.invoiceNumber, scale),
          _labelValue('Date', dateStr, scale),
          _labelValue('Time', timeStr, scale),
          pw.SizedBox(height: 2 * scale),
          _labelValue('Payment', data.paymentMethod, scale),
          _labelValue('Status', data.statusLabel, scale),
          _divider(),
          _sectionTitle('CUSTOMER', scale),
          _labelValue('Name', data.customerName, scale),
          _labelValue('Phone', data.phone, scale),
          pw.SizedBox(height: 2 * scale),
          pw.Text('Address:', style: _muted(scale)),
          pw.Text(data.address, style: _body(scale)),
          _divider(),
          _sectionTitle('DELIVERY', scale),
          if (data.deliverySlotLabel != null &&
              data.deliverySlotLabel!.isNotEmpty)
            _labelValue('Slot', data.deliverySlotLabel!, scale),
          if (data.deliveryTypeLabel != null &&
              data.deliveryTypeLabel!.isNotEmpty)
            _labelValue('Type', data.deliveryTypeLabel!, scale),
          if (data.instructionLines.isNotEmpty) ...[
            pw.Text('Instructions:', style: _muted(scale)),
            ...data.instructionLines.map(
              (l) => pw.Text(l, style: _body(scale)),
            ),
          ],
          if (data.storeName != null && data.storeName!.isNotEmpty) ...[
            pw.SizedBox(height: 2 * scale),
            _labelValue('Store', data.storeName!, scale),
          ],
          _divider(),
          _productTableHeader(data, scale),
          pw.SizedBox(height: 2 * scale),
          ...data.items.asMap().entries.map(
                (e) => _productRow(
                  index: e.key + 1,
                  item: e.value,
                  data: data,
                  scale: scale,
                  inrBold: inrBold,
                ),
              ),
          _divider(),
          pw.Text(
            'Items: ${data.items.length}',
            style: _bold(scale),
          ),
          if (data.showPrices) ...[
            _divider(dashed: false),
            _sectionTitle('TOTALS', scale),
            _moneyRow(
              'MRP Total',
              data.bill.subtotal + data.bill.itemSavings,
              scale,
              inrBold,
            ),
            if (data.bill.itemSavings > 0)
              _moneyRow(
                'Product Discount',
                -data.bill.itemSavings,
                scale,
                inrBold,
              ),
            _moneyRow('Item Total', data.bill.subtotal, scale, inrBold),
            if (data.bill.couponDiscount > 0)
              _moneyRow(
                data.couponCode != null && data.couponCode!.isNotEmpty
                    ? 'Coupon (${data.couponCode})'
                    : 'Coupon Discount',
                -data.bill.couponDiscount,
                scale,
                inrBold,
              ),
            if (data.bill.deliveryFee > 0 || !data.isPackingSlip)
              _moneyRow('Delivery Fee', data.bill.deliveryFee, scale, inrBold),
            if (data.bill.platformFee > 0)
              _moneyRow('Platform Fee', data.bill.platformFee, scale, inrBold),
            if (data.bill.surgeFee > 0)
              _moneyRow('Surge Fee', data.bill.surgeFee, scale, inrBold),
            if (data.bill.handlingCharge > 0)
              _moneyRow('Handling', data.bill.handlingCharge, scale, inrBold),
            if (data.bill.tax > 0)
              _moneyRow('Tax', data.bill.tax, scale, inrBold),
            _divider(),
            _grandTotalRow(data.bill.grandTotal, scale, inrBold),
          ],
          _divider(),
          _sectionTitle('PAYMENT', scale),
          _labelValue('Payment', data.paymentMethod, scale),
          _labelValue('Status', data.statusLabel, scale),
          _labelValue('ETA', data.etaLabel, scale),
          _divider(),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: data.trackingUrl,
              width: 48 * scale,
              height: 48 * scale,
            ),
          ),
          pw.SizedBox(height: 3 * scale),
          pw.Center(
            child: pw.Text(
              'Scan to track order',
              style: _muted(scale),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 2 * scale),
          pw.Center(
            child: pw.Text(
              data.trackingUrl,
              style: _body(scale, size: 7),
              textAlign: pw.TextAlign.center,
            ),
          ),
          _divider(),
          pw.Center(child: pw.Text('Thank You!', style: _bold(scale, size: 10))),
          pw.Center(
            child: pw.Text(
              data.isPackingSlip ? 'Pack with care' : 'Visit again',
              style: _muted(scale),
            ),
          ),
          pw.SizedBox(height: 2 * scale),
          pw.Center(
            child: pw.Text(supportEmail, style: _muted(scale, size: 6.5)),
          ),
        ],
      ),
    );

    return doc;
  }

  static double _fontScale(ReceiptPaperSize size) => switch (size) {
        ReceiptPaperSize.mm58 => 0.88,
        ReceiptPaperSize.mm80 => 1.0,
        ReceiptPaperSize.a4 => 1.15,
      };

  static pw.Widget _logoHeader(pw.ImageProvider? logo, double scale) =>
      pw.Column(
        children: [
          if (logo != null)
            pw.Center(
              child: pw.Image(logo, width: 36 * scale, height: 36 * scale),
            ),
          if (logo != null) pw.SizedBox(height: 4 * scale),
          pw.Center(
            child: pw.Text(
              brandTitle,
              style: _bold(scale, size: 11),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 1 * scale),
          pw.Center(
            child: pw.Text(
              brandSubtitle,
              style: _muted(scale),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      );

  static pw.Widget _productTableHeader(ReceiptOrderData data, double scale) {
    if (!data.showPrices) {
      return pw.Row(
        children: [
          pw.SizedBox(width: 16 * scale, child: pw.Text('NO', style: _bold(scale, size: 7))),
          pw.Expanded(child: pw.Text('PRODUCT', style: _bold(scale, size: 7))),
        ],
      );
    }
    return pw.Row(
      children: [
        pw.SizedBox(width: 14 * scale, child: pw.Text('NO', style: _bold(scale, size: 7))),
        pw.Expanded(child: pw.Text('PRODUCT', style: _bold(scale, size: 7))),
        pw.Text('AMOUNT', style: _bold(scale, size: 7)),
      ],
    );
  }

  static pw.Widget _productRow({
    required int index,
    required ReceiptLineItem item,
    required ReceiptOrderData data,
    required double scale,
    required pw.Font inrBold,
  }) {
    final name = item.name;
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4 * scale),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 14 * scale,
                child: pw.Text('$index', style: _body(scale, size: 8)),
              ),
              pw.Expanded(
                child: pw.Text(
                  name,
                  style: _bold(scale, size: 8),
                  maxLines: 3,
                ),
              ),
              if (data.showPrices)
                pw.Text(
                  formatInr(item.lineTotal),
                  style: pw.TextStyle(
                    font: inrBold,
                    fontSize: 8 * scale,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
          pw.Padding(
            padding: pw.EdgeInsets.only(left: 14 * scale, top: 1 * scale),
            child: pw.Text(item.qtyLine, style: _muted(scale, size: 7)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _grandTotalRow(
    double total,
    double scale,
    pw.Font inrBold,
  ) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GRAND TOTAL', style: _bold(scale, size: 10)),
          pw.Text(
            formatInr(total),
            style: pw.TextStyle(
              font: inrBold,
              fontSize: 11 * scale,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      );

  static pw.Widget _moneyRow(
    String label,
    double amount,
    double scale,
    pw.Font inrFont,
  ) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 1.5 * scale),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: _body(scale, size: 8)),
            pw.Text(
              formatInr(amount),
              style: pw.TextStyle(font: inrFont, fontSize: 8 * scale),
            ),
          ],
        ),
      );

  static pw.Widget _labelValue(String label, String value, double scale) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 1.2 * scale),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 52 * scale,
              child: pw.Text('$label:', style: _muted(scale)),
            ),
            pw.Expanded(child: pw.Text(value, style: _body(scale))),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String t, double scale) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 2 * scale, top: 1 * scale),
        child: pw.Text(t, style: _bold(scale, size: 8)),
      );

  static pw.Widget _divider({bool dashed = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(
                color: PdfColors.grey600,
                width: dashed ? 0.3 : 0.5,
                style: dashed ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
              ),
            ),
          ),
        ),
      );

  static pw.TextStyle _body(double scale, {double size = 8}) =>
      pw.TextStyle(fontSize: size * scale);

  static pw.TextStyle _bold(double scale, {double size = 8}) =>
      pw.TextStyle(
        fontSize: size * scale,
        fontWeight: pw.FontWeight.bold,
      );

  static pw.TextStyle _muted(double scale, {double size = 7.5}) =>
      pw.TextStyle(fontSize: size * scale, color: PdfColors.grey700);
}
