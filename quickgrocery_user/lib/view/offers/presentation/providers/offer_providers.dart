import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/home/presentation/providers/home_providers.dart';
import 'package:quickgrocery/view/offers/data/offer_banner_service.dart';
import 'package:quickgrocery/view/offers/domain/offer_banner_repository.dart';

final offerBannerServiceProvider = Provider<OfferBannerService>((ref) {
  return OfferBannerService(firestore: ref.watch(firestoreProvider));
});

final offerBannerRepositoryProvider = Provider<OfferBannerRepository>((ref) {
  return OfferBannerRepository(
    ref.watch(offerBannerServiceProvider),
    ref.watch(bannerRepositoryProvider),
  );
});

final homeExploreOfferBannersProvider =
    StreamProvider.autoDispose<List<OfferBannerModel>>((ref) {
      return ref.watch(offerBannerRepositoryProvider).watchHomeExploreOffers();
    });

final offersPageBannersProvider =
    StreamProvider.autoDispose<List<OfferBannerModel>>((ref) {
      return ref.watch(offerBannerRepositoryProvider).watchOffersPage();
    });

final offersStoriesProvider =
    StreamProvider.autoDispose<List<OfferBannerModel>>((ref) {
      return ref.watch(offerBannerRepositoryProvider).watchStories();
    });

final promotionPopupSettingsProvider =
    StreamProvider.autoDispose<PromotionPopupSettings>((ref) {
      return ref.watch(offerBannerRepositoryProvider).watchPopupSettings();
    });

final popupEligibleOffersProvider =
    StreamProvider.autoDispose<List<OfferBannerModel>>((ref) {
      return ref.watch(offerBannerRepositoryProvider).watchPopupEligible();
    });
