import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickgrocery/core/startup/startup_isolate_parse.dart';
import 'package:quickgrocery/models/banner_model.dart';
import 'package:quickgrocery/models/offer_banner_model.dart';
import 'package:quickgrocery/view/home/domain/banner_repository.dart';
import 'package:quickgrocery/view/offers/data/offer_banner_service.dart';
import 'package:rxdart/rxdart.dart';

class OfferBannerRepository {
  OfferBannerRepository(this._service, this._bannerRepository);

  final OfferBannerService _service;
  final BannerRepository _bannerRepository;

  Future<List<OfferBannerModel>> _mapOffersAsync(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) async {
    final parsed = await StartupIsolateParse.parseOffers(
      StartupIsolateParse.docsFromSnapshot(snap),
    );
    return parsed.where((o) => o.isScheduleOk).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  List<OfferBannerModel> _fromAdminBanners(List<BannerModel> banners) {
    final out = <OfferBannerModel>[];
    for (final b in banners) {
      if (!b.isScheduleOk) continue;
      final o = OfferBannerModel.fromAdminBanner(b);
      if (o.hasPromoMedia) out.add(o);
    }
    out.sort((a, b) => b.priority.compareTo(a.priority));
    return out;
  }

  /// [offerBanners] wins on duplicate ids (legacy `offer_banners` overrides admin).
  List<OfferBannerModel> _mergeAdminThenOffers(
    List<OfferBannerModel> adminBanners,
    List<OfferBannerModel> offerBanners,
  ) {
    final byId = <String, OfferBannerModel>{};
    for (final o in adminBanners) {
      byId[o.id] = o;
    }
    for (final o in offerBanners) {
      byId[o.id] = o;
    }
    final merged = byId.values.toList()
      ..sort((x, y) => y.priority.compareTo(x.priority));
    return merged;
  }

  Stream<List<OfferBannerModel>> watchHomeExploreOffers() {
    return Rx.combineLatest2(
      _service.watchOfferBanners().asyncMap(_mapOffersAsync),
      _bannerRepository.watchActiveBanners(),
      (List<OfferBannerModel> fromOffersRaw, List<BannerModel> admin) {
        final fromOffers = fromOffersRaw
            .where((o) =>
                o.showOnHomepage && o.showInHomeExplore && o.hasPromoMedia)
            .toList();
        final fromAdmin = _fromAdminBanners(admin)
            .where((o) =>
                o.showOnHomepage && o.showInHomeExplore && o.hasPromoMedia)
            .toList();
        return _mergeAdminThenOffers(fromAdmin, fromOffers);
      },
    );
  }

  Stream<List<OfferBannerModel>> watchOffersPage() {
    return Rx.combineLatest2(
      _service.watchOfferBanners().asyncMap(_mapOffersAsync),
      _bannerRepository.watchActiveBanners(),
      (List<OfferBannerModel> fromOffersRaw, List<BannerModel> admin) {
        final fromOffers = fromOffersRaw
            .where((o) => o.showOnOffersPage && o.hasPromoMedia)
            .toList();
        final fromAdmin = _fromAdminBanners(admin)
            .where((o) => o.showOnOffersPage && o.hasPromoMedia)
            .toList();
        return _mergeAdminThenOffers(fromAdmin, fromOffers);
      },
    );
  }

  Stream<List<OfferBannerModel>> watchStories() {
    return _service.watchOfferBanners().asyncMap((snap) async {
      final list = await _mapOffersAsync(snap);
      return list.where((o) => o.showInStories).toList();
    });
  }

  Stream<List<OfferBannerModel>> watchPopupEligible() {
    return Rx.combineLatest2(
      _service.watchOfferBanners().asyncMap(_mapOffersAsync),
      _bannerRepository.watchActiveBanners(),
      (List<OfferBannerModel> fromOffersRaw, List<BannerModel> admin) {
        final fromOffers = fromOffersRaw
            .where((o) =>
                o.showAsPopup &&
                (o.hasVideo ||
                    o.thumbnailUrl.isNotEmpty ||
                    o.imageFallbackUrl.isNotEmpty))
            .toList();
        final fromAdmin = _fromAdminBanners(admin)
            .where((o) =>
                o.showAsPopup &&
                (o.hasVideo ||
                    o.thumbnailUrl.isNotEmpty ||
                    o.imageFallbackUrl.isNotEmpty))
            .toList();
        return _mergeAdminThenOffers(fromAdmin, fromOffers);
      },
    );
  }

  Stream<PromotionPopupSettings> watchPopupSettings() {
    return _service.watchPromotionSettings().map((doc) {
      return PromotionPopupSettings.fromMap(doc.data());
    });
  }

  Future<List<OfferBannerModel>> fetchHomeExploreOffers({
    required List<BannerModel> adminBanners,
  }) async {
    try {
      final offerSnap = await _service.fetchOfferBanners();
      final fromOffers = (await _mapOffersAsync(offerSnap))
          .where((o) =>
              o.showOnHomepage && o.showInHomeExplore && o.hasPromoMedia)
          .toList();
      final fromAdmin = _fromAdminBanners(adminBanners)
          .where((o) =>
              o.showOnHomepage && o.showInHomeExplore && o.hasPromoMedia)
          .toList();
      return _mergeAdminThenOffers(fromAdmin, fromOffers);
    } catch (_) {
      return const [];
    }
  }

  Future<void> trackView(OfferBannerModel offer) =>
      _service.incrementMetric(offer, click: false);

  Future<void> trackClick(OfferBannerModel offer) =>
      _service.incrementMetric(offer, click: true);
}
