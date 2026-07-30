import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:quickgrocery/core/navigation/floating_cart_suppression.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/models/combo_offer_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/combo/presentation/providers/combo_providers.dart';
import 'package:quickgrocery/view/home/presentation/widgets/cached_image.dart';

/// Full combo breakdown + add all to cart.
class ComboDetailScreen extends ConsumerStatefulWidget {
  const ComboDetailScreen({
    super.key,
    required this.combo,
    this.addToCartOnLoad = false,
  });

  final ComboOfferModel combo;
  final bool addToCartOnLoad;

  @override
  ConsumerState<ComboDetailScreen> createState() => _ComboDetailScreenState();
}

class _ComboDetailScreenState extends ConsumerState<ComboDetailScreen> {
  List<ProductModel>? _products;
  bool _loading = true;
  int _qty = 1;
  String? _error;
  bool _justAdded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(comboOfferServiceProvider).incrementViewCount(widget.combo.id);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = ref.read(comboOfferServiceProvider);
      var products = await svc.fetchProductsByIds(widget.combo.productIds);
      if (products.length < widget.combo.productIds.length) {
        final cached = ref.read(comboProductsResolverProvider(widget.combo));
        cached.whenData((p) {
          if (p.isNotEmpty) products = p;
        });
      }
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
      if (widget.addToCartOnLoad && products.isNotEmpty) {
        _addToCart(products);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  void _addToCart(List<ProductModel> products) {
    if (!widget.combo.isAvailableNow) {
      AppSnackBar.error(
        'This combo is currently unavailable',
        context: context,
      );
      return;
    }
    ref.read(cartProvider.notifier).addComboBundle(
          comboId: widget.combo.id,
          products: products,
          comboUnitPrice: widget.combo.comboPrice,
          bundleCount: _qty,
        );
    ref.read(comboOfferServiceProvider).incrementOrderCount(widget.combo.id);
    setState(() => _justAdded = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final combo = widget.combo;
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppSurface.of(context).background,
      appBar: AppBar(
        title: Text(
          'Combo details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppSurface.of(context).background,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? _ComboDetailLoadingBody()
          : _error != null
              ? Center(child: Text(_error!))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: combo.image.isNotEmpty
                                ? CachedImage(url: combo.image, fit: BoxFit.cover)
                                : Container(
                                    color: AppSurface.of(context).subtle,
                                    child: const Icon(Icons.shopping_basket, size: 64),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              combo.title,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (combo.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                combo.subtitle,
                                style: GoogleFonts.poppins(
                                  color: AppSurface.of(context).textSecondary,
                                ),
                              ),
                            ],
                            SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(color: AppSurface.of(context).border),
                              ),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Combo price',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppSurface.of(context).textMuted,
                                        ),
                                      ),
                                      Text(
                                        fmt.format(combo.comboPrice * _qty),
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        fmt.format(combo.originalTotalPrice * _qty),
                                        style: TextStyle(
                                          decoration: TextDecoration.lineThrough,
                                          color: AppSurface.of(context).textMuted,
                                        ),
                                      ),
                                      Text(
                                        'Save ${fmt.format(combo.savingsAmount * _qty)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF11A04C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Included products',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final p = _products![i];
                          final line = combo.products
                              .where((l) => l.productId == p.id)
                              .firstOrNull;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: CachedImage(url: p.image, fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(p.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              'Qty ${line?.quantity ?? 1} · ${fmt.format(p.price)}',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          );
                        },
                        childCount: _products?.length ?? 0,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
      bottomNavigationBar: _loading || _products == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _QtyStepper(
                      qty: _qty,
                      maxQty: combo.stock > 0 ? combo.stock : null,
                      onChanged: (v) => setState(() => _qty = v),
                      onMaxReached: () => AppSnackBar.error(
                        combo.stock == 1
                            ? 'Only 1 combo available'
                            : 'Only ${combo.stock} combos available',
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        onPressed: combo.isAvailableNow && !_justAdded
                            ? () => _addToCart(_products!)
                            : null,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _justAdded
                              ? Row(
                                  key: const ValueKey('added'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Added',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  key: const ValueKey('add'),
                                  'Add all to cart',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Hides the global cart pill while combo data is loading (no bottom bar yet).
class _ComboDetailLoadingBody extends StatefulWidget {
  const _ComboDetailLoadingBody();

  @override
  State<_ComboDetailLoadingBody> createState() => _ComboDetailLoadingBodyState();
}

class _ComboDetailLoadingBodyState extends State<_ComboDetailLoadingBody> {
  @override
  void initState() {
    super.initState();
    FloatingCartSuppression.acquire();
  }

  @override
  void dispose() {
    FloatingCartSuppression.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onChanged,
    this.maxQty,
    this.onMaxReached,
  });

  final int qty;
  final int? maxQty;
  final ValueChanged<int> onChanged;
  final VoidCallback? onMaxReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppSurface.of(context).border),
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: qty > 1 ? () => onChanged(qty - 1) : null,
            icon: const Icon(Icons.remove, size: 20),
          ),
          Text('$qty', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          IconButton(
            onPressed: () {
              final cap = maxQty;
              if (cap != null && qty >= cap) {
                onMaxReached?.call();
                return;
              }
              onChanged(qty + 1);
            },
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }
}
