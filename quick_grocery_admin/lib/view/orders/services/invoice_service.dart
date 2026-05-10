import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:quick_grocery_admin/model/order_model.dart';
import 'package:quick_grocery_admin/model/customer_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class InvoiceService {
  // Helper function to format currency
  static String formatCurrency(double amount) {
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  static Future<void> printInvoice({
    required OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
    required BuildContext context,
  }) async {
    try {
      final pdf = await _generateInvoicePDF(order, customer, vendor);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invoice: $e'),
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
      final pdf = await _generateInvoicePDF(order, customer, vendor);
      
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'invoice_${order.id}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<pw.Document> _generateInvoicePDF(
    OrderModel order,
    CustomerModel? customer,
    VendorModel? vendor,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final orderDate = DateTime.parse(order.createdDate);

    // Calculate totals
    double subtotal = order.getSubtotal();
    double deliveryCharge = order.deliveryCharge.toDouble();
    double totalAmount = order.getTotalAmount();
    double totalDiscount = 0.0;
    for (var product in order.products) {
      totalDiscount +=
          (product.slashedPrice - product.price) * product.itemCount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(),
            pw.SizedBox(height: 20),

            // Invoice Details
            _buildInvoiceDetails(order, dateFormat.format(orderDate)),
            pw.SizedBox(height: 20),

            // Billing and Shipping Address
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Billing Address
                pw.Expanded(
                  child: _buildAddressSection(
                    'Bill To',
                    customer?.name ?? order.customerName,
                    order.phone,
                    order.address,
                  ),
                ),
                pw.SizedBox(width: 20),
                // Shipping Address
                pw.Expanded(
                  child: _buildAddressSection(
                    'Ship To',
                    customer?.name ?? order.customerName,
                    order.phone,
                    order.address,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Vendor Information
            if (vendor != null) ...[
              _buildVendorSection(vendor),
              pw.SizedBox(height: 20),
            ],

            // Items Table
            _buildItemsTable(order.products),
            pw.SizedBox(height: 20),

            // Summary
            _buildSummary(
              subtotal,
              totalDiscount,
              deliveryCharge,
              totalAmount,
            ),
            pw.SizedBox(height: 30),

            // Footer
            _buildFooter(order),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Quick Grocery',
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue900, width: 2),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            'TAX INVOICE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(OrderModel order, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order.id),
              pw.SizedBox(height: 5),
              _buildDetailRow('Order Date', date),
              pw.SizedBox(height: 5),
              _buildDetailRow('Payment Status', order.isPaid ? 'Paid' : 'Unpaid'),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order Status', order.orderStatus),
              pw.SizedBox(height: 5),
              _buildDetailRow('Delivery Type', order.deliveryType),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAddressSection(
    String title,
    String name,
    String phone,
    String address,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            phone,
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            address,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildVendorSection(VendorModel vendor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vendor Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            vendor.shopName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            vendor.phone,
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            vendor.shopAddress,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<ProductItem> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Discount', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data Rows
        ...products.map((product) {
          final itemTotal = product.price * product.itemCount;
          final discount =
              (product.slashedPrice - product.price) * product.itemCount;
          return pw.TableRow(
            children: [
              _buildTableCell(product.name),
              _buildTableCell('${product.itemCount}'),
              _buildTableCell(formatCurrency(product.price)),
              _buildTableCell(formatCurrency(discount)),
              _buildTableCell(formatCurrency(itemTotal)),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildSummary(
    double subtotal,
    double discount,
    double deliveryCharge,
    double total,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildSummaryRow('Subtotal', subtotal),
            pw.SizedBox(height: 5),
            if (discount > 0) ...[
              _buildSummaryRow('Discount', -discount, isDiscount: true),
              pw.SizedBox(height: 5),
            ],
            _buildSummaryRow('Delivery Charge', deliveryCharge),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildSummaryRow('Total Amount', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(width: 150),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 11,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Text(
          formatCurrency(amount),
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 11,
            fontWeight: pw.FontWeight.bold,
            color: isDiscount ? PdfColors.green : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Thank you for your order!',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'For any queries, please contact us at support@quickgrocery.com',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'This is a computer-generated invoice and does not require a signature.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}

