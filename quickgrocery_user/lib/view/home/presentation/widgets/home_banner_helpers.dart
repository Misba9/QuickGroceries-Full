import 'package:quickgrocery/models/banner_model.dart';

/// Image / carousel banners only — video URLs render in [HomeBannerVideoRail].
List<BannerModel> imageCarouselBanners(List<BannerModel> all) {
  return all
      .where((b) => !(b.isVideo && b.video.trim().isNotEmpty))
      .toList(growable: false);
}

/// Admin-uploaded MP4 (and similar) hero promos from `banners/`.
List<BannerModel> promoVideoBanners(List<BannerModel> all) {
  final list = all
      .where((b) => b.isVideo && b.video.trim().isNotEmpty)
      .toList(growable: false);
  list.sort((a, b) => a.priority.compareTo(b.priority));
  return list;
}
