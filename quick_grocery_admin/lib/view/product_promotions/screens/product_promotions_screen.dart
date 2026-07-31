import 'package:flutter/material.dart';
import 'package:quick_grocery_admin/core/realtime/admin_live_sync.dart';
import 'package:quick_grocery_admin/model/product_model.dart';
import 'package:quick_grocery_admin/model/vendor_model.dart';
import 'package:quick_grocery_admin/style/app_color.dart';
import 'package:quick_grocery_admin/utils/app_spacing.dart';
import 'package:quick_grocery_admin/view/product_promotions/models/product_promotion_model.dart';
import 'package:quick_grocery_admin/view/product_promotions/services/product_promotions_admin_service.dart';
import 'package:quick_grocery_admin/view/product_promotions/widgets/product_promotion_editor_sheet.dart';

/// Marketing → Product Promotions — admin control over vendor product promos.
///
/// Requires a bounded viewport ([AdminFlexPage] / [AdminPageSlot] flex).
/// Root [SizedBox.expand] guarantees [Column]+[Expanded] always get finite size.
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
  /// `null` = all vendors; otherwise only that vendor's products/promos.
  String? _selectedVendorId;

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
    // Force a definite size from the flex pane so Column/Expanded/ListView
    // never see unbounded constraints (root cause of blank white + no-size).
    return SizedBox.expand(
      child: ColoredBox(
        color: const Color(0xFFFFFAF0),
        child: StreamBuilder<List<VendorModel>>(
          stream: _service.watchVendors(),
          builder: (context, vendorSnap) {
            final vendors = vendorSnap.data ?? const <VendorModel>[];
            // Drop stale selection if vendor list no longer contains it.
            final vendorStillExists = _selectedVendorId == null ||
                vendors.any((v) => v.id == _selectedVendorId);
            final activeVendorId =
                vendorStillExists ? _selectedVendorId : null;

            return StreamBuilder<List<ProductModel>>(
              key: ValueKey('products_${activeVendorId ?? 'all'}'),
              stream: _service.watchProducts(vendorId: activeVendorId),
              builder: (context, productSnap) {
                return StreamBuilder<List<ProductPromotionModel>>(
                  key: ValueKey('promos_${activeVendorId ?? 'all'}'),
                  stream: _service.watchPromotions(vendorId: activeVendorId),
                  builder: (context, promoSnap) {
                    final loading =
                        (!productSnap.hasData && !productSnap.hasError) ||
                        (!promoSnap.hasData && !promoSnap.hasError);

                    final syncState =
                        (productSnap.hasError || promoSnap.hasError)
                            ? AdminLiveSyncState(
                                isLoading: false,
                                hasError: true,
                                errorMessage:
                                    (productSnap.error ?? promoSnap.error)
                                        .toString(),
                              )
                            : productSnap.hasData && promoSnap.hasData
                                ? AdminLiveSyncState(
                                    isLoading: false,
                                    hasError: false,
                                    lastSyncAt: DateTime.now(),
                                  )
                                : const AdminLiveSyncState(isLoading: true);

                    final products =
                        productSnap.data ?? const <ProductModel>[];
                    final promos =
                        promoSnap.data ?? const <ProductPromotionModel>[];
                    final filtered = _filterProducts(products, promos);
                    final selectedVendorName = activeVendorId == null
                        ? null
                        : vendors
                            .where((v) => v.id == activeVendorId)
                            .map(
                              (v) => v.shopName.isNotEmpty
                                  ? v.shopName
                                  : v.ownerName,
                            )
                            .firstOrNull;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdminLiveSyncBar(
                          state: syncState,
                          label: 'Promotions',
                        ),
                        AppSpacing.h12,
                        const Text(
                          'Product Promotions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedVendorName == null
                              ? 'Marketing → Product Promotions'
                              : 'Marketing → Product Promotions · $selectedVendorName',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        AppSpacing.h16,
                        LayoutBuilder(
                          builder: (context, c) {
                            final narrow = c.maxWidth < 720;
                            final vendorDropdown = DropdownButtonFormField<String?>(
                              // ignore: deprecated_member_use
                              value: activeVendorId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Vendor',
                                prefixIcon: const Icon(Icons.storefront_outlined),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All vendors'),
                                ),
                                ...vendors.map(
                                  (v) => DropdownMenuItem<String?>(
                                    value: v.id,
                                    child: Text(
                                      v.shopName.isNotEmpty
                                          ? v.shopName
                                          : (v.ownerName.isNotEmpty
                                              ? v.ownerName
                                              : v.id),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedVendorId = v),
                            );
                            final searchField = TextField(
                              controller: _search,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: activeVendorId == null
                                    ? 'Search products or vendors…'
                                    : 'Search products…',
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                            if (narrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  vendorDropdown,
                                  AppSpacing.h12,
                                  searchField,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: vendorDropdown),
                                AppSpacing.w10,
                                Expanded(flex: 3, child: searchField),
                              ],
                            );
                          },
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
                              onTap: () =>
                                  setState(() => _filter = 'featured'),
                            ),
                            _FilterChip(
                              label: 'Locked',
                              selected: _filter == 'locked',
                              onTap: () => setState(() => _filter = 'locked'),
                            ),
                            _FilterChip(
                              label: 'Vendor requests',
                              selected: _filter == 'requests',
                              onTap: () =>
                                  setState(() => _filter = 'requests'),
                            ),
                          ],
                        ),
                        AppSpacing.h12,
                        Expanded(
                          child: _filter == 'requests'
                              ? _VendorRequestsPane(
                                  service: _service,
                                  vendorId: activeVendorId,
                                )
                              : loading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : filtered.isEmpty
                                      ? Center(
                                          child: Text(
                                            activeVendorId == null
                                                ? 'No products match filters'
                                                : 'No products for this vendor',
                                            textAlign: TextAlign.center,
                                          ),
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
                                                x.locked &&
                                                x.source == 'admin',
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
                                                      errorBuilder:
                                                          (_, __, ___) =>
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
                                            subtitle: Text(
                                              [
                                                p.shopName.isEmpty
                                                    ? 'Vendor: ${p.vendorId}'
                                                    : p.shopName,
                                                if (p.isFlashSale ||
                                                    pPromos.any(
                                                      (x) =>
                                                          x.promotionType ==
                                                          PromotionTypes
                                                              .flashSale,
                                                    ))
                                                  'Flash',
                                                if (locked) 'Locked',
                                                ...pPromos
                                                    .take(3)
                                                    .map((x) => x.typeLabel),
                                              ].join(' · '),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                    );
                  },
                );
              },
            );
          },
        ),
      ),
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

/// Pending vendor promotion requests — approve creates a locked admin promo.
class _VendorRequestsPane extends StatefulWidget {
  const _VendorRequestsPane({
    required this.service,
    this.vendorId,
  });
  final ProductPromotionsAdminService service;
  final String? vendorId;

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${snap.error}', textAlign: TextAlign.center),
            ),
          );
        }
        final all = snap.data ?? const [];
        final vendorId = widget.vendorId;
        final items = vendorId == null || vendorId.isEmpty
            ? all
            : all
                .where(
                  (r) => (r['vendorId'] ?? '').toString() == vendorId,
                )
                .toList();
        if (items.isEmpty) {
          return Center(
            child: Text(
              vendorId == null || vendorId.isEmpty
                  ? 'No pending vendor requests'
                  : 'No pending requests for this vendor',
              textAlign: TextAlign.center,
            ),
          );
        }
        return Card(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final r = items[i];
              final id = (r['id'] ?? '').toString();
              final name =
                  (r['productName'] ?? r['productId'] ?? '').toString();
              final vendor =
                  (r['vendorName'] ?? r['vendorId'] ?? '').toString();
              final type = (r['promotionType'] ?? '').toString();
              final reason = (r['reason'] ?? '').toString();
              final sale = r['salePrice'];
              return ListTile(
                title: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '$vendor · $type'
                  '${sale != null ? ' · ₹$sale' : ''}'
                  '${reason.isNotEmpty ? '\n$reason' : ''}',
                  maxLines: reason.isNotEmpty ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: reason.isNotEmpty,
                trailing: Wrap(
                  spacing: 4,
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
