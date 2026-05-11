import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/models/product.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/category/services/category_service.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:quickgrocery/view/product_view/screens/product_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// Routes offer banner taps based on admin [redirectType].
Future<void> navigateFromOffer(
  BuildContext context,
  WidgetRef ref,
  OfferBannerModel offer,
) async {
  await ref.read(offerBannerRepositoryProvider).trackClick(offer);

  switch (offer.redirectType) {
    case 'offers_page':
      openOffersTab(context);
      break;
    case 'category':
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategoryScreen(category: offer.redirectId),
        ),
      );
      break;
    case 'product':
      final cartService =
          legacy.Provider.of<CategoryService>(context, listen: false);
      final ProductModel? product = cartService.allProducts
          .where((p) => p.id == offer.redirectId)
          .cast<ProductModel?>()
          .firstWhere((p) => p != null, orElse: () => null);
      if (product != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ProductViewScreen(product: product),
          ),
        );
      }
      break;
    case 'url':
      final uri = Uri.tryParse(offer.redirectId);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      break;
    default:
      break;
  }
}

/// Switches main tab to Offers (center FAB index **2**).
void openOffersTab(BuildContext context) {
  legacy.Provider.of<HomeProvider>(context, listen: false).onSelectedChange(2);
}
