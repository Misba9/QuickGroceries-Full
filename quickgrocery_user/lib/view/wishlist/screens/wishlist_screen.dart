import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/wishlist/services/wishlist_service.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WishlistService>(
        context,
        listen: false,
      ).fetchWishlistProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistService>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.wishlist),
      ),
      body: wishlistProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlistProvider.wishlistProducts == null ||
                wishlistProvider.wishlistProducts!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieBuilder.asset('assets/lottie/no_data.json'),
                  AppSpacing.h20,
                  Text(
                    context.l10n.wishlistEmpty,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                wishlistProvider.refreshWishlist();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inset = Responsive.of(context).horizontalInset();
                  final available =
                      (constraints.maxWidth - inset * 2).clamp(0.0, double.infinity);
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(inset, 10, inset, 24),
                    gridDelegate: Responsive.productGridDelegate(
                      context,
                      availableWidth: available,
                    ),
                    itemCount: wishlistProvider.wishlistProducts!.length,
                    itemBuilder: (context, i) {
                      final product = wishlistProvider.wishlistProducts![i];
                      return LayoutBuilder(
                        builder: (context, c) {
                          return ProductCardWidget(
                            product: product,
                            width: c.maxWidth,
                            heroScope: 'wishlist',
                            heroIndex: i,
                            onAfterProductDetailClosed: () =>
                                wishlistProvider.refreshWishlist(),
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
}
