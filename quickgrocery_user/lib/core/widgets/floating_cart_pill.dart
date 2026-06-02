import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/view/cart/screen/cart_screen.dart';

import '../design/app_tokens.dart';

/// Premium "view cart" pill — reads [cartProvider] (single source of truth).
class FloatingCartPill extends ConsumerWidget {
  const FloatingCartPill({
    super.key,
    this.horizontalInset = 24,
  });

  static const double kGapAboveTabBar = 12;

  static double positionedBottomFullScreen(BuildContext context) =>
      kGapAboveTabBar + MediaQuery.paddingOf(context).bottom;

  final double horizontalInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: Offset.zero,
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
      child: AnimatedOpacity(
        opacity: 1,
        duration: AppMotion.medium,
        child: _PillBody(
          cart: cart,
          horizontalInset: horizontalInset,
        ),
      ),
    );
  }
}

class _PillBody extends StatelessWidget {
  const _PillBody({
    required this.cart,
    required this.horizontalInset,
  });

  final CartState cart;
  final double horizontalInset;

  @override
  Widget build(BuildContext context) {
    final totalCount = cart.totalUnits;
    final total = cart.bill.total > 0 ? cart.bill.total : cart.bill.subtotal;
    final preview = cart.items.take(3).toList();

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
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/cart'),
                builder: (_) => const CartScreen(),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: AppColor.primary,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  _Avatars(items: preview, max: 3, extra: cart.items.length),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🛒 $totalCount ${totalCount == 1 ? 'item' : 'items'}',
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
                          'view_cart'.tr(),
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
  const _Avatars({
    required this.items,
    required this.max,
    required this.extra,
  });

  final List<CartItem> items;
  final int max;
  final int extra;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(max).toList();
    final extraCount = extra - shown.length;

    if (shown.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.shopping_cart_outlined, size: 18),
      );
    }

    return SizedBox(
      width: shown.length * 28.0 + (extraCount > 0 ? 24 : 0),
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
          if (extraCount > 0)
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
                  '+$extraCount',
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
