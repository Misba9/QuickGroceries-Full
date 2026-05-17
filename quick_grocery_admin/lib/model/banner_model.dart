import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String image;
  final String video;
  final String type; // 'image' or 'video'
  final String id;
  final String createddate;
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String ctaText;
  final String redirectType;
  final String redirectId;
  final bool isActive;
  final bool showInHome;
  final bool showInOffers;
  final bool showAsPopup;
  final int priority;
  final bool autoplay;
  final bool loop;
  final bool muted;
  final int popupAutoCloseSeconds;
  final int viewCount;
  final int clickCount;
  final int orderCount;
  final DateTime? startsAt;
  final DateTime? endsAt;

  BannerModel({
    required this.image,
    required this.video,
    required this.type,
    required this.id,
    required this.createddate,
    this.title = '',
    this.subtitle = '',
    this.thumbnailUrl = '',
    this.ctaText = '',
    this.redirectType = 'none',
    this.redirectId = '',
    this.isActive = true,
    this.showInHome = true,
    this.showInOffers = true,
    this.showAsPopup = false,
    this.priority = 10,
    this.autoplay = true,
    this.loop = true,
    this.muted = true,
    this.popupAutoCloseSeconds = 12,
    this.viewCount = 0,
    this.clickCount = 0,
    this.orderCount = 0,
    this.startsAt,
    this.endsAt,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> data, String id) {
    final videoRaw =
        data['videoUrl']?.toString() ?? data['video']?.toString() ?? '';
    final typeRaw =
        (data['bannerType'] ?? data['type'])?.toString().toLowerCase() ??
            'image';
    return BannerModel(
      id: (data['id'] ?? id).toString(),
      image: data['image']?.toString() ?? '',
      video: videoRaw,
      type: typeRaw == 'video' ? 'video' : 'image',
      createddate: (data['created_date'] ?? data['createdAt'] ?? '').toString(),
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      thumbnailUrl: data['thumbnailUrl']?.toString() ?? '',
      ctaText: data['ctaText']?.toString() ??
          data['ctaLabel']?.toString() ??
          'Shop now',
      redirectType: data['redirectType']?.toString() ?? 'none',
      redirectId: data['redirectId']?.toString() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      showInHome: data['showInHome'] as bool? ??
          data['showOnHome'] as bool? ??
          true,
      showInOffers: data['showInOffers'] as bool? ??
          data['showOnOffersPage'] as bool? ??
          true,
      showAsPopup: data['showAsPopup'] as bool? ?? false,
      priority: _int(data['priority'], 10),
      autoplay: data['autoplay'] as bool? ?? true,
      loop: data['loop'] as bool? ?? true,
      muted: data['muted'] as bool? ?? true,
      popupAutoCloseSeconds: _int(data['popupAutoCloseSeconds'], 12),
      viewCount: _int(data['viewCount'], 0),
      clickCount: _int(data['clickCount'], 0),
      orderCount: _int(data['orderCount'], 0),
      startsAt: _date(data['startsAt'] ?? data['startDate']),
      endsAt: _date(data['endsAt'] ?? data['endDate']),
    );
  }

  String get mediaUrl => type == 'video' ? video : image;
  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  double get ctrPercent =>
      viewCount > 0 ? (clickCount / viewCount) * 100 : 0;

  /// Active / scheduled / inactive for admin badges.
  BannerLifecycleStatus get lifecycleStatus {
    final now = DateTime.now();
    if (!isActive) return BannerLifecycleStatus.inactive;
    if (startsAt != null && now.isBefore(startsAt!)) {
      return BannerLifecycleStatus.scheduled;
    }
    if (endsAt != null && now.isAfter(endsAt!)) {
      return BannerLifecycleStatus.inactive;
    }
    return BannerLifecycleStatus.active;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return DateTime.tryParse(v.toString());
  }

  static int _int(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
}

enum BannerLifecycleStatus { active, inactive, scheduled }
