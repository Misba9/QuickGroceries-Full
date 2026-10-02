import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/product_promotions/models/product_promotion_model.dart';
import 'package:quick_grocery_admin/view/product_promotions/services/product_promotions_admin_service.dart';

/// Full admin editor for a product's promotional settings.
class ProductPromotionEditorSheet extends StatefulWidget {
  const ProductPromotionEditorSheet({
    super.key,
    required this.product,
    required this.service,
    this.existing = const [],
  });

  final ProductModel product;
  final ProductPromotionsAdminService service;
  final List<ProductPromotionModel> existing;

  static Future<bool?> show(
    BuildContext context, {
    required ProductModel product,
    required ProductPromotionsAdminService service,
    List<ProductPromotionModel> existing = const [],
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProductPromotionEditorSheet(
        product: product,
        service: service,
        existing: existing,
      ),
    );
  }

  @override
  State<ProductPromotionEditorSheet> createState() =>
      _ProductPromotionEditorSheetState();
}

class _ProductPromotionEditorSheetState
    extends State<ProductPromotionEditorSheet> {
  late final Map<String, bool> _flags;
  late final TextEditingController _salePrice;
  late final TextEditingController _discountPercent;
  late final TextEditingController _stockLimit;
  late final TextEditingController _maxPurchase;
  late final TextEditingController _badge;
  late final TextEditingController _bannerLabel;
  late final TextEditingController _reason;

  DateTime? _flashStart;
  DateTime? _flashEnd;
  DateTime? _offerExpiry;
  bool _visible = true;
  bool _pinToTop = false;
  bool _locked = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _flags = {
      for (final t in PromotionTypes.all) t: false,
    };
    for (final p in widget.existing) {
      if (p.source == 'admin' && p.enabled && !p.expired) {
        _flags[p.promotionType] = true;
      }
    }

    final flash = _firstOf(PromotionTypes.flashSale);
    final any = widget.existing.where((p) => p.source == 'admin').toList();

    _salePrice = TextEditingController(
      text: (flash?.salePrice ?? _firstPrice(any))?.toString() ??
          (double.tryParse(widget.product.slashedPrice)?.toString() ?? ''),
    );
    _discountPercent = TextEditingController(
      text: (flash?.discountPercent ?? _firstDiscount(any))?.toString() ?? '',
    );
    _stockLimit = TextEditingController(
      text: (flash?.stockLimit ?? 0) > 0 ? '${flash!.stockLimit}' : '',
    );
    _maxPurchase = TextEditingController(
      text: (flash?.maxPurchase ?? 0) > 0 ? '${flash!.maxPurchase}' : '',
    );
    _badge = TextEditingController(text: flash?.badge ?? _firstBadge(any) ?? '');
    _bannerLabel = TextEditingController(
      text: flash?.bannerLabel ?? _firstBanner(any) ?? '',
    );
    _reason = TextEditingController();

    _flashStart = flash?.startDate;
    _flashEnd = flash?.endDate;
    _offerExpiry = _firstOf(PromotionTypes.limitedTime)?.endDate ??
        flash?.endDate;
    _pinToTop = any.any((p) => p.pinToTop);
    _locked = any.isEmpty || any.any((p) => p.locked);
    _visible = widget.product.isActive;
  }

  ProductPromotionModel? _firstOf(String type) {
    for (final p in widget.existing) {
      if (p.promotionType == type && p.source == 'admin') return p;
    }
    return null;
  }

  double? _firstPrice(List<ProductPromotionModel> list) {
    for (final p in list) {
      if (p.salePrice != null && p.salePrice! > 0) return p.salePrice;
    }
    return null;
  }

  double? _firstDiscount(List<ProductPromotionModel> list) {
    for (final p in list) {
      if (p.discountPercent != null && p.discountPercent! > 0) {
        return p.discountPercent;
      }
    }
    return null;
  }

  String? _firstBadge(List<ProductPromotionModel> list) {
    for (final p in list) {
      if (p.badge.isNotEmpty) return p.badge;
    }
    return null;
  }

  String? _firstBanner(List<ProductPromotionModel> list) {
    for (final p in list) {
      if (p.bannerLabel.isNotEmpty) return p.bannerLabel;
    }
    return null;
  }

  @override
  void dispose() {
    _salePrice.dispose();
    _discountPercent.dispose();
    _stockLimit.dispose();
    _maxPurchase.dispose();
    _badge.dispose();
    _bannerLabel.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current ?? now),
    );
    if (time == null || !mounted) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.service.patchProductPromotions(
        productId: widget.product.id,
        flags: Map<String, bool>.from(_flags),
        salePrice: double.tryParse(_salePrice.text.trim()),
        discountPercent: double.tryParse(_discountPercent.text.trim()),
        flashSaleStart: _flashStart,
        flashSaleEnd: _flashEnd,
        offerExpiry: _offerExpiry,
        stockLimit: int.tryParse(_stockLimit.text.trim()),
        maxPurchase: int.tryParse(_maxPurchase.text.trim()),
        visible: _visible,
        pinToTop: _pinToTop,
        bannerLabel: _bannerLabel.text.trim(),
        badge: _badge.text.trim(),
        locked: _locked,
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Product Promotions',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.product.name,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Promotion flags',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.h8,
                    ...PromotionTypes.all.map((type) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(PromotionTypes.label(type)),
                        value: _flags[type] == true,
                        activeThumbColor: AppColor.primary,
                        onChanged: (v) => setState(() => _flags[type] = v),
                      );
                    }),
                    const Divider(height: 28),
                    const Text(
                      'Pricing & limits',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.h10,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _salePrice,
                            decoration: const InputDecoration(
                              labelText: 'Sale price',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.w10,
                        Expanded(
                          child: TextField(
                            controller: _discountPercent,
                            decoration: const InputDecoration(
                              labelText: 'Discount %',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.h10,
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _stockLimit,
                            decoration: const InputDecoration(
                              labelText: 'Offer stock limit',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        AppSpacing.w10,
                        Expanded(
                          child: TextField(
                            controller: _maxPurchase,
                            decoration: const InputDecoration(
                              labelText: 'Max qty / customer',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Schedule',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.h8,
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Flash sale start'),
                      subtitle: Text(
                        _flashStart?.toLocal().toString().substring(0, 16) ??
                            'Not set',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () => _pickDateTime(
                          current: _flashStart,
                          onPicked: (d) => setState(() => _flashStart = d),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Flash sale end'),
                      subtitle: Text(
                        _flashEnd?.toLocal().toString().substring(0, 16) ??
                            'Not set',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () => _pickDateTime(
                          current: _flashEnd,
                          onPicked: (d) => setState(() => _flashEnd = d),
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Offer expiry'),
                      subtitle: Text(
                        _offerExpiry?.toLocal().toString().substring(0, 16) ??
                            'Not set',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.event),
                        onPressed: () => _pickDateTime(
                          current: _offerExpiry,
                          onPicked: (d) => setState(() => _offerExpiry = d),
                        ),
                      ),
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Badges & placement',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AppSpacing.h10,
                    TextField(
                      controller: _badge,
                      decoration: const InputDecoration(
                        labelText: 'Custom badge (HOT, NEW, LIMITED…)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.h10,
                    TextField(
                      controller: _bannerLabel,
                      decoration: const InputDecoration(
                        labelText: 'Promotional banner label',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Product visibility'),
                      subtitle: const Text('Hide from catalog when off'),
                      value: _visible,
                      activeThumbColor: AppColor.primary,
                      onChanged: (v) => setState(() => _visible = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pin to top of category'),
                      value: _pinToTop,
                      activeThumbColor: AppColor.primary,
                      onChanged: (v) => setState(() => _pinToTop = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Lock vendor editing'),
                      subtitle: const Text(
                        'Vendor cannot override these promotions',
                      ),
                      value: _locked,
                      activeThumbColor: AppColor.primary,
                      onChanged: (v) => setState(() => _locked = v),
                    ),
                    AppSpacing.h10,
                    TextField(
                      controller: _reason,
                      decoration: const InputDecoration(
                        labelText: 'Reason (audit log)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    AppSpacing.h20,
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.black87,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save promotions'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
