import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/core/responsive/admin_responsive.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/product_promotions/models/product_promotion_model.dart';
import 'package:quick_grocery_admin/view/product_promotions/services/product_promotions_admin_service.dart';
import 'package:quick_grocery_admin/view/product_promotions/widgets/product_promotion_editor_sheet.dart';

/// Marketing → Product Promotions — admin control over vendor product promos.
class ProductPromotionsScreen extends StatefulWidget {
  const ProductPromotionsScreen({super.key});

  @override
  State<ProductPromotionsScreen> createState() =>
      _ProductPromotionsScreenState();
}

class _ProductPromotionsScreenState extends State<ProductPromotionsScreen> {
  final _service = ProductPromotionsAdminService();
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(
    ProductModel product,
    List<ProductPromotionModel> allPromos,
  ) async {
    final existing =
        allPromos.where((p) => p.productId == product.id).toList();
    final saved = await ProductPromotionEditorSheet.show(
      context,
      product: product,
      service: _service,
      existing: existing,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promotions saved — apps update live')),
      );
    }
  }

  List<ProductModel> _filterProducts(
    List<ProductModel> products,
    List<ProductPromotionModel> promos,
  ) {
    final q = _search.text.trim().toLowerCase();
    var list = products;
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.shopName.toLowerCase().contains(q) ||
                p.id.toLowerCase().contains(q),
          )
          .toList();
    }

    final promoProductIds = promos
        .where((p) => p.enabled && !p.expired)
        .map((p) => p.productId)
        .toSet();

    switch (_filter) {
      case 'active_promo':
        list = list.where((p) => promoProductIds.contains(p.id)).toList();
        break;
      case 'flash':
        final ids = promos
            .where(
              (p) =>
                  p.promotionType == PromotionTypes.flashSale &&
                  p.enabled &&
                  !p.expired,
            )
            .map((p) => p.productId)
            .toSet();
        list = list.where((p) => ids.contains(p.id) || p.isFlashSale).toList();
        break;
      case 'locked':
        final ids = promos
            .where((p) => p.locked && p.source == 'admin')
            .map((p) => p.productId)
            .toSet();
        list = list.where((p) => ids.contains(p.id)).toList();
        break;
      case 'featured':
        final ids = promos
            .where(
              (p) =>
                  p.promotionType == PromotionTypes.featured &&
                  p.enabled &&
                  !p.expired,
            )
            .map((p) => p.productId)
            .toSet();
        list = list.where((p) => ids.contains(p.id)).toList();
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final pad = adminResponsivePadding(w);

        return ColoredBox(
          color: const Color(0xFFFFFAF0),
          child: StreamBuilder<List<ProductModel>>(
            stream: _service.watchProducts(),
            builder: (context, productSnap) {
              return StreamBuilder<List<ProductPromotionModel>>(
                stream: _service.watchPromotions(),
                builder: (context, promoSnap) {
                  final loading =
                      (!productSnap.hasData && !productSnap.hasError) ||
                      (!promoSnap.hasData && !promoSnap.hasError);
                  final syncState = (productSnap.hasError || promoSnap.hasError)
                      ? AdminLiveSyncState(
                          isLoading: false,
                          hasError: true,
                          errorMessage:
                              (productSnap.error ?? promoSnap.error).toString(),
                        )
                      : productSnap.hasData && promoSnap.hasData
                          ? AdminLiveSyncState(
                              isLoading: false,
                              hasError: false,
                              lastSyncAt: DateTime.now(),
                            )
                          : const AdminLiveSyncState(isLoading: true);

                  final products = productSnap.data ?? const <ProductModel>[];
                  final promos =
                      promoSnap.data ?? const <ProductPromotionModel>[];
                  final filtered = _filterProducts(products, promos);

                  return Padding(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Promotions',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Marketing → Product Promotions',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AdminLiveSyncBar(state: syncState),
                          ],
                        ),
                        AppSpacing.h16,
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search products or vendors…',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        AppSpacing.h12,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: 'All',
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            _FilterChip(
                              label: 'Active promos',
                              selected: _filter == 'active_promo',
                              onTap: () =>
                                  setState(() => _filter = 'active_promo'),
                            ),
                            _FilterChip(
                              label: 'Flash Sale',
                              selected: _filter == 'flash',
                              onTap: () => setState(() => _filter = 'flash'),
                            ),
                            _FilterChip(
                              label: 'Featured',
                              selected: _filter == 'featured',
                              onTap: () => setState(() => _filter = 'featured'),
                            ),
                            _FilterChip(
                              label: 'Locked',
                              selected: _filter == 'locked',
                              onTap: () => setState(() => _filter = 'locked'),
                            ),
                            _FilterChip(
                              label: 'Vendor requests',
                              selected: _filter == 'requests',
                              onTap: () => setState(() => _filter = 'requests'),
                            ),
                          ],
                        ),
                        AppSpacing.h12,
                        Expanded(
                          child: _filter == 'requests'
                              ? _VendorRequestsPane(service: _service)
                              : loading
                              ? const Center(child: CircularProgressIndicator())
                              : filtered.isEmpty
                                  ? const Center(
                                      child: Text('No products match filters'),
                                    )
                                  : Card(
                                      color: Colors.white,
                                      clipBehavior: Clip.antiAlias,
                                      child: ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, i) {
                                          final p = filtered[i];
                                          final pPromos = promos
                                              .where(
                                                (x) =>
                                                    x.productId == p.id &&
                                                    x.enabled &&
                                                    !x.expired,
                                              )
                                              .toList();
                                          final locked = pPromos.any(
                                            (x) =>
                                                x.locked && x.source == 'admin',
                                          );
                                          return ListTile(
                                            leading: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: p.image.isNotEmpty
                                                  ? Image.network(
                                                      p.image,
                                                      width: 48,
                                                      height: 48,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) =>
                                                          _placeholder(),
                                                    )
                                                  : _placeholder(),
                                            ),
                                            title: Text(
                                              p.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  p.shopName.isEmpty
                                                      ? 'Vendor: ${p.vendorId}'
                                                      : p.shopName,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Wrap(
                                                  spacing: 4,
                                                  runSpacing: 4,
                                                  children: [
                                                    if (p.isFlashSale ||
                                                        pPromos.any(
                                                          (x) =>
                                                              x.promotionType ==
                                                              PromotionTypes
                                                                  .flashSale,
                                                        ))
                                                      const _MiniChip(
                                                        'Flash',
                                                        Colors.red,
                                                      ),
                                                    if (locked)
                                                      const _MiniChip(
                                                        'Locked',
                                                        Colors.orange,
                                                      ),
                                                    ...pPromos
                                                        .take(3)
                                                        .map(
                                                          (x) => _MiniChip(
                                                            x.typeLabel,
                                                            Colors.blueGrey,
                                                          ),
                                                        ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            isThreeLine: true,
                                            trailing: FilledButton.tonal(
                                              onPressed: () =>
                                                  _edit(p, promos),
                                              child: const Text('Manage'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade200,
      child: const Icon(Icons.inventory_2_outlined, size: 22),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColor.primary.withValues(alpha: 0.45),
      checkmarkColor: Colors.black87,
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Pending vendor promotion requests — approve creates a locked admin promo.
class _VendorRequestsPane extends StatefulWidget {
  const _VendorRequestsPane({required this.service});
  final ProductPromotionsAdminService service;

  @override
  State<_VendorRequestsPane> createState() => _VendorRequestsPaneState();
}

class _VendorRequestsPaneState extends State<_VendorRequestsPane> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.listPromotionRequests();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.service.listPromotionRequests();
    });
  }

  Future<void> _resolve(String id, String action) async {
    try {
      await widget.service.resolvePromotionRequest(
        requestId: id,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Request approved — promotion locked by admin'
                : 'Request rejected',
          ),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No pending vendor requests'));
        }
        return Card(
          color: Colors.white,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final id = (r['id'] ?? '').toString();
              final name = (r['productName'] ?? r['productId'] ?? '').toString();
              final vendor = (r['vendorName'] ?? r['vendorId'] ?? '').toString();
              final type = (r['promotionType'] ?? '').toString();
              final reason = (r['reason'] ?? '').toString();
              final sale = r['salePrice'];
              return ListTile(
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '$vendor · $type'
                  '${sale != null ? ' · ₹$sale' : ''}'
                  '${reason.isNotEmpty ? '\n$reason' : ''}',
                ),
                isThreeLine: reason.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _resolve(id, 'reject'),
                      child: const Text('Reject'),
                    ),
                    FilledButton(
                      onPressed: () => _resolve(id, 'approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.primary,
                      ),
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
