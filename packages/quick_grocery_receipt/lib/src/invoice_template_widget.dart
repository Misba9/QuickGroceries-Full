import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final width = maxWidth ?? _logicalWidth(data.paperSize);
    final scale = _fontScale(data.paperSize);
    final date = data.createdAt;
    final dateStr =
        date != null ? DateFormat('dd MMM yyyy').format(date) : '—';
    final timeStr =
        date != null ? DateFormat('hh:mm a').format(date) : '—';

    return Center(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11 * scale,
            color: Colors.black87,
            height: 1.35,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logo != null) Center(child: logo),
              if (logo != null) SizedBox(height: 6 * scale),
              _center(ThermalReceiptPdfBuilder.brandTitle, bold: true, size: 13 * scale),
              _center(
                ThermalReceiptPdfBuilder.brandSubtitle,
                muted: true,
                size: 10 * scale,
              ),
              _rule(),
              _kv('Invoice', data.invoiceNumber, scale),
              _kv('Date', dateStr, scale),
              _kv('Time', timeStr, scale),
              _kv('Payment', data.paymentMethod, scale),
              _kv('Status', data.statusLabel, scale),
              _rule(),
              _section('CUSTOMER', scale),
              _kv('Name', data.customerName, scale),
              _kv('Phone', data.phone, scale),
              Text('Address:', style: _muted(scale)),
              Text(data.address, style: _body(scale)),
              _rule(),
              _section('DELIVERY', scale),
              if (data.deliverySlotLabel != null &&
                  data.deliverySlotLabel!.isNotEmpty)
                _kv('Slot', data.deliverySlotLabel!, scale),
              if (data.deliveryTypeLabel != null &&
                  data.deliveryTypeLabel!.isNotEmpty)
                _kv('Type', data.deliveryTypeLabel!, scale),
              if (data.instructionLines.isNotEmpty) ...[
                Text('Instructions:', style: _muted(scale)),
                ...data.instructionLines.map((l) => Text(l, style: _body(scale))),
              ],
              _rule(),
              Row(
                children: [
                  SizedBox(width: 20, child: Text('NO', style: _bold(scale, 8))),
                  Expanded(child: Text('PRODUCT', style: _bold(scale, 8))),
                  if (data.showPrices)
                    Text('AMOUNT', style: _bold(scale, 8)),
                ],
              ),
              const SizedBox(height: 4),
              ...data.items.asMap().entries.map((e) {
                final i = e.key + 1;
                final item = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 20, child: Text('$i')),
                          Expanded(
                            child: Text(
                              item.name,
                              style: _bold(scale, 9),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data.showPrices)
                            Text(
                              ThermalReceiptPdfBuilder.formatInr(item.lineTotal),
                              style: _bold(scale, 9),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 2),
                        child: Text(item.qtyLine, style: _muted(scale, 8)),
                      ),
                    ],
                  ),
                );
              }),
              _rule(),
              Text('Items: ${data.items.length}', style: _bold(scale, 9)),
              if (data.showPrices) ...[
                _rule(),
                _section('TOTALS', scale),
                _money('Subtotal', data.bill.subtotal, scale),
                if (data.bill.couponDiscount > 0)
                  _money(
                    data.couponCode != null && data.couponCode!.isNotEmpty
                        ? 'Coupon (${data.couponCode})'
                        : 'Coupon discount',
                    -data.bill.couponDiscount,
                    scale,
                  ),
                _money('Delivery Fee', data.bill.deliveryFee, scale),
                if (data.bill.platformFee > 0)
                  _money('Platform Fee', data.bill.platformFee, scale),
                if (data.bill.tax > 0) _money('Tax', data.bill.tax, scale),
                _rule(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GRAND TOTAL',
                        style: _bold(scale, 11),
                      ),
                    ),
                    Text(
                      ThermalReceiptPdfBuilder.formatInr(data.bill.grandTotal),
                      style: _bold(scale, 12),
                    ),
                  ],
                ),
              ],
              _rule(),
              _section('PAYMENT', scale),
              _kv('Payment', data.paymentMethod, scale),
              _kv('Status', data.statusLabel, scale),
              _kv('ETA', data.etaLabel, scale),
              _rule(),
              Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 72 * scale,
                  color: Colors.black87,
                ),
              ),
              _center('Scan to track order', muted: true, size: 10 * scale),
              _center(data.trackingUrl, size: 9 * scale),
              _rule(),
              _center('Thank You!', bold: true, size: 12 * scale),
              _center(
                data.isPackingSlip ? 'Pack with care' : 'Visit again',
                muted: true,
              ),
              _center(ThermalReceiptPdfBuilder.supportEmail, muted: true, size: 9),
            ],
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(height: 1, color: Colors.grey.shade400),
      );

  Widget _section(String t, double scale) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t, style: _bold(scale, 9)),
      );

  Widget _kv(String k, String v, double scale) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 56, child: Text('$k:', style: _muted(scale))),
            Expanded(child: Text(v, style: _body(scale))),
          ],
        ),
      );

  Widget _money(String label, double amount, double scale) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: _body(scale))),
            Text(
              ThermalReceiptPdfBuilder.formatInr(amount),
              style: _body(scale),
            ),
          ],
        ),
      );

  Widget _center(
    String t, {
    bool bold = false,
    bool muted = false,
    double size = 11,
  }) =>
      Text(
        t,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: muted ? Colors.grey.shade700 : Colors.black87,
          fontSize: size,
        ),
      );

  TextStyle _body(double scale, [double size = 10]) =>
      TextStyle(fontSize: size * scale);

  TextStyle _bold(double scale, double size) =>
      TextStyle(fontSize: size * scale, fontWeight: FontWeight.w700);

  TextStyle _muted(double scale, [double size = 9.5]) =>
      TextStyle(fontSize: size * scale, color: Colors.grey.shade700);
}
