import 'package:flutter/material.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../services/invoice_service.dart';
import '../../style/app_color.dart';
import '../../utils/receipt_order_mapper.dart';

/// Thermal receipt preview + print/share (unified Quick Groceries template).
class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({
    super.key,
    required this.order,
    required this.vendor,
    this.mode = ReceiptMode.invoice,
  });

  final OrderModel order;
  final VendorModel vendor;
  final ReceiptMode mode;

  @override
  Widget build(BuildContext context) {
    final receiptData = ReceiptOrderMapper.fromOrder(
      order,
      vendorId: vendor.id,
      mode: mode,
      storeName: vendor.shopName,
    );
    final title = mode == ReceiptMode.packingSlip ? 'Packing slip' : 'Invoice';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () => _print(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InvoiceTemplateWidget(
              data: receiptData,
              logo: Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 40,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront_rounded,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _print(context),
                  icon: const Icon(Icons.print),
                  label: const Text('Print (80mm)'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share),
                  label: const Text('Download PDF'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context) async {
    try {
      await InvoiceService().printInvoice(order, vendor, mode: mode);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Print failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _share(BuildContext context) async {
    try {
      await InvoiceService().shareInvoice(order, vendor, mode: mode);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF ready to share'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
