import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/vendor_model.dart';
import '../../services/combo_offer_service.dart';
import '../../style/app_color.dart';
import '../../utils/app_spacing.dart';

/// Vendor — create combo packs from own products.
class VendorComboOffersScreen extends StatefulWidget {
  const VendorComboOffersScreen({super.key, required this.vendor});

  final VendorModel vendor;

  @override
  State<VendorComboOffersScreen> createState() => _VendorComboOffersScreenState();
}

class _VendorComboOffersScreenState extends State<VendorComboOffersScreen> {
  final _svc = ComboOfferService();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '30');

  List<ProductModel> _products = [];
  final Set<String> _selected = {};
  String? _editingId;
  String? _imageUrl;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await _svc.vendorProducts(widget.vendor.id);
    if (mounted) setState(() => _products = list);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selected = _products.where((p) => _selected.contains(p.id)).toList();
    final combo = double.tryParse(_price.text) ?? 0;
    if (selected.isEmpty || combo <= 0) return;
    setState(() => _saving = true);
    try {
      await _svc.save(
        vendorId: widget.vendor.id,
        vendorName: widget.vendor.shopName,
        editingId: _editingId,
        title: _title.text.trim(),
        subtitle: _subtitle.text.trim(),
        products: selected,
        comboPrice: combo,
        stock: int.tryParse(_stock.text) ?? 30,
        isActive: _active,
        existingImage: _imageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Combo saved')),
        );
        _reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    _title.clear();
    _subtitle.clear();
    _price.clear();
    _stock.text = '30';
    _selected.clear();
    _editingId = null;
    _imageUrl = null;
    _active = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.black,
        title: const Text('Combo offers', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(
                        labelText: 'Combo title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.h10,
                    TextField(
                      controller: _subtitle,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.h10,
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _svc.pickImage();
                        setState(() {});
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Upload combo image'),
                    ),
                    AppSpacing.h10,
                    Text('Your products', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (_, i) {
                          final p = _products[i];
                          return CheckboxListTile(
                            value: _selected.contains(p.id),
                            title: Text(p.name),
                            subtitle: Text('₹${p.price}'),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(p.id);
                                } else {
                                  _selected.remove(p.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _price,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Combo price ₹',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _stock,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      title: const Text('Active'),
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
                      onPressed: _saving ? null : _save,
                      child: Text(_editingId == null ? 'Save combo' : 'Update'),
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.h20,
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _svc.watchVendorCombos(widget.vendor.id),
              builder: (context, snap) {
                final list = snap.data ?? [];
                return Card(
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text('My combos', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No combos yet'),
                        )
                      else
                        ...list.map((c) {
                          final id = c['id'] as String;
                          return ListTile(
                            title: Text('${c['title']}'),
                            subtitle: Text('₹${c['comboPrice']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: c['isActive'] as bool? ?? true,
                                  onChanged: (v) => _svc.toggle(id, v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _svc.delete(id),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
