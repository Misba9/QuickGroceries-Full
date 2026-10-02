import 'package:flutter/material.dart';

import 'receipt_models.dart';
import 'receipt_options.dart';
import 'thermal_receipt_pdf_builder.dart';

/// On-screen thermal receipt preview — matches PDF output layout.
class InvoiceTemplateWidget extends StatelessWidget {
  const InvoiceTemplateWidget({
    super.key,
    required this.data,
    this.logo,
    this.maxWidth,
  });

  final ReceiptOrderData data;
  final Widget? logo;
  final double? maxWidth;

  static const Color _ink = Color(0xFF000000);
  static const Color _labelColor = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? _logicalWidth(data.paperSize);
    final scale = _fontScale(data.paperSize);
    final dateTimeStr = ThermalReceiptPdfBuilder.formatDateTime(data.createdAt);

    return Center(
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 14 * scale),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontSize: 11 * scale,
            color: _ink,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _brandHeader(scale),
              _rule(),
              _kv('Invoice', data.invoiceNumber, scale),
              _kv('Date & Time', dateTimeStr, scale),
              _kv('Payment', data.paymentMethod, scale),
              _rule(),
              _section('CUSTOMER', scale),
              _kv('Name', data.customerName, scale),
              _kv(
                'Phone',
                data.phone.trim().isNotEmpty ? data.phone : '—',
                scale,
              ),
              Text('Address:', style: _labelStyle(scale)),
              Text(data.address, style: _body(scale)),
              _rule(),
              _section('DELIVERY', scale),
              if (data.deliverySlotLabel != null &&
                  data.deliverySlotLabel!.isNotEmpty)
                _kv('Slot', data.deliverySlotLabel!, scale),
              if (data.typeAndStoreLine != null)
                _kv('Type & Store', data.typeAndStoreLine!, scale),
              if (data.instructionLines.isNotEmpty) ...[
                Text('Instructions:', style: _labelStyle(scale)),
                ...data.instructionLines.map((l) => Text(l, style: _body(scale))),
              ],
              _rule(),
              Row(
                children: [
                  SizedBox(width: 22, child: Text('NO', style: _bold(scale, 8.5))),
                  Expanded(child: Text('PRODUCT', style: _bold(scale, 8.5))),
                  if (data.showPrices)
                    Text('AMOUNT', style: _bold(scale, 8.5)),
                ],
              ),
              SizedBox(height: 4 * scale),
              ...data.items.asMap().entries.map((e) {
                final i = e.key + 1;
                final item = e.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 22, child: Text('$i', style: _body(scale, 9))),
                          Expanded(
                            child: Text(
                              item.name,
                              style: _bold(scale, 9.5),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data.showPrices)
                            Text(
                              ThermalReceiptPdfBuilder.formatInr(item.lineTotal),
                              style: _bold(scale, 9.5),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 22, top: 2),
                        child: Text(item.qtyLine, style: _labelStyle(scale, 8)),
                      ),
                    ],
                  ),
                );
              }),
              _rule(),
              Text('Items: ${data.items.length}', style: _bold(scale, 9.5)),
              if (data.showPrices) ...[
                _rule(),
                _section('TOTALS', scale),
                ..._totalLines(scale),
                _rule(),
                Row(
                  children: [
                    Expanded(
                      child: Text('GRAND TOTAL', style: _bold(scale, 12)),
                    ),
                    Text(
                      ThermalReceiptPdfBuilder.formatInr(data.bill.grandTotal),
                      style: _bold(scale, 13),
                    ),
                  ],
                ),
              ],
              _rule(),
              Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 76 * scale,
                  color: _ink,
                ),
              ),
              _center('Scan to track order', label: true, size: 10 * scale),
              _center(data.trackingUrl, size: 9 * scale),
              _rule(),
              _center('Thank You!', bold: true, size: 13 * scale),
              _center(
                data.isPackingSlip ? 'Pack with care' : 'Visit again',
                label: true,
              ),
              _center(ThermalReceiptPdfBuilder.supportEmail, label: true, size: 9),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader(double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (logo != null)
          SizedBox(
            width: 44 * scale,
            height: 44 * scale,
            child: logo,
          ),
        if (logo != null) SizedBox(width: 10 * scale),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ThermalReceiptPdfBuilder.brandTitle,
                style: _bold(scale, 14),
              ),
              SizedBox(height: 2 * scale),
              Text(
                ThermalReceiptPdfBuilder.brandSubtitle,
                style: _labelStyle(scale, 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _totalLines(double scale) {
    final b = data.bill;
    return [
      _money('MRP Total', b.mrpTotal, scale),
      if (b.itemSavings > 0)
        _money('Product Discount', -b.itemSavings, scale),
      _money('Item Total', b.subtotal, scale),
      if (b.couponDiscount > 0)
        _money(
          data.couponCode != null && data.couponCode!.isNotEmpty
              ? 'Coupon (${data.couponCode})'
              : 'Coupon Discount',
          -b.couponDiscount,
          scale,
        ),
      _money('Delivery Fee', b.deliveryFee, scale),
      if (b.platformFee > 0) _money('Platform Fee', b.platformFee, scale),
      if (b.surgeFee > 0) _money('Surge Fee', b.surgeFee, scale),
      if (b.handlingCharge > 0)
        _money('Handling Charge', b.handlingCharge, scale),
      if (b.tax > 0) _money('Tax', b.tax, scale),
      if (b.codConvenienceFee > 0)
        _money(
          b.codFeeDescription.isNotEmpty
              ? b.codFeeDescription
              : 'COD Convenience Fee',
          b.codConvenienceFee,
          scale,
        ),
      if (b.deliveryPartnerTip > 0)
        _money('Delivery Partner Tip', b.deliveryPartnerTip, scale),
    ];
  }

  static double _logicalWidth(ReceiptPaperSize size) => switch (size) {
        ReceiptPaperSize.mm58 => 220,
        ReceiptPaperSize.mm80 => 302,
        ReceiptPaperSize.a4 => 520,
      };

  static double _fontScale(ReceiptPaperSize size) => switch (size) {
        ReceiptPaperSize.mm58 => 0.9,
        ReceiptPaperSize.mm80 => 1.0,
        ReceiptPaperSize.a4 => 1.1,
      };

  Widget _rule() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Container(height: 1, color: Colors.grey.shade700),
      );

  Widget _section(String t, double scale) => Padding(
        padding: EdgeInsets.only(bottom: 4 * scale),
        child: Text(t, style: _bold(scale, 9.5)),
      );

  Widget _kv(String k, String v, double scale) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 58, child: Text('$k:', style: _labelStyle(scale))),
            Expanded(child: Text(v, style: _body(scale))),
          ],
        ),
      );

  Widget _money(String label, double amount, double scale) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: _body(scale, 10))),
            Text(
              ThermalReceiptPdfBuilder.formatInr(amount),
              style: _bold(scale, 10),
            ),
          ],
        ),
      );

  Widget _center(
    String t, {
    bool bold = false,
    bool label = false,
    double size = 11,
  }) =>
      Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: label ? _labelColor : _ink,
          fontSize: size,
        ),
      );

  TextStyle _body(double scale, [double size = 10.5]) =>
      TextStyle(fontSize: size * scale, color: _ink, fontWeight: FontWeight.w500);

  TextStyle _bold(double scale, double size) =>
      TextStyle(fontSize: size * scale, fontWeight: FontWeight.w700, color: _ink);

  TextStyle _labelStyle(double scale, [double size = 9.5]) =>
      TextStyle(fontSize: size * scale, color: _labelColor, fontWeight: FontWeight.w500);
}
