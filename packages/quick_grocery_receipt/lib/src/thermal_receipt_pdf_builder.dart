import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'receipt_models.dart';
import 'receipt_options.dart';
import 'order_date_time_format.dart';

/// Unified 58mm / 80mm / A4 thermal receipt PDF (PeriPeri 80mm compatible).
class ThermalReceiptPdfBuilder {
  ThermalReceiptPdfBuilder._();

  static const String brandTitle = 'Quick Groceries';
  static const String brandSubtitle = 'Fresh groceries delivered fast';
  static const String supportEmail = 'support@quickgrocery.com';

  static const PdfColor _ink = PdfColors.black;
  static const PdfColor _label = PdfColor.fromInt(0xFF333333);

  static PdfPageFormat pageFormatFor(ReceiptOrderData data) {
    final w = data.paperSize.widthMm;
    final itemCount = data.items.length;
    final baseMm = data.isPackingSlip ? 180.0 : 240.0;
    final heightMm = (baseMm + itemCount * 14.0).clamp(260.0, 960.0);
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

  /// Local wall-clock from order createdAt (UTC → device timezone).
  static String formatDateTime(DateTime? date) =>
      OrderDateTimeFormat.format(date);

  static Future<pw.Document> build(ReceiptOrderData data) async {
    final base = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load(
        'packages/quick_grocery_receipt/assets/images/qg_logo.png',
      );
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}

    final scale = _fontScale(data.paperSize);
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: base, bold: bold),
    );

    final dateTimeStr = formatDateTime(data.createdAt);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormatFor(data),
        maxPages: 1,
        build: (context) => [
          _brandHeader(logo, scale, bold),
          _divider(),
          _labelValue('Invoice', data.invoiceNumber, scale, bold),
          _labelValue('Date & Time', dateTimeStr, scale, bold),
          _labelValue('Payment', data.paymentMethod, scale, bold),
          _divider(),
          _sectionTitle('CUSTOMER', scale, bold),
          _labelValue('Name', data.customerName, scale, bold),
          _labelValue(
            'Phone',
            data.phone.trim().isNotEmpty ? data.phone : '—',
            scale,
            bold,
          ),
          pw.SizedBox(height: 2 * scale),
          pw.Text('Address:', style: _labelStyle(scale)),
          pw.Text(data.address, style: _body(scale, bold: bold)),
          _divider(),
          _sectionTitle('DELIVERY', scale, bold),
          if (data.deliverySlotLabel != null &&
              data.deliverySlotLabel!.isNotEmpty)
            _labelValue('Slot', data.deliverySlotLabel!, scale, bold),
          if (data.typeAndStoreLine != null)
            _labelValue('Type & Store', data.typeAndStoreLine!, scale, bold),
          if (data.instructionLines.isNotEmpty) ...[
            pw.Text('Instructions:', style: _labelStyle(scale)),
            ...data.instructionLines.map(
              (l) => pw.Text(l, style: _body(scale, bold: bold)),
            ),
          ],
          _divider(),
          _productTableHeader(data, scale, bold),
          pw.SizedBox(height: 2 * scale),
          ...data.items.asMap().entries.map(
                (e) => _productRow(
                  index: e.key + 1,
                  item: e.value,
                  data: data,
                  scale: scale,
                  bold: bold,
                ),
              ),
          _divider(),
          pw.Text(
            'Items: ${data.items.length}',
            style: _boldStyle(scale, size: 9, font: bold),
          ),
          if (data.showPrices) ...[
            _divider(dashed: false),
            _sectionTitle('TOTALS', scale, bold),
            ..._totalRows(data, scale, bold),
            _divider(),
            _grandTotalRow(data.bill.grandTotal, scale, bold),
          ],
          _divider(),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: data.trackingUrl,
              color: _ink,
              drawText: false,
              width: 52 * scale,
              height: 52 * scale,
            ),
          ),
          pw.SizedBox(height: 3 * scale),
          pw.Center(
            child: pw.Text(
              'Scan to track order',
              style: _labelStyle(scale),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 2 * scale),
          pw.Center(
            child: pw.Text(
              data.trackingUrl,
              style: _body(scale, size: 7, bold: bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
          _divider(),
          pw.Center(
            child: pw.Text(
              'Thank You!',
              style: _boldStyle(scale, size: 11, font: bold),
            ),
          ),
          pw.Center(
            child: pw.Text(
              data.isPackingSlip ? 'Pack with care' : 'Visit again',
              style: _labelStyle(scale),
            ),
          ),
          pw.SizedBox(height: 2 * scale),
          pw.Center(
            child: pw.Text(supportEmail, style: _labelStyle(scale, size: 7)),
          ),
        ],
      ),
    );

    return doc;
  }

  static List<pw.Widget> _totalRows(
    ReceiptOrderData data,
    double scale,
    pw.Font bold,
  ) {
    final b = data.bill;
    final rows = <pw.Widget>[
      _moneyRow('MRP Total', b.mrpTotal, scale, bold),
      if (b.itemSavings > 0)
        _moneyRow('Product Discount', -b.itemSavings, scale, bold),
      _moneyRow('Item Total', b.subtotal, scale, bold),
      if (b.couponDiscount > 0)
        _moneyRow(
          data.couponCode != null && data.couponCode!.isNotEmpty
              ? 'Coupon (${data.couponCode})'
              : 'Coupon Discount',
          -b.couponDiscount,
          scale,
          bold,
        ),
      _moneyRow('Delivery Fee', b.deliveryFee, scale, bold),
      if (b.platformFee > 0)
        _moneyRow('Platform Fee', b.platformFee, scale, bold),
      if (b.surgeFee > 0) _moneyRow('Surge Fee', b.surgeFee, scale, bold),
      if (b.handlingCharge > 0)
        _moneyRow('Handling Charge', b.handlingCharge, scale, bold),
      if (b.tax > 0) _moneyRow('Tax', b.tax, scale, bold),
      if (b.codConvenienceFee > 0)
        _moneyRow(
          b.codFeeDescription.isNotEmpty
              ? b.codFeeDescription
              : 'COD Convenience Fee',
          b.codConvenienceFee,
          scale,
          bold,
        ),
      if (b.deliveryPartnerTip > 0)
        _moneyRow('Delivery Partner Tip', b.deliveryPartnerTip, scale, bold),
    ];
    return rows;
  }

  static double _fontScale(ReceiptPaperSize size) => switch (size) {
        ReceiptPaperSize.mm58 => 0.88,
        ReceiptPaperSize.mm80 => 1.0,
        ReceiptPaperSize.a4 => 1.15,
      };

  static pw.Widget _brandHeader(
    pw.ImageProvider? logo,
    double scale,
    pw.Font bold,
  ) =>
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Image(logo, width: 40 * scale, height: 40 * scale),
          if (logo != null) pw.SizedBox(width: 8 * scale),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  brandTitle,
                  style: _boldStyle(scale, size: 12, font: bold),
                ),
                pw.SizedBox(height: 2 * scale),
                pw.Text(
                  brandSubtitle,
                  style: _labelStyle(scale, size: 8),
                ),
              ],
            ),
          ),
        ],
      );

  static pw.Widget _productTableHeader(
    ReceiptOrderData data,
    double scale,
    pw.Font bold,
  ) {
    final header = _boldStyle(scale, size: 7.5, font: bold);
    if (!data.showPrices) {
      return pw.Row(
        children: [
          pw.SizedBox(width: 16 * scale, child: pw.Text('NO', style: header)),
          pw.Expanded(child: pw.Text('PRODUCT', style: header)),
        ],
      );
    }
    return pw.Row(
      children: [
        pw.SizedBox(width: 14 * scale, child: pw.Text('NO', style: header)),
        pw.Expanded(child: pw.Text('PRODUCT', style: header)),
        pw.Text('AMOUNT', style: header),
      ],
    );
  }

  static pw.Widget _productRow({
    required int index,
    required ReceiptLineItem item,
    required ReceiptOrderData data,
    required double scale,
    required pw.Font bold,
  }) {
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
                child: pw.Text('$index', style: _body(scale, size: 8, bold: bold)),
              ),
              pw.Expanded(
                child: pw.Text(
                  item.name,
                  style: _boldStyle(scale, size: 8.5, font: bold),
                  maxLines: 3,
                ),
              ),
              if (data.showPrices)
                pw.Text(
                  formatInr(item.lineTotal),
                  style: _boldStyle(scale, size: 8.5, font: bold),
                ),
            ],
          ),
          pw.Padding(
            padding: pw.EdgeInsets.only(left: 14 * scale, top: 1 * scale),
            child: pw.Text(item.qtyLine, style: _labelStyle(scale, size: 7)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _grandTotalRow(double total, double scale, pw.Font bold) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GRAND TOTAL', style: _boldStyle(scale, size: 11, font: bold)),
          pw.Text(
            formatInr(total),
            style: _boldStyle(scale, size: 12, font: bold),
          ),
        ],
      );

  static pw.Widget _moneyRow(
    String label,
    double amount,
    double scale,
    pw.Font bold,
  ) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 2 * scale),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(label, style: _body(scale, size: 8.5, bold: bold)),
            ),
            pw.Text(
              formatInr(amount),
              style: _boldStyle(scale, size: 8.5, font: bold),
            ),
          ],
        ),
      );

  static pw.Widget _labelValue(
    String label,
    String value,
    double scale,
    pw.Font bold,
  ) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 1.5 * scale),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 54 * scale,
              child: pw.Text('$label:', style: _labelStyle(scale)),
            ),
            pw.Expanded(
              child: pw.Text(value, style: _body(scale, bold: bold)),
            ),
          ],
        ),
      );

  static pw.Widget _sectionTitle(String t, double scale, pw.Font bold) =>
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 3 * scale, top: 1 * scale),
        child: pw.Text(t, style: _boldStyle(scale, size: 9, font: bold)),
      );

  static pw.Widget _divider({bool dashed = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(
                color: PdfColors.grey800,
                width: dashed ? 0.4 : 0.6,
                style: dashed ? pw.BorderStyle.dashed : pw.BorderStyle.solid,
              ),
            ),
          ),
        ),
      );

  static pw.TextStyle _body(
    double scale, {
    double size = 8.5,
    pw.Font? bold,
  }) =>
      pw.TextStyle(
        font: bold,
        fontSize: size * scale,
        color: _ink,
      );

  static pw.TextStyle _boldStyle(
    double scale, {
    double size = 8.5,
    required pw.Font font,
  }) =>
      pw.TextStyle(
        font: font,
        fontSize: size * scale,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      );

  static pw.TextStyle _labelStyle(double scale, {double size = 8}) =>
      pw.TextStyle(
        fontSize: size * scale,
        color: _label,
      );
}
