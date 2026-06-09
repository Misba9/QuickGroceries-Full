import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quickgrocery/constants/app_color.dart';
import 'package:quickgrocery/core/design/app_tokens.dart';
import 'package:quickgrocery/core/navigation/app_page_routes.dart';
import 'package:quickgrocery/core/navigation/app_route_names.dart';
import 'package:quickgrocery/core/navigation/app_route_observer.dart';
import 'package:quickgrocery/core/push/push_navigation.dart';
import 'package:quickgrocery/view/cart/domain/cart_models.dart';
import 'package:quickgrocery/view/cart/presentation/providers/cart_notifier.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

/// App-wide floating cart bar — single source of truth for the view-cart pill.
class GlobalFloatingCartWidget extends ConsumerWidget {
  const GlobalFloatingCartWidget({super.key});

  /// Gap between the pill and the bottom navigation / safe area.
  static const double gapAboveTabBar = 12;

  /// Horizontal inset from screen edges (“in side”).
  static const double horizontalInset = 16;

  /// Opens [CartScreen] unless it is already the top route.
  static void openCart(BuildContext context) {
    if (appRouteObserver.isCurrent(AppRoutes.cart)) return;
    rootNavigatorKey.currentState?.push<void>(AppPageRoutes.cart());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return _PillBody(cart: cart);
  }
}

class _PillBody extends StatelessWidget {
  const _PillBody({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final totalCount = cart.totalUnits;
    final total = cart.bill.total > 0 ? cart.bill.total : cart.bill.subtotal;
    final preview = cart.items.take(3).toList();
    final primaryName = cart.items.isNotEmpty ? cart.items.first.name : '';
    final itemLabel = context.l10n.itemLabel(totalCount);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primary,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            _Avatars(items: preview, max: 3, extra: cart.items.length),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primaryName.isNotEmpty)
                    Text(
                      primaryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.15,
                      ),
                    ),
                  Text(
                    itemLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withValues(alpha: 0.65),
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
            const SizedBox(width: 8),
            Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              child: InkWell(
                onTap: () => GlobalFloatingCartWidget.openCart(context),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.view_cart,
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
              ),
            ),
          ],
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
        width: 40,
        height: 40,
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
      width: shown.length * 24.0 + (extraCount > 0 ? 28 : 0),
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 40,
                height: 40,
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
                  width: 36,
                  height: 36,
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
              left: shown.length * 20.0,
              child: Container(
                width: 40,
                height: 40,
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
