import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quickgrocery/constants/app_spacing.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';
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
    final categoryProvider = Provider.of<CategoryService>(context);

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
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.38,
                ),
                itemCount: wishlistProvider.wishlistProducts!.length,
                itemBuilder: (context, i) {
                  final product = wishlistProvider.wishlistProducts![i];
                  return ProductCard(
                    itemQuantity: product.unitPerItem,
                    name: product.name,
                    image: product.image,
                    price: product.price.toString(),
                    slashedPrice: product.slashedPrice.toString(),
                    isSelected: categoryProvider.selectedProduct.any(
                      (e) => e.id == product.id,
                    ),
                    onSelect: () {
                      categoryProvider.addProduct(context, product);
                    },
                    itemCount: product.itemCount.toString(),
                    onDecrement: () {
                      categoryProvider.removeProductCount(product.id);
                    },
                    onIncrement: () {
                      categoryProvider.addProductCount(product.id);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductViewScreen(product: product),
                        ),
                      ).then((_) {
                        // Refresh wishlist when returning from product view
                        wishlistProvider.refreshWishlist();
                      });
                    },
                  );
                },
              ),
            ),
    );
  }
}
