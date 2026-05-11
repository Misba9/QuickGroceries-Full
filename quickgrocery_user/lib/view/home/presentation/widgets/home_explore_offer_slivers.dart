import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/home/presentation/providers/explore_products_provider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_shimmer.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_status_views.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_promo_video_card.dart';

/// Builds explore header + injected offer videos after every **two** product
/// rows, driven by [offer_banners] (`showOnHomepage` + `showInHomeExplore`).
List<Widget> buildHomeExploreOfferSlivers({
  required BuildContext context,
  required WidgetRef ref,
  required AsyncValue<ExploreState> exploreAsync,
  required List<OfferBannerModel> offers,
  required double gutter,
}) {
  final responsive = Responsive.of(context);
  final cols = responsive.cols(phone: 2, tablet: 3, desktop: 4);
  final chunk = cols * 2;

  return exploreAsync.when(
    loading: () => [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
          child: SectionHeader(title: 'explore_products'.tr()),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: HomeShimmer.exploreGrid(),
        ),
      ),
    ],
    error: (e, _) => [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
          child: SectionHeader(title: 'explore_products'.tr()),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
          child: HomeErrorView(
            message: 'Couldn\'t load products',
            onRetry: () =>
                ref.read(exploreProductsProvider.notifier).refresh(),
          ),
        ),
      ),
    ],
    data: (state) {
      if (state.products.isEmpty) {
        final subtitle = _exploreEmptySubtitle(state);
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
              child: SectionHeader(title: 'explore_products'.tr()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 16),
              child: HomeEmptyView(
                message: 'No products available right now.',
                subtitle: subtitle,
                icon: Icons.shopping_bag_outlined,
                height: subtitle == null ? 120 : 156,
              ),
            ),
          ),
        ];
      }

      final out = <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
            child: SectionHeader(title: 'explore_products'.tr()),
          ),
        ),
      ];

      var pi = 0;
      var bi = 0;
      final products = state.products;

      while (pi < products.length) {
        if (offers.isNotEmpty) {
          final offer = offers[bi % offers.length];
          bi++;
          out.add(
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
                child: OfferPromoVideoCard(offer: offer),
              ),
            ),
          );
        }

        final end = min(pi + chunk, products.length);
        final slice = products.sublist(pi, end);

        out.add(
          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 4),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: cols >= 4 ? 0.62 : 0.56,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => HomeProductCard(product: slice[i]),
                childCount: slice.length,
              ),
            ),
          ),
        );
        pi = end;
      }

      if (state.isLoadingMore) {
        out.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return out;
    },
  );
}

String? _exploreEmptySubtitle(ExploreState state) {
  if (state.diagnosticRawDocs == 0) return null;
  if (state.diagnosticFilteredUnavailable > 0) {
    return '${state.diagnosticFilteredUnavailable} item(s) are temporarily '
        'out of stock. Pull to refresh.';
  }
  return null;
}
