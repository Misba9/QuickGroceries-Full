import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:quickgrocery/core/feedback/app_snackbar.dart';
import 'package:quickgrocery/core/navigation/product_navigation.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/category/screens/category_screen.dart';
import 'package:quickgrocery/view/home/provider/home_provider.dart';
import 'package:quickgrocery/view/offers/presentation/providers/offer_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Routes offer banner taps based on admin [redirectType].
///
/// Product redirects always open [ProductViewScreen] via
/// [ProductNavigation.openProductById] (cache + Firestore fallback).
Future<void> navigateFromOffer(
  BuildContext context,
  WidgetRef ref,
  OfferBannerModel offer,
) async {
  await ref.read(offerBannerRepositoryProvider).trackClick(offer);
  if (!context.mounted) return;

  final type = ProductNavigation.normalizeRedirectType(offer.redirectType);
  final targetId = ProductNavigation.resolveProductId(
    redirectId: offer.redirectId,
  );

  switch (type) {
    case 'offers_page':
      openOffersTab(context);
      break;
    case 'category':
      final categoryId = offer.redirectId.trim();
      if (categoryId.isEmpty) {
        AppSnackBar.error('Category unavailable', context: context);
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CategoryScreen(category: categoryId),
        ),
      );
      break;
    case 'product':
      await ProductNavigation.openProductById(context, targetId);
      break;
    case 'url':
      final uri = Uri.tryParse(offer.redirectId.trim());
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        AppSnackBar.error('Invalid link', context: context);
      }
      break;
    default:
      // No redirect configured — stay on offers surface.
      break;
  }
}

/// Switches main tab to Offers (center FAB index **2**).
void openOffersTab(BuildContext context) {
  legacy.Provider.of<HomeProvider>(context, listen: false).onSelectedChange(2);
}
