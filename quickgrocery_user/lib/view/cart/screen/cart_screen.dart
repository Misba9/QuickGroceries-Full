import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickgrocery/core/auth/guest_auth_coordinator.dart';
import 'package:quickgrocery/core/auth/guest_auth_guard.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/core/widgets/horizontal_product_rail.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/address/services/address_service.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/domain/pricing_calculator.dart';
import 'package:quickgrocery/core/feedback/show_top_error_toast.dart';
import 'package:quickgrocery/core/inventory/inventory_limit_messages.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/cart_header.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/cart_shimmer.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/free_delivery_banner.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_bill_card.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_cart_item_card.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_checkout_bar.dart';
import 'package:quickgrocery/view/cart/presentation/widgets/premium_empty_cart.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/coupons/coupon_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
/// **CartScreen** — premium Zepto / Blinkit / Instamart-style bag.
///
/// **Layout architecture (the user explicitly asked for this):**
///
/// ```
/// Scaffold
///  ├ body: SafeArea(bottom: false) → Column
///  │   ├ CartHeader
///  │   └ Expanded(CustomScrollView / empty / shimmer)
///  └ bottomNavigationBar: PremiumCheckoutBar (when cart non-empty)
/// ```
///
/// * [bottomNavigationBar] keeps the dock above the keyboard and avoids
///   Column bottom overflow on small phones when [resizeToAvoidBottomInset]
///   reduces body height.
/// * Scrollable content stays in [Expanded].
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  static const _calc = PricingCalculator();
  bool _bootstrappedAddress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_bootstrappedAddress || !mounted) return;
      _bootstrappedAddress = true;
      if (FirebaseAuth.instance.currentUser == null) return;
      final address =
          legacy_provider.Provider.of<AddressService>(context, listen: false);
      await address.getAddress();
    });
  }

  BillBreakdown _bill(CartState cart, double zoneCharge) {
    final deliveryInt = zoneCharge > 0
        ? zoneCharge.round()
        : cart.pricing.standardDeliveryCharge;
    return _calc.compute(
      items: cart.items,
      config: cart.pricing,
      coupon: cart.coupon,
      deliveryChargeOverride: deliveryInt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    final addressService = legacy_provider.Provider.of<AddressService>(context);
    final pin = addressService.activeDeliveryPin ?? addressService.pinCode;
    final zoneAsync = ref.watch(zoneDeliveryProvider(pin));
    final zoneCharge = zoneAsync.value ?? 0;
    final bill = _bill(cart, zoneCharge);

    final showShimmer = cart.isHydrating && cart.isEmpty;
    final showEmpty = !cart.isHydrating && cart.isEmpty;

    return Scaffold(
      backgroundColor: AppSurface.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CartHeader(
              itemCount: cart.totalUnits,
              onBack: () => Navigator.maybePop(context),
              onCoupons: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CouponScreen()),
              ),
            ),
            Expanded(
              child: showShimmer
                  ? const CartShimmer()
                  : showEmpty
                      ? PremiumEmptyCart(
                          onBrowse: () => Navigator.maybePop(context),
                        )
                      : _CartBody(
                          cart: cart,
                          bill: bill,
                          zoneAsync: zoneAsync,
                          notifier: notifier,
                          addressService: addressService,
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : PremiumCheckoutBar(
              total: bill.total,
              itemCount: cart.totalUnits,
              savings: bill.totalSavings,
              enabled: bill.meetsMinimumOrder &&
                  !cart.items.any((e) => e.isUnavailable),
              isLoading: cart.isSyncing,
              helperText: _helperText(cart, bill),
              helperIsError: !bill.meetsMinimumOrder ||
                  cart.items.any((e) => e.isUnavailable),
              onCheckout: () async {
                final authed = await GuestAuthGuard.requireAuth(
                  context,
                  ref,
                  postLogin: GuestPostLoginAction.continueCheckout,
                );
                if (!authed || !context.mounted) return;
                Navigator.push(context, AppPageRoutes.checkout());
              },
            ),
    );
  }

  String? _helperText(CartState cart, BillBreakdown bill) {
    if (cart.items.any((e) => e.isUnavailable)) {
      return 'Some items in your bag are unavailable — remove them to checkout';
    }
    if (!bill.meetsMinimumOrder) {
      final delta =
          (bill.minimumOrderValue - bill.subtotal).clamp(0, double.infinity);
      return 'Min order ₹${bill.minimumOrderValue.toStringAsFixed(0)} • '
          'Add ₹${delta.toStringAsFixed(0)} more to checkout';
    }
    return null;
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Body — scrollable content
// ──────────────────────────────────────────────────────────────────────────

class _CartBody extends StatelessWidget {
  const _CartBody({
    required this.cart,
    required this.bill,
    required this.zoneAsync,
    required this.notifier,
    required this.addressService,
  });

  final CartState cart;
  final BillBreakdown bill;
  final AsyncValue<double> zoneAsync;
  final CartNotifier notifier;
  final AddressService addressService;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppSurface.success,
      onRefresh: () async {
        await addressService.getAddress();
      },
      child: CustomScrollView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: FreeDeliveryBanner(
                subtotal: bill.subtotal,
                threshold: cart.pricing.freeDeliveryThreshold.toDouble(),
                isFreeDeliveryEnabled: cart.pricing.isFreeDeliveryEnabled,
                isDeliveryChargesEnabled: cart.pricing.isDeliveryChargesEnabled,
                surgeActive: cart.pricing.surgeActive,
                surgeMultiplier: cart.pricing.surgeMultiplier,
                surgeReason: cart.pricing.surgeReason,
              ),
            ),
          ),
          if (cart.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _InlineError(
                  message: cart.errorMessage!,
                  onRetry: notifier.retry,
                ),
              ),
            ),
          if (zoneAsync.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: AppSurface.subtle,
                ),
              ),
            ),
          if (cart.items.any((e) => e.isUnavailable))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _UnavailableCartBanner(
                  onRemoveUnavailable: () {
                    final n = notifier.removeUnavailableItems();
                    if (context.mounted && n > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            n == 1
                                ? 'Removed 1 unavailable item'
                                : 'Removed $n unavailable items',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
              child: Row(
                children: [
                  Text(
                    'Items in bag',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppSurface.text,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppSurface.subtle,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${cart.items.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppSurface.textSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      size: 18,
                      color: AppSurface.danger,
                    ),
                    label: Text(
                      'Clear all',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppSurface.danger,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = cart.items[i];
                  return FadeInUp(
                    duration: Duration(milliseconds: 220 + i * 30),
                    from: 14,
                    child: PremiumCartItemCard(
                      item: item,
                      onIncrement: () {
                        if (notifier.increment(item.productId)) return;
                        showTopErrorToast(
                          context,
                          InventoryLimitMessages.incrementBlocked(
                            l10n: context.l10n,
                            stock: item.stock,
                            maxOrder: item.maxOrder,
                            currentCount: item.itemCount,
                          ),
                        );
                      },
                      onDecrement: () => notifier.decrement(item.productId),
                      onRemove: () => notifier.remove(item.productId),
                    ),
                  );
                },
                childCount: cart.items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: PremiumBillCard(
                bill: bill,
                pricing: cart.pricing,
                couponLabel: cart.coupon != null
                    ? 'Coupon · ${cart.coupon!.code}'
                    : null,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _YouMightAlsoLikeRail()),
          // Bottom breathing room so the last card never sits flush
          // against the checkout bar's top divider.
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            title: Text(
              'Clear cart?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: AppSurface.text,
              ),
            ),
            content: Text(
              'This will remove all items from your bag. Are you sure?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppSurface.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppSurface.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: AppSurface.danger,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) notifier.clear();
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  Inline error
// ──────────────────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppSurface.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: AppSurface.danger.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppSurface.danger,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: AppSurface.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  color: AppSurface.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
//  "You might also like" rail
// ──────────────────────────────────────────────────────────────────────────

class _YouMightAlsoLikeRail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return legacy_provider.Consumer2<HomeProvider, CategoryService>(
      builder: (context, home, cat, _) {
        if (home.products == null || home.products!.isEmpty) {
          return const SizedBox.shrink();
        }
        List<ProductModel> filtered = home.products!;
        if (home.categories.isNotEmpty) {
          final name = home.categories.first.name;
          filtered = home.products!
              .where((p) => p.category == name)
              .toList(growable: false);
          if (filtered.isEmpty) filtered = home.products!;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppSurface.text,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.you_might_also_like,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppSurface.text,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Responsive.horizontalProductRailHeight(context),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: kHorizontalProductRailPhysics,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filtered.length,
                  itemBuilder: (context, j) {
                    final p = filtered[j];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: HomeProductCard(
                        product: p,
                        width: Responsive.of(context).isPhone ? 148 : 158,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnavailableCartBanner extends StatelessWidget {
  const _UnavailableCartBanner({required this.onRemoveUnavailable});

  final VoidCallback onRemoveUnavailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSurface.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppSurface.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppSurface.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some items are unavailable. Remove them to continue checkout.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppSurface.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: onRemoveUnavailable,
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppSurface.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
