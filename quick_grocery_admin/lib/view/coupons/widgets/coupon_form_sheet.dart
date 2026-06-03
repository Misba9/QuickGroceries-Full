import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/coupons/models/admin_coupon_model.dart';
import 'package:quick_grocery_admin/view/coupons/models/coupon_type.dart';
import 'package:quick_grocery_admin/view/coupons/services/coupon_admin_service.dart';

class CouponFormSheet extends StatefulWidget {
  const CouponFormSheet({
    super.key,
    this.existing,
    required this.service,
  });

  final AdminCouponModel? existing;
  final CouponAdminService service;

  static Future<AdminCouponModel?> show(
    BuildContext context, {
    AdminCouponModel? existing,
    required CouponAdminService service,
  }) {
    return showModalBottomSheet<AdminCouponModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CouponFormSheet(existing: existing, service: service),
    );
  }

  @override
  State<CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends State<CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _discount;
  late final TextEditingController _flat;
  late final TextEditingController _minOrder;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _usageLimit;
  late final TextEditingController _perUser;
  late final TextEditingController _description;

  late CouponType _type;
  late DateTime? _start;
  late DateTime? _expiry;
  late bool _freeDelivery;
  late bool _firstOrderOnly;
  late bool _onePerDevice;
  late bool _isActive;

  List<String> _vendorIds = [];
  List<String> _productIds = [];
  List<String> _categoryIds = [];

  List<MapEntry<String, String>> _vendors = [];
  List<MapEntry<String, String>> _products = [];
  List<MapEntry<String, String>> _categories = [];
  bool _loadingOptions = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _code = TextEditingController(text: e?.code ?? '');
    _title = TextEditingController(text: e?.title ?? '');
    _discount = TextEditingController(text: '${e?.discountPercent ?? 0}');
    _flat = TextEditingController(text: '${e?.flatAmount ?? 0}');
    _minOrder = TextEditingController(text: '${e?.minimumOrderAmount ?? 0}');
    _maxDiscount = TextEditingController(text: '${e?.maximumDiscountAmount ?? 0}');
    _usageLimit = TextEditingController(text: '${e?.usageLimit ?? 0}');
    _perUser = TextEditingController(text: '${e?.perUserLimit ?? 1}');
    _description = TextEditingController(text: e?.description ?? '');
    _type = e?.couponType ?? CouponType.percentageDiscount;
    _start = e?.startDate;
    _expiry = e?.expiryDate;
    _freeDelivery = e?.freeDelivery ?? false;
    _firstOrderOnly = e?.firstOrderOnly ?? false;
    _onePerDevice = e?.onePerDevice ?? true;
    _isActive = e?.isActive ?? true;
    _vendorIds = List.from(e?.applicableVendorIds ?? []);
    _productIds = List.from(e?.applicableProductIds ?? []);
    _categoryIds = List.from(e?.applicableCategoryIds ?? []);
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final v = await widget.service.fetchVendorOptions();
    final p = await widget.service.fetchProductOptions();
    final c = await widget.service.fetchCategoryOptions();
    if (mounted) {
      setState(() {
        _vendors = v;
        _products = p;
        _categories = c;
        _loadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _discount.dispose();
    _flat.dispose();
    _minOrder.dispose();
    _maxDiscount.dispose();
    _usageLimit.dispose();
    _perUser.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _start : _expiry;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _expiry = picked;
      }
    });
  }

  AdminCouponModel _buildModel() {
    return AdminCouponModel(
      id: widget.existing?.id ?? '',
      code: _code.text.trim().toUpperCase(),
      title: _title.text.trim(),
      couponType: _type,
      discountPercent: int.tryParse(_discount.text) ?? 0,
      flatAmount: int.tryParse(_flat.text) ?? 0,
      minimumOrderAmount: int.tryParse(_minOrder.text) ?? 0,
      maximumDiscountAmount: int.tryParse(_maxDiscount.text) ?? 0,
      startDate: _start,
      expiryDate: _expiry,
      usageLimit: int.tryParse(_usageLimit.text) ?? 0,
      usedCount: widget.existing?.usedCount ?? 0,
      perUserLimit: int.tryParse(_perUser.text) ?? 1,
      applicableVendorIds: _vendorIds,
      applicableProductIds: _productIds,
      applicableCategoryIds: _categoryIds,
      freeDelivery: _freeDelivery || _type.isFreeDelivery,
      firstOrderOnly: _firstOrderOnly || _type.isFirstOrder,
      onePerDevice: _onePerDevice,
      isActive: _isActive,
      description: _description.text.trim(),
      analyticsTotalUsage: widget.existing?.analyticsTotalUsage ?? 0,
      analyticsFailedAttempts: widget.existing?.analyticsFailedAttempts ?? 0,
      analyticsRevenue: widget.existing?.analyticsRevenue ?? 0,
      analyticsFirstOrderUsers: widget.existing?.analyticsFirstOrderUsers ?? 0,
      createdAt: widget.existing?.createdAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scroll,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.existing == null ? 'Create coupon' : 'Edit coupon',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _code,
                  decoration: const InputDecoration(
                    labelText: 'Coupon code *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title (shown in app)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CouponType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Coupon type',
                    border: OutlineInputBorder(),
                  ),
                  items: CouponType.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _type = v;
                      if (v.isFirstOrder) _firstOrderOnly = true;
                      if (v.isFreeDelivery) _freeDelivery = true;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_type.isPercentage || _type.isFirstOrder)
                  TextFormField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount %',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_type.isFlat) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _flat,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Flat amount (₹)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minOrder,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimum order amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxDiscount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maximum discount cap (₹, 0 = none)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(true),
                        child: Text(
                          _start == null
                              ? 'Start date'
                              : 'Start: ${_start!.toString().split(' ').first}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(false),
                        child: Text(
                          _expiry == null
                              ? 'Expiry date'
                              : 'Ends: ${_expiry!.toString().split(' ').first}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usageLimit,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total usage limit (0 = unlimited)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _perUser,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Per user usage limit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Free delivery'),
                  value: _freeDelivery,
                  activeColor: AppColor.primary,
                  onChanged: (v) => setState(() => _freeDelivery = v),
                ),
                SwitchListTile(
                  title: const Text('First order only'),
                  value: _firstOrderOnly,
                  activeColor: AppColor.primary,
                  onChanged: (v) => setState(() => _firstOrderOnly = v),
                ),
                SwitchListTile(
                  title: const Text('One per device (first-order abuse)'),
                  value: _onePerDevice,
                  activeColor: AppColor.primary,
                  onChanged: (v) => setState(() => _onePerDevice = v),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  activeColor: AppColor.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                if (_loadingOptions)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (_type.needsVendors) ...[
                    const SizedBox(height: 8),
                    _MultiPicker(
                      title: 'Applicable vendors',
                      options: _vendors,
                      selected: _vendorIds,
                      onChanged: (ids) => setState(() => _vendorIds = ids),
                    ),
                  ],
                  if (_type.needsProducts) ...[
                    const SizedBox(height: 8),
                    _MultiPicker(
                      title: 'Applicable products',
                      options: _products,
                      selected: _productIds,
                      onChanged: (ids) => setState(() => _productIds = ids),
                    ),
                  ],
                  if (_categoryIds.isNotEmpty || true) ...[
                    const SizedBox(height: 8),
                    _MultiPicker(
                      title: 'Applicable categories (optional)',
                      options: _categories,
                      selected: _categoryIds,
                      onChanged: (ids) => setState(() => _categoryIds = ids),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, _buildModel());
                  },
                  child: Text(widget.existing == null ? 'Create' : 'Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MultiPicker extends StatelessWidget {
  const _MultiPicker({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<MapEntry<String, String>> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.take(40).map((e) {
            final on = selected.contains(e.key);
            return FilterChip(
              label: Text(e.value, style: const TextStyle(fontSize: 12)),
              selected: on,
              onSelected: (v) {
                final next = List<String>.from(selected);
                if (v) {
                  next.add(e.key);
                } else {
                  next.remove(e.key);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
