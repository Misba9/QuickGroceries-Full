import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:quickgrocery/models/banner_model.dart';

/// Promotional offer banner — sourced from `offer_banners` and/or admin
/// `banners` (video promo) collection.
class OfferBannerModel {
  const OfferBannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.imageFallbackUrl,
    required this.ctaText,
    required this.redirectType,
    required this.redirectId,
    required this.startsAt,
    required this.endsAt,
    required this.priority,
    required this.isActive,
    required this.showOnHomepage,
    required this.showInHomeExplore,
    required this.showOnOffersPage,
    required this.showAsPopup,
    required this.showInStories,
    required this.lottieUrl,
    required this.discountBadgeLabel,
    required this.autoplay,
    required this.loop,
    required this.muted,
    required this.bannerHeightPx,
    required this.viewCount,
    required this.clickCount,
    required this.fromBannersCollection,
    this.popupAutoCloseSeconds,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String imageFallbackUrl;
  final String ctaText;

  /// `product` | `category` | `offers_page` | `url` | `none`
  final String redirectType;
  final String redirectId;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int priority;
  final bool isActive;
  final bool showOnHomepage;
  final bool showInHomeExplore;
  final bool showOnOffersPage;
  final bool showAsPopup;
  final bool showInStories;
  final String lottieUrl;
  final String discountBadgeLabel;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final double? bannerHeightPx;
  final int viewCount;
  final int clickCount;

  /// When true, analytics writes go to `banners/{id}` instead of `offer_banners`.
  final bool fromBannersCollection;

  /// Per-banner popup auto-close override (seconds); null → use global settings.
  final int? popupAutoCloseSeconds;

  factory OfferBannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    final showHome = data['showOnHomepage'] as bool? ??
        data['showInHome'] as bool? ??
        false;
    final showExplore = data['showInHomeExplore'] as bool? ??
        data['showInHome'] as bool? ??
        true;
    final showOffers = data['showOnOffersPage'] as bool? ??
        data['showInOffers'] as bool? ??
        true;

    return OfferBannerModel(
      id: (data['id'] ?? id).toString(),
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      videoUrl: data['videoUrl']?.toString() ?? data['video']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      imageFallbackUrl:
          data['imageFallbackUrl']?.toString() ?? data['image']?.toString() ?? '',
      ctaText: data['ctaText']?.toString() ??
          data['ctaLabel']?.toString() ??
          'Shop now',
      redirectType: data['redirectType']?.toString() ?? 'none',
      redirectId: data['redirectId']?.toString() ?? '',
      startsAt: _date(data['startsAt'] ?? data['startDate']),
      endsAt: _date(data['endsAt'] ?? data['endDate']),
      priority: _int(data['priority']),
      isActive: data['isActive'] as bool? ?? true,
      showOnHomepage: showHome,
      showInHomeExplore: showExplore,
      showOnOffersPage: showOffers,
      showAsPopup: data['showAsPopup'] as bool? ?? false,
      showInStories: data['showInStories'] as bool? ?? false,
      lottieUrl: data['lottieUrl']?.toString() ?? '',
      discountBadgeLabel: data['discountBadgeLabel']?.toString() ?? '',
      autoplay: data['autoplay'] as bool? ?? true,
      loop: data['loop'] as bool? ?? true,
      muted: data['muted'] as bool? ?? true,
      bannerHeightPx: _double(data['bannerHeightPx']),
      viewCount: _int(data['viewCount']),
      clickCount: _int(data['clickCount']),
      fromBannersCollection: false,
      popupAutoCloseSeconds: _optionalInt(data['popupAutoCloseSeconds']),
    );
  }

  /// Maps admin [BannerModel] (`banners/` collection) into the same shape used
  /// by [OfferPromoVideoCard] / popup / home injection.
  factory OfferBannerModel.fromAdminBanner(BannerModel b) {
    final vid = b.effectiveVideoUrl;
    final popupSecs = b.popupAutoCloseSeconds > 0 ? b.popupAutoCloseSeconds : null;
    return OfferBannerModel(
      id: b.id,
      title: b.title,
      subtitle: b.subtitle,
      description: '',
      videoUrl: vid,
      thumbnailUrl: b.thumbnailUrl,
      imageFallbackUrl: b.image,
      ctaText: b.ctaLabel.trim().isEmpty ? 'Shop now' : b.ctaLabel,
      redirectType: b.redirectType.trim().isEmpty ? 'none' : b.redirectType,
      redirectId: b.redirectId,
      startsAt: b.startsAt,
      endsAt: b.endsAt,
      priority: b.priority,
      isActive: b.isActive,
      showOnHomepage: b.showInHome,
      showInHomeExplore: b.showInHome,
      showOnOffersPage: b.showInOffers,
      showAsPopup: b.showAsPopup,
      showInStories: false,
      lottieUrl: '',
      discountBadgeLabel: '',
      autoplay: b.autoplay,
      loop: b.loop,
      muted: b.muted,
      bannerHeightPx: b.bannerHeightPx ?? 200,
      viewCount: b.viewCount,
      clickCount: b.clickCount,
      fromBannersCollection: true,
      popupAutoCloseSeconds: popupSecs,
    );
  }

  bool get hasVideo => videoUrl.trim().isNotEmpty;

  /// Enough visual media to render [OfferPromoVideoCard] (video and/or image).
  bool get hasPromoMedia =>
      hasVideo || thumbnailUrl.trim().isNotEmpty || imageFallbackUrl.isNotEmpty;

  bool get hasRedirect =>
      redirectType != 'none' && redirectId.trim().isNotEmpty;

  bool get isExpired => endsAt != null && DateTime.now().isAfter(endsAt!);

  bool get isNotYetActive =>
      startsAt != null && DateTime.now().isBefore(startsAt!);

  bool get isScheduleOk => isActive && !isExpired && !isNotYetActive;

  Duration? get timeRemaining {
    if (endsAt == null) return null;
    final d = endsAt!.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.tryParse(v.toString());
  }

  static int? _optionalInt(dynamic v) {
    if (v == null) return null;
    final n = _int(v, -1);
    if (n <= 0) return null;
    return n;
  }

  static int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double? _double(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Global popup rules — document `app_settings/promotions`.
class PromotionPopupSettings {
  const PromotionPopupSettings({
    required this.enabled,
    required this.frequencyHours,
    required this.autoCloseSeconds,
    required this.pinnedOfferId,
  });

  final bool enabled;
  final int frequencyHours;
  final int autoCloseSeconds;
  final String pinnedOfferId;

  factory PromotionPopupSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const PromotionPopupSettings(
        enabled: true,
        frequencyHours: 24,
        autoCloseSeconds: 12,
        pinnedOfferId: '',
      );
    }
    return PromotionPopupSettings(
      enabled: data['popupEnabled'] as bool? ?? true,
      frequencyHours: OfferBannerModel._int(data['popupFrequencyHours'], 24)
          .clamp(1, 720),
      autoCloseSeconds:
          OfferBannerModel._int(data['popupAutoCloseSeconds'], 12).clamp(3, 120),
      pinnedOfferId: data['pinnedOfferId']?.toString() ?? '',
    );
  }
}
