import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/theme/app_text_styles.dart';
import 'package:quick_grocery_admin/core/widgets/admin_list_tile.dart';
import 'package:quick_grocery_admin/model/combo_offer_model.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/view/combo_offers/services/combo_offer_admin_service.dart';

/// Admin — create and manage combo product bundles (scroll via [AdminPageSlot]).
class ComboOffersScreen extends StatefulWidget {
  const ComboOffersScreen({super.key});

  @override
  State<ComboOffersScreen> createState() => _ComboOffersScreenState();
}

class _ComboOffersScreenState extends State<ComboOffersScreen> {
  final _svc = ComboOfferAdminService();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _comboPrice = TextEditingController();
  final _stock = TextEditingController(text: '50');
  final _priority = TextEditingController(text: '10');

  List<ProductModel> _allProducts = [];
  List<VendorModel> _vendors = [];
  final Set<String> _selectedIds = {};
  String? _editingId;
  String? _existingImage;
  String? _vendorId;
  bool _isActive = true;
  bool _isFlash = false;
  bool _isTrending = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;
  StreamSubscription<List<ProductModel>>? _productsSub;
  StreamSubscription<List<VendorModel>>? _vendorsSub;

  @override
  void initState() {
    super.initState();
    _productsSub = _svc.watchProducts().listen((list) {
      if (mounted) setState(() => _allProducts = list);
    });
    _vendorsSub = _svc.watchVendors().listen((list) {
      if (mounted) setState(() => _vendors = list);
    });
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _vendorsSub?.cancel();
    _title.dispose();
    _subtitle.dispose();
    _comboPrice.dispose();
    _stock.dispose();
    _priority.dispose();
    super.dispose();
  }

  double get _originalTotal {
    return _allProducts
        .where((p) => _selectedIds.contains(p.id))
        .fold<double>(0, (s, p) => s + (double.tryParse(p.price) ?? 0));
  }

  void _resetForm() {
    _title.clear();
    _subtitle.clear();
    _comboPrice.clear();
    _stock.text = '50';
    _priority.text = '10';
    _selectedIds.clear();
    _editingId = null;
    _existingImage = null;
    _vendorId = null;
    _isActive = true;
    _isFlash = false;
    _isTrending = true;
    _startsAt = null;
    _endsAt = null;
    _svc.clearImage();
    setState(() {});
  }

  void _loadForEdit(ComboOfferModel c) {
    _editingId = c.id;
    _title.text = c.title;
    _subtitle.text = c.subtitle;
    _comboPrice.text = c.comboPrice.toStringAsFixed(0);
    _stock.text = c.stock.toString();
    _priority.text = c.priority.toString();
    _selectedIds
      ..clear()
      ..addAll(c.productIds);
    _existingImage = c.image;
    _vendorId = c.vendorId.isEmpty ? null : c.vendorId;
    _isActive = c.isActive;
    _isFlash = c.isFlashSale;
    _isTrending = c.isTrending;
    _startsAt = c.startsAt;
    _endsAt = c.endsAt;
    setState(() {});
  }

  void _duplicate(ComboOfferModel c) {
    _loadForEdit(c);
    _editingId = null;
    _title.text = '${c.title} (Copy)';
    setState(() {});
  }

  Future<void> _save() async {
    final selected =
        _allProducts.where((p) => _selectedIds.contains(p.id)).toList();
    final price = double.tryParse(_comboPrice.text.trim()) ?? 0;
    if (selected.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select products and set combo price')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final vendor = _vendors.where((v) => v.id == _vendorId).firstOrNull;
      await _svc.saveCombo(
        editingId: _editingId,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        selectedProducts: selected,
        comboPrice: price,
        vendorId: _vendorId ?? '',
        vendorName: vendor?.shopName ?? '',
        stock: int.tryParse(_stock.text) ?? 50,
        isActive: _isActive,
        isFlashSale: _isFlash,
        isTrending: _isTrending,
        priority: int.tryParse(_priority.text) ?? 10,
        startsAt: _startsAt,
        endsAt: _endsAt,
        existingImageUrl: _existingImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combo saved')),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Combo Offers', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 6),
        Text(
          'Create product bundles with discounted combo pricing.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final wide = w >= 900;
            if (wide) {
              final formW = w * 0.58;
              final listW = w - formW - 20;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: formW, child: _buildForm()),
                  const SizedBox(width: 20),
                  SizedBox(width: listW, child: _buildList()),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildForm(),
                const SizedBox(height: 20),
                _buildList(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm() {
    final pct = _originalTotal > 0 && _comboPrice.text.isNotEmpty
        ? (((_originalTotal - (double.tryParse(_comboPrice.text) ?? 0)) /
                    _originalTotal) *
                100)
            .round()
        : 0;

    return _ComboPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _editingId == null ? 'Create combo offer' : 'Edit combo offer',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Combo title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitle,
            decoration: const InputDecoration(
              labelText: 'Subtitle',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await _svc.pickImage();
                setState(() {});
              },
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _svc.imageBytes != null || (_existingImage?.isNotEmpty ?? false)
                    ? 'Change banner image'
                    : 'Upload combo banner',
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _vendorId,
            decoration: const InputDecoration(
              labelText: 'Vendor (optional)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All / platform'),
              ),
              ..._vendors.map(
                (v) => DropdownMenuItem(
                  value: v.id,
                  child: Text(
                    v.shopName.isNotEmpty ? v.shopName : v.firstName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _vendorId = v),
          ),
          const SizedBox(height: 12),
          Text(
            'Select products (${_selectedIds.length}) · Original ₹${_originalTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _allProducts.length,
              itemBuilder: (_, i) {
                final p = _allProducts[i];
                final sel = _selectedIds.contains(p.id);
                return CheckboxListTile(
                  value: sel,
                  title: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('₹${p.price}'),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedIds.add(p.id);
                      } else {
                        _selectedIds.remove(p.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 480;
              final priceField = TextField(
                controller: _comboPrice,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Combo price (₹)',
                  helperText: pct > 0 ? '$pct% off' : null,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              );
              final stockField = TextField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              );
              if (stacked) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    priceField,
                    const SizedBox(height: 12),
                    stockField,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: priceField),
                  const SizedBox(width: 12),
                  Expanded(child: stockField),
                ],
              );
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Flash sale'),
            value: _isFlash,
            onChanged: (v) => setState(() => _isFlash = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Trending'),
            value: _isTrending,
            onChanged: (v) => setState(() => _isTrending = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editingId == null ? 'Save combo' : 'Update combo'),
              ),
              OutlinedButton(onPressed: _resetForm, child: const Text('New')),
              if (_editingId != null)
                OutlinedButton(
                  onPressed: () {
                    final c = ComboOfferModel(
                      id: _editingId!,
                      title: _title.text,
                      productIds: _selectedIds.toList(),
                      products: const [],
                      originalTotalPrice: _originalTotal,
                      comboPrice: double.tryParse(_comboPrice.text) ?? 0,
                      discountPercent: pct,
                    );
                    _duplicate(c);
                  },
                  child: const Text('Duplicate'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<ComboOfferModel>>(
      stream: _svc.watchCombos(),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting && list.isEmpty) {
          return const _ComboPanel(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return _ComboPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Existing combos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const Text('No combo offers yet')
              else
                ...list.map(
                  (c) => AdminListTile(
                    leading: c.image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              c.image,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.shopping_basket),
                    title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '₹${c.comboPrice.toStringAsFixed(0)} · ${c.discountPercent}% off · stock ${c.stock}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: c.isActive,
                          onChanged: (v) => _svc.toggleActive(c.id, v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _loadForEdit(c),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _svc.deleteCombo(c.id),
                        ),
                      ],
                    ),
                    onTap: () => _loadForEdit(c),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// White panel — bounded width from parent, no infinite stretch.
class _ComboPanel extends StatelessWidget {
  const _ComboPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
