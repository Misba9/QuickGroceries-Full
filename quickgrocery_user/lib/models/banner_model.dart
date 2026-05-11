import 'package:cloud_firestore/cloud_firestore.dart';

/// BannerModel — `banners/` collection (admin Banner Management + user app).
///
/// Backward compatible with legacy: `image`, `video`, `type`, `id`, `created_date`.
/// New admin fields: title, subtitle, thumbnail, placement flags, schedule,
/// video behaviour, optional per-popup auto-close.
class BannerModel {
  final String id;
  final String image;
  final String video;
  final String type; // 'image' | 'video' (legacy + admin)
  final String redirectType; // 'category' | 'product' | 'url' | 'offers_page' | 'none'
  final String redirectId;
  final int priority;
  final bool isActive;
  final String createddate;
  final DateTime? createdAt;
  final String ctaLabel;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final bool showInHome;
  final bool showInOffers;
  final bool showAsPopup;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final double? bannerHeightPx;
  final int popupAutoCloseSeconds;
  final int viewCount;
  final int clickCount;

  const BannerModel({
    required this.id,
    required this.image,
    required this.video,
    required this.type,
    required this.redirectType,
    required this.redirectId,
    required this.priority,
    required this.isActive,
    required this.createddate,
    this.createdAt,
    this.ctaLabel = '',
    this.title = '',
    this.subtitle = '',
    this.thumbnailUrl = '',
    this.showInHome = false,
    this.showInOffers = false,
    this.showAsPopup = false,
    this.startsAt,
    this.endsAt,
    this.autoplay = true,
    this.loop = true,
    this.muted = true,
    this.bannerHeightPx,
    this.popupAutoCloseSeconds = 0,
    this.viewCount = 0,
    this.clickCount = 0,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    final created = _asDateTime(data['createdAt'] ?? data['created_date']);
    final videoRaw =
        data['videoUrl']?.toString() ?? data['video']?.toString() ?? '';
    final typeRaw =
        (data['bannerType'] ?? data['type'])?.toString().toLowerCase() ?? 'image';
    return BannerModel(
      id: (data['id'] ?? id).toString(),
      image: data['image']?.toString() ?? '',
      video: videoRaw,
      type: typeRaw == 'video' ? 'video' : 'image',
      redirectType: data['redirectType']?.toString() ?? 'none',
      redirectId: data['redirectId']?.toString() ?? '',
      priority: _asInt(data['priority']),
      isActive: data['isActive'] as bool? ?? true,
      createddate: (data['created_date'] ?? data['createdAt'] ?? '').toString(),
      createdAt: created,
      ctaLabel: data['ctaLabel']?.toString() ??
          data['ctaText']?.toString() ??
          data['buttonText']?.toString() ??
          '',
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      showInHome: data['showInHome'] as bool? ??
          data['showOnHome'] as bool? ??
          false,
      showInOffers: data['showInOffers'] as bool? ??
          data['showOnOffersPage'] as bool? ??
          false,
      showAsPopup: data['showAsPopup'] as bool? ?? false,
      startsAt: _asDateTime(data['startsAt'] ?? data['startDate']),
      endsAt: _asDateTime(data['endsAt'] ?? data['endDate']),
      autoplay: data['autoplay'] as bool? ?? true,
      loop: data['loop'] as bool? ?? true,
      muted: data['muted'] as bool? ?? true,
      bannerHeightPx: _asDouble(data['bannerHeightPx']),
      popupAutoCloseSeconds: _asInt(data['popupAutoCloseSeconds'], 0),
      viewCount: _asInt(data['viewCount']),
      clickCount: _asInt(data['clickCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'video': video,
        'type': type,
        'redirectType': redirectType,
        'redirectId': redirectId,
        'priority': priority,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
        if (ctaLabel.isNotEmpty) 'ctaLabel': ctaLabel,
      };

  BannerModel copyWith({
    String? id,
    String? image,
    String? video,
    String? type,
    String? redirectType,
    String? redirectId,
    int? priority,
    bool? isActive,
    String? createddate,
    DateTime? createdAt,
    String? ctaLabel,
    String? title,
    String? subtitle,
    String? thumbnailUrl,
    bool? showInHome,
    bool? showInOffers,
    bool? showAsPopup,
    DateTime? startsAt,
    DateTime? endsAt,
    bool? autoplay,
    bool? loop,
    bool? muted,
    double? bannerHeightPx,
    int? popupAutoCloseSeconds,
    int? viewCount,
    int? clickCount,
  }) {
    return BannerModel(
      id: id ?? this.id,
      image: image ?? this.image,
      video: video ?? this.video,
      type: type ?? this.type,
      redirectType: redirectType ?? this.redirectType,
      redirectId: redirectId ?? this.redirectId,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createddate: createddate ?? this.createddate,
      createdAt: createdAt ?? this.createdAt,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      showInHome: showInHome ?? this.showInHome,
      showInOffers: showInOffers ?? this.showInOffers,
      showAsPopup: showAsPopup ?? this.showAsPopup,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      autoplay: autoplay ?? this.autoplay,
      loop: loop ?? this.loop,
      muted: muted ?? this.muted,
      bannerHeightPx: bannerHeightPx ?? this.bannerHeightPx,
      popupAutoCloseSeconds:
          popupAutoCloseSeconds ?? this.popupAutoCloseSeconds,
      viewCount: viewCount ?? this.viewCount,
      clickCount: clickCount ?? this.clickCount,
    );
  }

  /// Resolved MP4 URL (admin may store as `video` or `videoUrl`).
  String get effectiveVideoUrl => video.trim();

  String get mediaUrl => isVideo ? effectiveVideoUrl : image;
  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';
  bool get hasRedirect => redirectType != 'none' && redirectId.isNotEmpty;

  bool get isExpired =>
      endsAt != null && DateTime.now().isAfter(endsAt!);

  bool get isNotYetActive =>
      startsAt != null && DateTime.now().isBefore(startsAt!);

  bool get isScheduleOk => isActive && !isExpired && !isNotYetActive;

  bool get hasPromoMedia =>
      effectiveVideoUrl.isNotEmpty ||
      image.isNotEmpty ||
      thumbnailUrl.isNotEmpty;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
