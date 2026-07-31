import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/core/design/responsive.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/home/presentation/providers/explore_products_provider.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_section_slot.dart';
import 'package:quickgrocery/view/home/presentation/widgets/home_status_views.dart';
import 'package:quickgrocery/view/home/presentation/widgets/product_card.dart';
import 'package:quickgrocery/view/home/presentation/widgets/section_header.dart';
import 'package:quickgrocery/view/offers/presentation/widgets/offer_promo_video_card.dart';
import 'package:quickgrocery/core/localization/l10n_extension.dart';
import 'package:quickgrocery/core/loading/loading.dart';

/// Builds explore header + injected offer videos after every **two** product
/// rows, driven by [offer_banners] (`showOnHomepage` + `showInHomeExplore`).
///
/// Offers and explore products each keep their own lightweight shimmer — Home
/// stays scrollable and interactive while either side loads.
List<Widget> buildHomeExploreOfferSlivers({
  required BuildContext context,
  required WidgetRef ref,
  required AsyncValue<ExploreState> exploreAsync,
  required List<OfferBannerModel> offers,
  bool offersLoading = false,
  required double gutter,
}) {
  final responsive = Responsive.of(context);
  final cols = responsive.cols(phone: 2, tablet: 3, desktop: 4);
  final chunk = cols * 2;
  final exploreLoading = exploreAsync.isLoading && !exploreAsync.hasValue;

  final out = <Widget>[
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
        child: SectionHeader(title: context.l10n.explore_products),
      ),
    ),
  ];

  if (exploreLoading) {
    if (offersLoading) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
            child: HomeSectionSlot(
              loading: true,
              minHeight: 180,
              shimmer: AppLoading.banner,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    } else if (offers.isNotEmpty) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
            child: HomeSectionSlot(
              loading: false,
              minHeight: 180,
              shimmer: AppLoading.banner,
              child: OfferPromoVideoCard(offer: offers.first),
            ),
          ),
        ),
      );
    }
    out.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: HomeSectionSlot(
            loading: true,
            minHeight: 320,
            shimmer: AppLoading.exploreGrid,
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    return out;
  }

  if (exploreAsync.hasError && !exploreAsync.hasValue) {
    out.add(
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
    );
    return out;
  }

  final state = exploreAsync.asData?.value;
  if (state == null || state.products.isEmpty) {
    final subtitle = state == null ? null : _exploreEmptySubtitle(state);
    out.add(
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
    );
    return out;
  }

  var pi = 0;
  var bi = 0;
  final products = state.products;
  final readyOffers = offersLoading ? const <OfferBannerModel>[] : offers;

  while (pi < products.length) {
    if (offersLoading && pi == 0) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 10, gutter, 10),
            child: HomeSectionSlot(
              loading: true,
              minHeight: 180,
              shimmer: AppLoading.banner,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    } else if (readyOffers.isNotEmpty) {
      final offer = readyOffers[bi % readyOffers.length];
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
            mainAxisSpacing: 8,
            childAspectRatio: cols >= 4 ? 0.66 : 0.60,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final p = slice[i];
              return HomeProductCard(
                key: ValueKey('explore-${p.id}'),
                product: p,
              );
            },
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
              child: AppLoading.micro,
            ),
          ),
        ),
      ),
    );
  }

  return out;
}

String? _exploreEmptySubtitle(ExploreState state) {
  if (state.diagnosticRawDocs == 0) return null;
  if (state.diagnosticFilteredUnavailable > 0) {
    return '${state.diagnosticFilteredUnavailable} item(s) are temporarily '
        'out of stock. Pull to refresh.';
  }
  return null;
}
