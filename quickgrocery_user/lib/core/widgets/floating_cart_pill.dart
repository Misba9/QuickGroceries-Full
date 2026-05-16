import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';

import '../design/app_tokens.dart';

/// Premium "view cart" pill that floats above the content.
///
/// Reads the legacy [CategoryService] cart so it works app-wide. Drops
/// itself when the cart is empty. Use [FloatingCartPill.scaffold] to
/// stack it above any existing screen body.
class FloatingCartPill extends StatelessWidget {
  const FloatingCartPill({
    super.key,
    this.bottomInset = 12,
    this.horizontalInset = 24,
  });

  /// Same vertical band as [PremiumFiveTabNav.floatingCartGapAboveBar].
  static const double kGapAboveTabBar = 12;

  /// [Positioned.bottom] when the stack fills the screen (no tab bar) but
  /// [SafeArea] bottom is off — adds [MediaQuery.padding.bottom] for the
  /// home indicator / gesture inset.
  static double positionedBottomFullScreen(BuildContext context) =>
      kGapAboveTabBar + MediaQuery.paddingOf(context).bottom;

  /// Wrap any [body] with the pill stacked at the bottom. Use this on
  /// screens that don't already have their own floating cart bar.
  static Widget scaffold({
    required Widget body,
    double bottomInset = 12,
    double horizontalInset = 24,
  }) {
    return Stack(
      children: [
        body,
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset,
          child: FloatingCartPill(
            bottomInset: bottomInset,
            horizontalInset: horizontalInset,
          ),
        ),
      ],
    );
  }

  final double bottomInset;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    return legacy.Consumer<CategoryService>(
      builder: (context, cart, _) {
        final items = cart.selectedProduct;
        final visible = items.isNotEmpty;
        return AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.6),
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: AppMotion.medium,
            child: visible
                ? _PillBody(
                    horizontalInset: horizontalInset,
                  )
                : const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _PillBody extends StatelessWidget {
  const _PillBody({required this.horizontalInset});
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final cart = legacy.Provider.of<CategoryService>(context);
    final items = cart.selectedProduct;
    final totalCount =
        items.fold<int>(0, (acc, p) => acc + (p.itemCount <= 0 ? 1 : p.itemCount));

    final total = items.fold<double>(
      0,
      (acc, p) {
        final unit = p.price <= 0 ? p.slashedPrice.toDouble() : p.price.toDouble();
        return acc + unit * (p.itemCount <= 0 ? 1 : p.itemCount);
      },
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalInset),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        elevation: 0,
        shadowColor: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _Avatars(items: items, max: 3),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalCount item${totalCount == 1 ? '' : 's'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          _money(total),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Cart',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _money(double v) =>
      '₹${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
}

class _Avatars extends StatelessWidget {
  const _Avatars({required this.items, required this.max});
  final List items;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(max).toList();
    final extra = items.length - shown.length;

    return SizedBox(
      width: shown.length * 28.0 + (extra > 0 ? 24 : 0),
      height: 36,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  shown[i].image,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppSurface.textMuted,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * 22.0,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
