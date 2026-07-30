import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

/// Vendor calls `vendorRequestPromotionCallable` to ask admin for a promo.
class VendorPromotionRequestService {
  VendorPromotionRequestService({FirebaseFunctions? functions})
      : _fn = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _fn;

  static const promotionTypes = <String>[
    'flash_sale',
    'todays_deal',
    'featured',
    'best_seller',
    'recommended',
    'trending',
    'new_arrival',
    'limited_time',
    'discount_badge',
    'bogo',
    'combo_offer',
  ];

  static String labelFor(String type) {
    return switch (type) {
      'flash_sale' => 'Flash Sale',
      'todays_deal' => "Today's Deal",
      'featured' => 'Featured',
      'best_seller' => 'Best Seller',
      'recommended' => 'Recommended',
      'trending' => 'Trending',
      'new_arrival' => 'New Arrival',
      'limited_time' => 'Limited Time Offer',
      'discount_badge' => 'Discount Badge',
      'bogo' => 'Buy One Get One',
      'combo_offer' => 'Combo Offer',
      _ => type,
    };
  }

  Future<void> request({
    required String productId,
    required String vendorId,
    required String promotionType,
    double? salePrice,
    double? discountPercent,
    DateTime? startDate,
    DateTime? endDate,
    String reason = '',
    String badge = '',
  }) async {
    await _fn.httpsCallable('vendorRequestPromotionCallable').call({
      'productId': productId,
      'vendorId': vendorId,
      'promotionType': promotionType,
      if (salePrice != null) 'salePrice': salePrice,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (badge.trim().isNotEmpty) 'badge': badge.trim(),
    });
  }
}

Future<bool?> showVendorPromotionRequestDialog({
  required BuildContext context,
  required String productId,
  required String vendorId,
  required String productName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _VendorPromoRequestDialog(
      productId: productId,
      vendorId: vendorId,
      productName: productName,
    ),
  );
}

class _VendorPromoRequestDialog extends StatefulWidget {
  const _VendorPromoRequestDialog({
    required this.productId,
    required this.vendorId,
    required this.productName,
  });

  final String productId;
  final String vendorId;
  final String productName;

  @override
  State<_VendorPromoRequestDialog> createState() =>
      _VendorPromoRequestDialogState();
}

class _VendorPromoRequestDialogState extends State<_VendorPromoRequestDialog> {
  final _svc = VendorPromotionRequestService();
  final _reason = TextEditingController();
  final _sale = TextEditingController();
  final _badge = TextEditingController();
  String _type = 'flash_sale';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    _sale.dispose();
    _badge.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sale = double.tryParse(_sale.text.trim());
      await _svc.request(
        productId: widget.productId,
        vendorId: widget.vendorId,
        promotionType: _type,
        salePrice: sale,
        reason: _reason.text.trim(),
        badge: _badge.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _error = e.message ?? e.code;
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request promotion'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.productName,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Promotion type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final t in VendorPromotionRequestService.promotionTypes)
                    DropdownMenuItem(
                      value: t,
                      child: Text(VendorPromotionRequestService.labelFor(t)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sale,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Proposed sale price (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _badge,
                decoration: const InputDecoration(
                  labelText: 'Badge text (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'HOT / NEW / LIMITED',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason for request',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit request'),
        ),
      ],
    );
  }
}
