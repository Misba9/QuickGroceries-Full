import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/wishlist/services/wishlist_service.dart';

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
      appBar: AppBar(centerTitle: true, title: Text('wishlist'.tr())),
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
                    'No items in wishlist'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                wishlistProvider.refreshWishlist();
              },
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.64,
                ),
                itemCount: wishlistProvider.wishlistProducts!.length,
                itemBuilder: (context, i) {
                  final product = wishlistProvider.wishlistProducts![i];
                  return LayoutBuilder(
                    builder: (context, c) {
                      return ProductCardWidget(
                        product: product,
                        width: c.maxWidth,
                        onAfterProductDetailClosed: () =>
                            wishlistProvider.refreshWishlist(),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
