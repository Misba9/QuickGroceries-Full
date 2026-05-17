import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/view/orders/services/thermal_receipt_pdf_builder.dart';
import 'package:quick_grocery_admin/view/orders/utils/order_contact_actions.dart';

/// Thermal receipt print / share (80mm Blinkit-style bill).
class InvoiceService {
  InvoiceService._();

  static String formatCurrency(double amount) =>
      '₹${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)}';

  static Future<pw.Document> _buildReceipt(
    OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
  ) =>
      ThermalReceiptPdfBuilder.build(
        order: order,
        customer: customer,
        vendor: vendor,
      );

  static Future<void> printInvoice({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    required BuildContext context,
  }) async {
    try {
      final pdf = await _buildReceipt(order, customer, vendor);
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        format: ThermalReceiptPdfBuilder.pageFormat,
        name: 'receipt_${order.id}',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not print receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> shareInvoice({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    required BuildContext context,
  }) async {
    try {
      final pdf = await _buildReceipt(order, customer, vendor);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'receipt_${order.id}.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share receipt: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Share receipt PDF via WhatsApp (opens chat with customer when possible).
  static Future<void> shareReceiptWhatsApp({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    required BuildContext context,
  }) async {
    try {
      final pdf = await _buildReceipt(order, customer, vendor);
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'QuickGrocery_${order.id}.pdf',
      );
      if (!context.mounted) return;
      await OrderContactActions.whatsAppCustomer(
        context,
        order.phone,
        message:
            'Your Quick Grocery receipt for order #${order.id} — total ${formatCurrency(order.getTotalAmount())}.',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }
}
