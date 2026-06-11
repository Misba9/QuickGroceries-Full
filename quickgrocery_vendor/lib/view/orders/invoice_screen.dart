import 'package:flutter/material.dart';
import 'package:quickgrocery_vendor/constants/vendor_branding.dart';
import 'package:quick_grocery_receipt/quick_grocery_receipt.dart';

import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../services/invoice_service.dart';
import '../../services/thermal_receipt_pdf.dart';
import '../../style/app_color.dart';

/// Thermal receipt preview + print/share (unified Quick Groceries template).
class InvoiceScreen extends StatefulWidget {
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
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  ReceiptOrderData? _receiptData;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    final data = await ThermalReceiptPdf.receiptData(
      widget.order,
      widget.vendor,
      mode: widget.mode,
    );
    if (mounted) setState(() => _receiptData = data);
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.mode == ReceiptMode.packingSlip ? 'Packing slip' : 'Invoice';

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
      body: _receiptData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InvoiceTemplateWidget(
                    data: _receiptData!,
                    logo: Image.asset(
                      'packages/quick_grocery_receipt/assets/images/qg_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        VendorBranding.logoAsset,
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront_rounded,
                          size: 44,
                          color: Colors.black,
                        ),
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
      await InvoiceService().printInvoice(
        widget.order,
        widget.vendor,
        mode: widget.mode,
      );
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
      await InvoiceService().shareInvoice(
        widget.order,
        widget.vendor,
        mode: widget.mode,
      );
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
